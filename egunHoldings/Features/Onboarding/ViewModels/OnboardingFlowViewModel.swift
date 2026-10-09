import Combine
import Foundation

struct OnboardingSubmissionFailure: Equatable {
    let stepTitle: String
    let endpoint: String
    let errorCode: String
    let message: String
}

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
    /// 계좌 연결을 계속해도 성공할 수 없는 인증 실패인지 여부.
    /// 화면은 이 상태일 때만 사용자를 로그인 화면으로 안내한다.
    @Published private(set) var requiresBrokerageReauthentication = false
    @Published private(set) var onboardingSubmissionFailure: OnboardingSubmissionFailure?

    private let onboardingRepository: OnboardingRepositoryProtocol
    private let brokerageConnectionRepository: BrokerageConnectionRepositoryProtocol
    private let brokerBalanceRepository: BrokerBalanceRepositoryProtocol
    private let authTokenStore: AuthTokenStore
    private var hasCustomTargetAmount = false

    init(
        userName: String = "회원",
        onboardingRepository: OnboardingRepositoryProtocol = LiveOnboardingRepository(),
        brokerageConnectionRepository: BrokerageConnectionRepositoryProtocol = LiveBrokerageConnectionRepository(),
        brokerBalanceRepository: BrokerBalanceRepositoryProtocol = BackendPortfolioBalanceRepository(),
        authTokenStore: AuthTokenStore = SessionAuthTokenStore()
    ) {
        self.userName = userName
        self.onboardingRepository = onboardingRepository
        self.brokerageConnectionRepository = brokerageConnectionRepository
        self.brokerBalanceRepository = brokerBalanceRepository
        self.authTokenStore = authTokenStore
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

    func skipBrokerageConnection() async -> Bool {
        do {
            try await onboardingRepository.skipBrokerageConnection()
        } catch {
            recordSubmissionFailure(
                stepTitle: "계좌 연결 건너뛰기",
                endpoint: "POST /api/onboarding/account/skip",
                error: error
            )
            brokerageLinkErrorMessage = onboardingSubmissionFailure?.message
            return false
        }

        connectedInstitutionID = nil
        isBrokerageConnected = false
        activeLinkStage = nil
        completedLinkStages = []
        linkedAccount = nil
        brokerageAccountId = nil
        brokerageLinkErrorMessage = nil
        requiresBrokerageReauthentication = false
        return true
    }

    // MARK: - Step 8: 완료 처리

    /// 목표 금액은 `/api/goal`에서 먼저 저장한다. 직접 입력한 금액도 같은 계약으로 전송한다.
    func submitGoal(userId: Int64?) async -> Bool {
        guard let userId else {
            recordMissingUserFailure(stepTitle: "투자 목표", endpoint: "PATCH /api/goal")
            return false
        }

        do {
            onboardingSubmissionFailure = nil
            try await onboardingRepository.updateGoal(
                userId: userId,
                financialGoal: financialGoal,
                targetAmount: targetAmount
            )
            return true
        } catch {
            recordSubmissionFailure(stepTitle: "투자 목표", endpoint: "PATCH /api/goal", error: error)
            return false
        }
    }

    /// 관심 섹터를 포함한 프로필은 목표 저장 뒤, 마지막으로 한 번만 저장한다.
    func submitProfile(userId: Int64?) async -> Bool {
        guard let userId else {
            recordMissingUserFailure(stepTitle: "맞춤 설정", endpoint: "PATCH /api/onboarding/profile")
            return false
        }

        do {
            onboardingSubmissionFailure = nil
            try await onboardingRepository.updateProfile(
                userId: userId,
                investmentHorizon: investmentHorizon ?? .threeToFiveYears,
                maxDrawdownTolerance: maxDrawdownTolerance ?? .withinTen,
                investmentProfile: investmentProfile ?? .balanced,
                interests: selectedWatchAssets.sorted { $0.rawValue < $1.rawValue }
            )
            return true
        } catch {
            recordSubmissionFailure(
                stepTitle: "맞춤 설정",
                endpoint: "PATCH /api/onboarding/profile",
                error: error
            )
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
            requiresBrokerageReauthentication = true
            return false
        }

        guard let accessToken = authTokenStore.currentAccessToken(), !accessToken.isEmpty else {
            TokenDebugLog.log("온보딩 계좌 연결 중단 → 저장된 access token 없음")
            brokerageLinkErrorMessage = AppVocabulary.ErrorMessage.loginExpired
            requiresBrokerageReauthentication = true
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
            requiresBrokerageReauthentication = Self.isAuthenticationFailure(error)
            if requiresBrokerageReauthentication {
                TokenDebugLog.log("온보딩 계좌 연결 인증 실패 → 재로그인 필요")
                brokerageLinkErrorMessage = AppVocabulary.ErrorMessage.loginExpired
            } else {
                brokerageLinkErrorMessage = error.localizedDescription
            }
            return false
        }
    }

    private static func isAuthenticationFailure(_ error: Error) -> Bool {
        guard let networkError = error as? NetworkError else {
            return false
        }

        switch networkError {
        case .httpStatus(401), .missingRefreshToken:
            return true
        case .apiFailure(let statusCode, let code, _):
            return statusCode == 401 || code == "AUTH_REQUIRED"
        default:
            return false
        }
    }

    private func recordMissingUserFailure(stepTitle: String, endpoint: String) {
        onboardingSubmissionFailure = OnboardingSubmissionFailure(
            stepTitle: stepTitle,
            endpoint: endpoint,
            errorCode: "AUTH_REQUIRED",
            message: "로그인 정보를 확인할 수 없어요. 다시 로그인해 주세요."
        )
        logSubmissionFailure(onboardingSubmissionFailure!)
    }

    private func recordSubmissionFailure(stepTitle: String, endpoint: String, error: Error) {
        let networkError = error as? NetworkError
        let errorCode: String
        let message: String

        switch networkError {
        case .apiFailure(_, let code, let serverMessage):
            errorCode = code
            message = serverMessage
        case .httpStatus(let statusCode):
            errorCode = "HTTP_\(statusCode)"
            message = error.localizedDescription
        default:
            errorCode = "REQUEST_FAILED"
            message = error.localizedDescription
        }

        onboardingSubmissionFailure = OnboardingSubmissionFailure(
            stepTitle: stepTitle,
            endpoint: endpoint,
            errorCode: errorCode,
            message: message
        )
        logSubmissionFailure(onboardingSubmissionFailure!)
    }

    private func logSubmissionFailure(_ failure: OnboardingSubmissionFailure) {
        #if DEBUG
        print("[Onboarding] \(failure.endpoint) failed (\(failure.errorCode)): \(failure.message)")
        #endif
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
