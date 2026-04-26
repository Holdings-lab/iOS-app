import Combine
import Foundation

@MainActor
final class AppFlowViewModel: ObservableObject {
    @Published private(set) var route: AppRoute = .loading
    @Published private(set) var userAssetProfile: UserAssetProfile = HomeMockData.userAssetProfile
    @Published private(set) var portfolioSnapshot: PortfolioSnapshot = HomeMockData.snapshot
    @Published private(set) var userName: String = "투자자"
    @Published var authErrorMessage: String?

    private let store: AuthSessionStoring
    private let accountStore: AuthAccountStoring
    private let brokerBalanceRepository: BrokerBalanceRepositoryProtocol
    private(set) var session: AppUserSession?
    private var lastAuthenticatedEmail: String?

    init(
        store: AuthSessionStoring? = nil,
        accountStore: AuthAccountStoring? = nil,
        brokerBalanceRepository: BrokerBalanceRepositoryProtocol? = nil
    ) {
        self.store = store ?? AuthSessionStore()
        self.accountStore = accountStore ?? AuthAccountStore()
        self.brokerBalanceRepository = brokerBalanceRepository ?? KisSandboxBalanceRepository()
        bootstrap()
    }

    func bootstrap() {
        guard let savedSession = store.load() else {
            clearSessionAndMoveToAuth()
            return
        }

        guard savedSession.isTokenValid else {
            clearSessionAndMoveToAuth()
            return
        }

        session = savedSession
        lastAuthenticatedEmail = savedSession.email
        applySessionDerivedData(from: savedSession)

        route = savedSession.onboardingCompleted ? .main : .onboarding

        if shouldRefreshBrokerBalance(for: savedSession) {
            Task {
                await refreshBrokerBalance(forSessionToken: savedSession.token, showsUserFacingError: false)
            }
        }
    }

    func login(email: String, password: String) {
        resetAuthError()

        let normalizedEmail = normalizedEmail(from: email)

        guard isValidEmail(normalizedEmail) else {
            authErrorMessage = "올바른 이메일 주소를 입력해주세요."
            return
        }
        guard password.count >= 4 else {
            authErrorMessage = "비밀번호는 4자 이상 입력해주세요."
            return
        }

        guard let account = registeredAccount(for: normalizedEmail) else {
            authErrorMessage = "가입된 계정을 찾지 못했습니다. 회원가입 후 다시 로그인해주세요."
            return
        }
        guard account.password == password else {
            authErrorMessage = "비밀번호가 올바르지 않습니다."
            return
        }

        let isNewUser = account.onboardingCompleted == false

        let newSession = AppUserSession(
            token: UUID().uuidString,
            refreshToken: nil,
            expiresAt: Date().addingTimeInterval(60 * 60 * 24 * 14),
            userName: account.userName,
            email: account.email,
            onboardingCompleted: account.onboardingCompleted,
            onboardingResult: account.onboardingResult,
            brokerBalanceSnapshot: account.brokerBalanceSnapshot
        )

        saveSession(newSession)
        route = isNewUser ? .onboarding : .main

        if shouldRefreshBrokerBalance(for: newSession) {
            Task {
                await refreshBrokerBalance(forSessionToken: newSession.token, showsUserFacingError: false)
            }
        }
    }

    @discardableResult
    func signUp(name: String, email: String, password: String, confirmPassword: String, agreedToTerms: Bool) -> Bool {
        resetAuthError()

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = normalizedEmail(from: email)

        guard !trimmedName.isEmpty else {
            authErrorMessage = "닉네임을 입력해주세요."
            return false
        }
        guard isValidEmail(normalizedEmail) else {
            authErrorMessage = "올바른 이메일 주소를 입력해주세요."
            return false
        }
        guard isValidSignUpPassword(password) else {
            authErrorMessage = "비밀번호는 8~16자의 영문, 숫자, 특수문자를 포함해야 합니다."
            return false
        }
        guard password == confirmPassword else {
            authErrorMessage = "비밀번호와 비밀번호 확인이 일치하지 않습니다."
            return false
        }
        guard agreedToTerms else {
            authErrorMessage = "이용약관 및 개인정보처리방침 동의가 필요합니다."
            return false
        }
        guard registeredAccount(for: normalizedEmail) == nil else {
            authErrorMessage = "이미 가입된 이메일입니다. 로그인하거나 다른 이메일을 사용해주세요."
            return false
        }

        let newAccount = RegisteredAuthAccount(
            userName: trimmedName,
            email: normalizedEmail,
            password: password,
            onboardingCompleted: false,
            onboardingResult: nil,
            brokerBalanceSnapshot: nil
        )

        upsertAccount(newAccount)
        return true
    }

    func login(with provider: SocialLoginProvider) {
        resetAuthError()

        // OAuth 연동 전까지는 탭 이벤트와 분기 지점만 유지한다.
        Self.debugLog("소셜 로그인 탭: provider=\(provider.rawValue)")
    }

    func completeOnboarding(with result: OnboardingResult) {
        resetAuthError()

        guard var currentSession = session ?? makeFallbackSession(for: result) else {
            // UI-only 흐름에서도 마지막 단계는 홈 진입까지 이어지도록 로컬 상태를 우선 반영한다.
            userAssetProfile = AuthMockData.makeAssetProfile(from: result)
            portfolioSnapshot = HomeMockData.snapshot
            route = .main
            return
        }

        currentSession.onboardingCompleted = true
        currentSession.onboardingResult = result
        currentSession.brokerBalanceSnapshot = nil

        saveSession(currentSession)
        route = .main

        if shouldRefreshBrokerBalance(for: currentSession) {
            Task {
                await refreshBrokerBalance(forSessionToken: currentSession.token, showsUserFacingError: false)
            }
        }
    }

