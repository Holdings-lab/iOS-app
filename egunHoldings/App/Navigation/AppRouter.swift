import Combine
import Foundation

@MainActor
final class AppRouter: ObservableObject {
    @Published private(set) var route: AppRoute = .loading
    @Published private(set) var userAssetProfile: UserAssetProfile = AppMockData.userAssetProfile
    @Published private(set) var portfolioSnapshot: PortfolioSnapshot = AppMockData.portfolioSnapshot
    @Published private(set) var userName: String = "투자자"

    private let store: AuthSessionStoring
    private let accountStore: AuthAccountStoring
    private let brokerBalanceRepository: BrokerBalanceRepositoryProtocol
    private let loginRepository: LoginRepositoryProtocol
    private let tokenRefresher: AccessTokenRefreshing
    private(set) var session: AppUserSession?
    private var lastAuthenticatedEmail: String?
    private var tokenNotificationCancellables = Set<AnyCancellable>()

    init(
        store: AuthSessionStoring? = nil,
        accountStore: AuthAccountStoring? = nil,
        brokerBalanceRepository: BrokerBalanceRepositoryProtocol? = nil,
        loginRepository: LoginRepositoryProtocol? = nil,
        tokenRefresher: AccessTokenRefreshing? = nil
    ) {
        let resolvedStore = store ?? KeychainAuthSessionStore()
        self.store = resolvedStore
        self.accountStore = accountStore ?? AuthAccountStore()
        self.brokerBalanceRepository = brokerBalanceRepository ?? KisSandboxBalanceRepository()
        self.loginRepository = loginRepository ?? LiveLoginRepository()
        self.tokenRefresher = tokenRefresher ?? AlamofireAccessTokenRefresher(
            tokenStore: SessionAuthTokenStore(sessionStore: resolvedStore),
            refreshURL: NetworkConfiguration.authRefreshURL
        )
        observeTokenLifecycleNotifications()
        bootstrap()
    }

    func bootstrap() {
        guard let savedSession = store.load() else {
            clearSessionAndMoveToAuth()
            return
        }

        guard savedSession.isTokenValid else {
            // 액세스 토큰(30분)은 만료됐어도 리프레시 토큰(14일)이 살아있을 확률이 높은 흔한 경로다.
            // 여기서 바로 로그인 화면으로 보내면 30분마다 재로그인해야 하는 셈이라, 리프레시를 먼저 시도한다.
            Task {
                await attemptBootstrapRefresh(savedSession)
            }
            return
        }

        resumeSession(savedSession)
    }

    /// 저장된 세션을 화면 상태로 복원한다(부트스트랩 직행 경로와 부트스트랩-갱신-성공 경로가 공유).
    private func resumeSession(_ savedSession: AppUserSession) {
        session = savedSession
        lastAuthenticatedEmail = savedSession.email
        applySessionDerivedData(from: savedSession)

        route = savedSession.onboardingCompleted ? .main : .onboarding

        if shouldRefreshBrokerBalance(for: savedSession) {
            Task {
                await refreshBrokerBalance(forSessionToken: savedSession.token)
            }
        }
    }

    /// 액세스 토큰은 만료됐지만 리프레시 토큰이 있는 상태로 앱이 (재)실행됐을 때, 로그인 화면을 보여주기 전에
    /// 조용히 한 번 갱신을 시도한다. 성공하면 세션을 그대로 복원하고, 리프레시 토큰까지 무효면 로그인으로 보낸다.
    private func attemptBootstrapRefresh(_ savedSession: AppUserSession) async {
        guard let refreshToken = savedSession.refreshToken, !refreshToken.isEmpty else {
            TokenDebugLog.log("부트스트랩: 액세스 토큰 만료 + 리프레시 토큰 없음 → 재로그인 필요")
            clearSessionAndMoveToAuth()
            return
        }

        TokenDebugLog.log("부트스트랩: 액세스 토큰 만료 감지 → 리프레시 토큰으로 세션 복원 시도")

        do {
            let payload = try await tokenRefresher.refreshAccessToken()

            var refreshedSession = savedSession
            refreshedSession.token = payload.accessToken
            refreshedSession.refreshToken = payload.refreshToken ?? savedSession.refreshToken
            refreshedSession.expiresAt = payload.expiresAt
            store.save(refreshedSession)

            TokenDebugLog.log("부트스트랩 갱신 성공 → 재로그인 없이 세션 복원 (만료까지 \(Int(payload.expiresAt.timeIntervalSinceNow))초)")
            resumeSession(refreshedSession)
        } catch {
            TokenDebugLog.log("부트스트랩 갱신 실패 → 리프레시 토큰도 무효함, 재로그인 필요: \(error)")
            clearSessionAndMoveToAuth()
        }
    }

