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
    @Published private(set) var brokerageConnectionId: String?

    // MARK: - Step 7 연결 연출 상태

    @Published private(set) var activeLinkStage: BrokerageLinkStage?
    @Published private(set) var completedLinkStages: Set<BrokerageLinkStage> = []
    /// 연결이 끝난 뒤 요약 카드에 노출할 계좌 정보. 잔고 조회가 실패하면 nil로 남는다.
    @Published private(set) var linkedAccount: LinkedDemoAccount?

    private let onboardingRepository: OnboardingRepositoryProtocol
    private let brokerageConnectionRepository: BrokerageConnectionRepositoryProtocol
    private let brokerBalanceRepository: BrokerBalanceRepositoryProtocol
    private var hasCustomTargetAmount = false

    init(
        userName: String = "회원",
        onboardingRepository: OnboardingRepositoryProtocol = LiveOnboardingRepository(),
        brokerageConnectionRepository: BrokerageConnectionRepositoryProtocol = LiveBrokerageConnectionRepository(),
        brokerBalanceRepository: BrokerBalanceRepositoryProtocol = KisSandboxBalanceRepository()
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
    /// 크리덴셜 입력이 없는 대신 실제로 두 가지 일을 한다 — 서버에 연동 레코드를 만들고,
    /// 모의투자 잔고를 한 번 조회해 계좌가 실제로 응답하는지 확인한다. 단계 표시는 이 두
    /// 요청이 끝날 때까지 순차로 진행되며, 최소 노출 시간을 두어 한 프레임에 스쳐 지나가지 않게 한다.
    /// 백엔드가 아직 준비되지 않아 둘 다 실패하더라도 온보딩 진행 자체는 막지 않는다.
    func connectBrokerage(userId: Int64?, reduceMotion: Bool) async {
        guard let institutionID = connectedInstitutionID, !isBrokerageConnected else { return }

        completedLinkStages = []
        linkedAccount = nil

        let connectionTask: Task<BrokerageConnection?, Never> = Task { [brokerageConnectionRepository] in
            guard let userId else { return nil }
            return try? await brokerageConnectionRepository.connect(userId: userId, institutionID: institutionID)
        }

        let stageDuration: UInt64 = reduceMotion ? 120_000_000 : 620_000_000

        activeLinkStage = .authenticating
        try? await Task.sleep(nanoseconds: stageDuration)
        let connection = await connectionTask.value
        brokerageConnectionId = connection?.connectionId
        completedLinkStages.insert(.authenticating)

        activeLinkStage = .verifyingAccount
        let balanceTask: Task<BrokerBalanceSnapshot?, Never> = Task { [brokerBalanceRepository] in
            try? await brokerBalanceRepository.fetchKisSandboxBalance()
        }
        try? await Task.sleep(nanoseconds: stageDuration)
        let balance = await balanceTask.value
        completedLinkStages.insert(.verifyingAccount)

        activeLinkStage = .loadingHoldings
        try? await Task.sleep(nanoseconds: stageDuration)
        completedLinkStages.insert(.loadingHoldings)

        linkedAccount = LinkedDemoAccount(
            accountNumber: balance?.accountNumber ?? connection?.accountNumber,
            holdingCount: balance?.holdings.count,
            totalEvaluationAmount: balance?.totalEvaluationAmount
        )
        activeLinkStage = nil
        isBrokerageConnected = true
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