    func resetAuthError() {
        authErrorMessage = nil
    }

    func logout() {
        clearSessionAndMoveToAuth()
    }

    private func applySessionDerivedData(from session: AppUserSession) {
        userName = session.userName

        if let brokerBalanceSnapshot = session.brokerBalanceSnapshot {
            userAssetProfile = brokerBalanceSnapshot.toUserAssetProfile()
            portfolioSnapshot = brokerBalanceSnapshot.toPortfolioSnapshot()
        } else {
            userAssetProfile = AuthMockData.makeAssetProfile(from: session.onboardingResult)
            portfolioSnapshot = HomeMockData.snapshot
        }
    }

    private func saveSession(_ session: AppUserSession) {
        self.session = session
        lastAuthenticatedEmail = session.email
        applySessionDerivedData(from: session)
        store.save(session)
        syncRegisteredAccount(with: session)
    }

    private func clearSessionAndMoveToAuth() {
        session = nil
        lastAuthenticatedEmail = nil
        userAssetProfile = HomeMockData.userAssetProfile
        portfolioSnapshot = HomeMockData.snapshot
        userName = "투자자"
        store.clear()
        route = .auth
    }

    private func isValidEmail(_ email: String) -> Bool {
        email.contains("@") && email.contains(".")
    }

    private func isValidSignUpPassword(_ password: String) -> Bool {
        guard password.count >= 8, password.count <= 16 else {
            return false
        }

        let hasLetter = password.range(of: "[A-Za-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecial = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        return hasLetter && hasNumber && hasSpecial
    }

    private func normalizedEmail(from email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func registeredAccount(for email: String) -> RegisteredAuthAccount? {
        accountStore.loadAll().first { $0.normalizedEmail == normalizedEmail(from: email) }
    }

    private func upsertAccount(_ account: RegisteredAuthAccount) {
        var accounts = accountStore.loadAll()

        if let index = accounts.firstIndex(where: { $0.normalizedEmail == account.normalizedEmail }) {
            accounts[index] = account
        } else {
            accounts.append(account)
        }

        accountStore.saveAll(accounts)
    }

    private func syncRegisteredAccount(with session: AppUserSession) {
        guard var account = registeredAccount(for: session.email) else {
            return
        }

        account.userName = session.userName
        account.onboardingCompleted = session.onboardingCompleted
        account.onboardingResult = session.onboardingResult
        account.brokerBalanceSnapshot = session.brokerBalanceSnapshot
        upsertAccount(account)
    }

    private func shouldRefreshBrokerBalance(for session: AppUserSession) -> Bool {
        session.onboardingResult?.connectedInstitutionIDs.contains(AccountInstitution.koreaInvestmentID) == true
            || session.brokerBalanceSnapshot != nil
    }

    private func makeFallbackSession(for result: OnboardingResult) -> AppUserSession? {
        guard let lastAuthenticatedEmail,
              let account = registeredAccount(for: lastAuthenticatedEmail)
        else {
            return nil
        }

        return AppUserSession(
            token: UUID().uuidString,
            refreshToken: nil,
            expiresAt: Date().addingTimeInterval(60 * 60 * 24 * 14),
            userName: account.userName,
            email: account.email,
            onboardingCompleted: false,
            onboardingResult: result,
            brokerBalanceSnapshot: nil
        )
    }

    private func refreshBrokerBalance(forSessionToken sessionToken: String, showsUserFacingError: Bool) async {
        do {
            Self.debugLog("로그인/부트스트랩 잔고조회 시작: sessionToken=\(sessionToken)")
            let snapshot = try await brokerBalanceRepository.fetchKisSandboxBalance()

            guard var currentSession = session, currentSession.token == sessionToken else {
                Self.debugLog("잔고조회 응답 무시: 세션 토큰이 이미 변경되었습니다.")
                return
            }

            currentSession.brokerBalanceSnapshot = snapshot
            saveSession(currentSession)
            Self.debugLog("로그인/부트스트랩 잔고조회 저장 완료: total=\(snapshot.totalEvaluationAmount), cash=\(snapshot.cashAmount)")
        } catch {
            Self.debugLog("로그인/부트스트랩 잔고조회 실패: \(String(describing: error))")
            if showsUserFacingError {
                authErrorMessage = brokerBalanceSyncErrorMessage(for: error)
            }
        }
    }

    private func brokerBalanceSyncErrorMessage(for error: Error) -> String {
        if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
            return description
        }

        switch error {
        case BrokerBalanceRepositoryError.unavailable:
            return "잔고조회 서버 주소가 설정되지 않았습니다."
        case NetworkError.httpStatus(_):
            return "잔고조회 서버가 요청을 처리하지 못했습니다."
        default:
            return "한국투자 시뮬레이션 잔고를 불러오지 못했습니다. 서버 실행 상태를 확인해주세요."
        }
    }

    private static func debugLog(_ message: String) {
#if DEBUG
        print("[BrokerBalance] \(message)")
#endif
    }
}