    func handleLoginSuccess(loginSession: LoginSession) {
        let existingAccount = registeredAccount(for: loginSession.email)
        let newSession = AppUserSession(
            userId: loginSession.userId,
            token: loginSession.accessToken,
            refreshToken: loginSession.refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(loginSession.accessTokenExpiresIn)),
            userName: loginSession.nickname,
            email: loginSession.email,
            onboardingCompleted: loginSession.onboardingCompleted,
            onboardingResult: existingAccount?.onboardingResult,
            brokerBalanceSnapshot: existingAccount?.brokerBalanceSnapshot
        )
        TokenDebugLog.log("로그인 성공 → 액세스 토큰 만료까지 \(loginSession.accessTokenExpiresIn)초, refreshToken 발급=\(loginSession.refreshToken != nil)")

        let isNewUser = newSession.onboardingCompleted == false
        applySession(newSession)
        route = isNewUser ? .onboarding : .main
        persistSessionAfterRoute(newSession)

        if shouldRefreshBrokerBalance(for: newSession) {
            Task {
                await refreshBrokerBalance(forSessionToken: newSession.token)
            }
        }
    }

    func completeOnboarding(with result: OnboardingResult) {
        guard var currentSession = session ?? makeFallbackSession(for: result) else {
            userAssetProfile = AuthMockData.makeAssetProfile(from: result)
            portfolioSnapshot = AppMockData.portfolioSnapshot
            route = .main
            return
        }

        currentSession.onboardingCompleted = true
        currentSession.onboardingResult = result
        currentSession.brokerBalanceSnapshot = nil

        applySession(currentSession)
        route = .main
        persistSessionAfterRoute(currentSession)

        if shouldRefreshBrokerBalance(for: currentSession) {
            Task {
                await refreshBrokerBalance(forSessionToken: currentSession.token)
            }
        }
    }

    func logout() {
        let refreshToken = session?.refreshToken
        clearSessionAndMoveToAuth()
        revokeRefreshTokenOnServer(refreshToken)
    }

    func registeredAccount(for email: String) -> RegisteredAuthAccount? {
        accountStore.loadAll().first { $0.normalizedEmail == normalizedEmail(from: email) }
    }

    private func applySessionDerivedData(from session: AppUserSession) {
        userName = session.userName

        if let brokerBalanceSnapshot = session.brokerBalanceSnapshot {
            userAssetProfile = brokerBalanceSnapshot.toUserAssetProfile()
            portfolioSnapshot = brokerBalanceSnapshot.toPortfolioSnapshot()
        } else {
            userAssetProfile = AuthMockData.makeAssetProfile(from: session.onboardingResult)
            portfolioSnapshot = AppMockData.portfolioSnapshot
        }
    }

    private func applySession(_ session: AppUserSession) {
        self.session = session
        lastAuthenticatedEmail = session.email
        applySessionDerivedData(from: session)
    }

    private func saveSession(_ session: AppUserSession) {
        applySession(session)
        persistSessionNow(session)
    }

    private func persistSessionAfterRoute(_ session: AppUserSession) {
        Task { [weak self] in
            await Task.yield()
            guard let self else { return }
            guard let currentSession = self.session else { return }

            if currentSession.token == session.token,
               currentSession.onboardingCompleted && !session.onboardingCompleted {
                return
            }

            self.persistSessionNow(session)
        }
    }

    private func persistSessionNow(_ session: AppUserSession) {
        store.save(session)
        syncRegisteredAccount(with: session)
    }

    private func clearSessionAndMoveToAuth() {
        session = nil
        lastAuthenticatedEmail = nil
        userAssetProfile = AppMockData.userAssetProfile
        portfolioSnapshot = AppMockData.portfolioSnapshot
        userName = "투자자"
        store.clear()
        route = .auth
    }

    /// 서버에 리프레시 토큰 폐기를 알린다. 최선 노력(best-effort)이며 실패해도 로컬 로그아웃은 이미 끝난 뒤라 UX에 영향 없음.
    private func revokeRefreshTokenOnServer(_ refreshToken: String?) {
        guard let refreshToken, !refreshToken.isEmpty else { return }

        Task { [loginRepository] in
            do {
                try await loginRepository.logout(refreshToken: refreshToken)
                TokenDebugLog.log("서버 로그아웃(리프레시 토큰 폐기) 완료")
            } catch {
                TokenDebugLog.log("서버 로그아웃 요청 실패(로컬 세션은 이미 종료됨): \(error)")
            }
        }
    }

    /// 네트워크 계층(AuthRefreshInterceptor)이 백그라운드에서 토큰을 갱신/폐기할 때 AppRouter에도 반영한다.
    private func observeTokenLifecycleNotifications() {
        NotificationCenter.default.publisher(for: .authTokensDidUpdate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncSessionWithTokenStore()
            }
            .store(in: &tokenNotificationCancellables)

        NotificationCenter.default.publisher(for: .authTokensDidClear)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleRefreshTokenInvalidated()
            }
            .store(in: &tokenNotificationCancellables)
    }

    /// 실제 인증 헤더는 매 요청마다 Keychain에서 새로 읽으므로 이 동기화가 없어도 네트워크 요청은
    /// 항상 올바른 토큰을 쓴다. 다만 `session.token`을 참조하는 화면 로직(예: 잔고조회 토큰 비교)이
    /// 백그라운드 갱신 이후에도 옛 토큰을 들고 있지 않도록 메모리 상의 사본을 최신화해 둔다.
    private func syncSessionWithTokenStore() {
        guard var currentSession = session, let refreshed = store.load(), refreshed.token != currentSession.token else {
            return
        }

        currentSession.token = refreshed.token
        currentSession.refreshToken = refreshed.refreshToken
        currentSession.expiresAt = refreshed.expiresAt
        session = currentSession
        TokenDebugLog.log("백그라운드 토큰 갱신 감지 → AppRouter 세션 동기화 완료 (만료까지 \(Int(refreshed.expiresAt.timeIntervalSinceNow))초)")
    }

    /// 리프레시 토큰까지 무효화되어 자동 갱신이 완전히 실패한 경우, 화면을 즉시 로그인으로 되돌린다.
    private func handleRefreshTokenInvalidated() {
        guard route != .auth else { return }
        TokenDebugLog.log("리프레시 토큰 만료/무효 감지 → 로그인 화면으로 전환합니다")
        clearSessionAndMoveToAuth()
    }

    private func normalizedEmail(from email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func syncRegisteredAccount(with session: AppUserSession) {
        var accounts = accountStore.loadAll()
        guard let index = accounts.firstIndex(where: { $0.normalizedEmail == normalizedEmail(from: session.email) }) else {
            return
        }

        accounts[index].userId = session.userId
        accounts[index].onboardingCompleted = session.onboardingCompleted
        accounts[index].onboardingResult = session.onboardingResult
        accounts[index].brokerBalanceSnapshot = session.brokerBalanceSnapshot
        accountStore.saveAll(accounts)
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
            userId: account.userId,
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

    private func refreshBrokerBalance(forSessionToken sessionToken: String) async {
        do {
            Self.debugLog("로그인/부트스트랩 잔고조회 시작: token=\(Self.redactedToken(sessionToken))")
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
        }
    }

    private static func debugLog(_ message: String) {
#if DEBUG
        print("[BrokerBalance] \(message)")
#endif
    }

    /// 액세스 토큰 원문 대신 로그에서 세션을 구분할 수 있는 정도로만 노출한다(비밀번호에 준하는
    /// 값이라 콘솔/스크린샷/화면 공유로 유출되면 만료 전까지 그 사용자로 API를 호출할 수 있다).
    private static func redactedToken(_ token: String) -> String {
        "\(token.prefix(8))…(\(token.count)자)"
    }
}
