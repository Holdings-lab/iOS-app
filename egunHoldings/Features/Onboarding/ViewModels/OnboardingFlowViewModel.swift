import Combine
import Foundation

@MainActor
final class OnboardingFlowViewModel: ObservableObject {
    let userName: String

    @Published var financialGoal: FinancialGoal = .seedMoney
    @Published var targetAmount: Int64 = FinancialGoal.seedMoney.defaultTargetAmount
    @Published var investmentHorizon: InvestmentHorizon?
    @Published var maxDrawdownTolerance: MaxDrawdownTolerance?
    @Published var investmentProfile: InvestmentProfile?
    @Published private(set) var selectedWatchAssets: Set<WatchAssetSector> = []
    @Published private(set) var connectedInstitutionID: String?
    @Published private(set) var isBrokerageConnected = false
    @Published private(set) var brokerageAccountId: Int64?

    // MARK: - Step 7 연결 연출 상태

    @Published private(set) var activeLinkStage: BrokerageLinkStage?
    @Published private(set) var completedLinkStages: Set<BrokerageLinkStage> = []
    /// 연결이 끝난 뒤 요약 카드에 노출할 계좌 정보.
    @Published private(set) var linkedAccount: LinkedDemoAccount?
    @Published private(set) var brokerageLinkErrorMessage: String?

    private let onboardingRepository: OnboardingRepositoryProtocol
    private let brokerageConnectionRepository: BrokerageConnectionRepositoryProtocol
    private let brokerBalanceRepository: BrokerBalanceRepositoryProtocol
    private var hasCustomTargetAmount = false

    init(
        userName: String = "회원",
        onboardingRepository: OnboardingRepositoryProtocol = LiveOnboardingRepository(),
        brokerageConnectionRepository: BrokerageConnectionRepositoryProtocol = LiveBrokerageConnectionRepository(),
        brokerBalanceRepository: BrokerBalanceRepositoryProtocol = BackendPortfolioBalanceRepository()
    ) {
        self.userName = userName
        self.onboardingRepository = onboardingRepository
        self.brokerageConnectionRepository = brokerageConnectionRepository
        self.brokerBalanceRepository = brokerBalanceRepository
    }

    var recommendedInstitution: AccountInstitution {
        AuthMockData.brokerageInstitutions.first(where: { $0.id == AccountInstitution.koreaInvestmentID })
            ?? AuthMockData.brokerageInstitutions[0]
    }

    var brokerageInstitutions: [AccountInstitution] {
        let orderedIDs = [
            AccountInstitution.koreaInvestmentID,
            "mirae",
            "kiwoom",
            "samsung_securities",
            "nh_invest",
            "shinhan_invest"
        ]

        return orderedIDs.compactMap { id in
            AuthMockData.brokerageInstitutions.first(where: { $0.id == id })
        }
    }

    var connectableInstitutionIDs: Set<String> {
        [AccountInstitution.koreaInvestmentID]
    }

    var connectedInstitution: AccountInstitution? {
        guard let connectedInstitutionID else { return nil }
        return AuthMockData.brokerageInstitutions.first(where: { $0.id == connectedInstitutionID })
    }

    // MARK: - Step 1~2: 투자 목적 · 목표 금액

    func selectFinancialGoal(_ goal: FinancialGoal) {
        financialGoal = goal
        if !hasCustomTargetAmount {
            targetAmount = goal.defaultTargetAmount
        }
    }

    func updateTargetAmount(_ amount: Int64) {
        targetAmount = amount
        hasCustomTargetAmount = amount != financialGoal.defaultTargetAmount
    }

    // MARK: - Step 5: 투자 성향 소프트컨펌

    func profileConflictsWithDrawdown(_ profile: InvestmentProfile) -> Bool {
        guard let maxDrawdownTolerance else { return false }
        return !RiskProfileConsistency.isConsistent(profile: profile, tolerance: maxDrawdownTolerance)
    }

    // MARK: - Step 6: 관심 섹터

    var canAdvanceFromWatchAssetsStep: Bool {
        (1...5).contains(selectedWatchAssets.count)
    }

    func toggleWatchAsset(_ sector: WatchAssetSector) {
        if selectedWatchAssets.contains(sector) {
            selectedWatchAssets.remove(sector)
            return
        }

        guard selectedWatchAssets.count < 5 else { return }
        selectedWatchAssets.insert(sector)
    }

    // MARK: - Step 7: 계좌 연결

    func canConnect(_ institution: AccountInstitution) -> Bool {
        connectableInstitutionIDs.contains(institution.id)
    }

    func selectInstitution(_ institution: AccountInstitution) {
        guard canConnect(institution) else { return }
        connectedInstitutionID = institution.id
    }

    func skipBrokerageConnection() {
        connectedInstitutionID = nil
        isBrokerageConnected = false
        activeLinkStage = nil
        completedLinkStages = []
        linkedAccount = nil
        brokerageAccountId = nil
        brokerageLinkErrorMessage = nil
    }

    // MARK: - Step 8: 완료 처리

    /// 서버가 요청을 정상 수신했다는 응답을 받았을 때만 true를 반환한다. 실패/미응답이어도
    /// 온보딩 자체는 막지 않되, 호출부(Step8 완료 화면)가 이 결과를 보고 목업 대기 여부를 결정한다.
    func submitSettings(userId: Int64?) async -> Bool {
        guard let userId else { return false }

        do {
            try await onboardingRepository.updateSettings(
                userId: userId,
                investmentHorizon: investmentHorizon ?? .threeToFiveYears,
                maxDrawdownTolerance: maxDrawdownTolerance ?? .withinTen,
                investmentProfile: investmentProfile ?? .balanced
            )
            return true
        } catch {
            return false
        }
    }

    func submitWatchAssets(userId: Int64?) async -> Bool {
        guard let userId else { return false }

        do {
            try await onboardingRepository.updateWatchAssets(
                userId: userId,
                sectors: Array(selectedWatchAssets)
            )
            return true
        } catch {
            return false
        }
    }

    /// Step 7 "연결하기" 시점에 호출된다.
    ///
    /// 서버의 KIS 모의투자 계좌를 연결하고, 동기화 후 포트폴리오를 조회한다.
    /// 세 단계가 모두 성공한 경우에만 연결 완료로 처리한다.
    func connectBrokerage(userId: Int64?, reduceMotion: Bool) async -> Bool {
        guard let institutionID = connectedInstitutionID else { return false }
        guard !isBrokerageConnected else { return true }

        completedLinkStages = []
        linkedAccount = nil
        brokerageAccountId = nil
        brokerageLinkErrorMessage = nil

        guard userId != nil else {
            brokerageLinkErrorMessage = "로그인 정보를 확인할 수 없어요. 다시 로그인해 주세요."
            return false
        }

        let stageDuration: UInt64 = reduceMotion ? 120_000_000 : 620_000_000

        do {
            activeLinkStage = .authenticating
            async let minimumConnectionDelay: Void = Task.sleep(nanoseconds: stageDuration)
            let connection = try await brokerageConnectionRepository.connectKISDemoAccount(
                institutionID: institutionID
            )
            try? await minimumConnectionDelay
            brokerageAccountId = connection.accountId
            completedLinkStages.insert(.authenticating)

            activeLinkStage = .verifyingAccount
            try await Task.sleep(nanoseconds: stageDuration)
            guard connection.status == .connected else {
                throw BrokerageConnectionError.connectionRejected
            }
            completedLinkStages.insert(.verifyingAccount)

            activeLinkStage = .loadingHoldings
            async let minimumPortfolioDelay: Void = Task.sleep(nanoseconds: stageDuration)
            try await brokerageConnectionRepository.sync(accountId: connection.accountId)
            let balance = try await brokerBalanceRepository.fetchPortfolioBalance()
            try? await minimumPortfolioDelay
            completedLinkStages.insert(.loadingHoldings)

            linkedAccount = LinkedDemoAccount(
                accountNumber: balance.accountNumber.isEmpty ? connection.accountNumber : balance.accountNumber,
                holdingCount: balance.holdings.count,
                totalEvaluationAmount: balance.totalEvaluationAmount
            )
            activeLinkStage = nil
            isBrokerageConnected = true
            return true
        } catch {
            activeLinkStage = nil
            isBrokerageConnected = false
            brokerageLinkErrorMessage = error.localizedDescription
            return false
        }
    }

    func submitGoal(userId: Int64?) async -> Bool {
        guard let userId else { return false }

        do {
            try await onboardingRepository.updateGoal(
                userId: userId,
                financialGoal: financialGoal,
                targetAmount: targetAmount
            )
            return true
        } catch {
            APIFallbackLog.log("PATCH /api/users/\(userId)/goal", error: error)
            return false
        }
    }

    func makeOnboardingResult() -> OnboardingResult {
        let rebalancing = OnboardingRebalancingPreference(
            investmentProfile: investmentProfile ?? .balanced,
            investmentHorizon: investmentHorizon ?? .threeToFiveYears,
            maxDrawdownTolerance: maxDrawdownTolerance ?? .withinTen
        )

        return OnboardingResult(
            connectedInstitutionIDs: connectedInstitutionID.map { [$0] } ?? [],
            selectedSectorIDs: [],
            selectedKeywordIDs: [],
            investmentStyleID: (investmentProfile ?? .balanced).legacyStyle.rawValue,
            rebalancingPreference: rebalancing,
            selectedAssetSymbols: [],
            primaryAssetSymbol: nil,
            financialGoal: financialGoal.rawValue,
            targetAmount: targetAmount,
            selectedWatchAssetIDs: selectedWatchAssets.map(\.rawValue),
            isBrokerageConnected: isBrokerageConnected
        )
    }
}
