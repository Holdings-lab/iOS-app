import Alamofire
import Foundation
import Testing
@testable import egunHoldings

@MainActor
struct LoginRequestLifecycleTests {
    @Test("새 설치는 남아 있는 Keychain 세션을 지우고 로그인 후 재실행에서 오늘 탭으로 복원한다")
    func freshInstallRequiresLoginThenRestoresSession() throws {
        let suite = "fresh-install-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        let keychain = InMemoryKeychain()
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = KeychainAuthSessionStore(
            keychain: keychain,
            legacyStore: AuthSessionStore(defaults: defaults),
            defaults: defaults
        )
        store.save(AppUserSession(userId: 99, token: "old", refreshToken: "old-refresh",
                                  expiresAt: .distantFuture, userName: "old", email: "old@test.example",
                                  onboardingCompleted: true))

        let router = AppRouter(store: store, accountStore: AuthAccountStore(defaults: defaults))
        #expect(router.route == .auth)
        #expect(store.load() == nil)

        router.handleLoginSuccess(loginSession: loginSession)
        let restarted = AppRouter(store: store, accountStore: AuthAccountStore(defaults: defaults))
        #expect(restarted.route == .main)
        #expect(restarted.session?.refreshToken == "new-refresh")
    }

    @Test("기존 설치의 계정 기록이 있으면 Keychain 로그인 세션을 유지한다")
    func existingInstallPreservesSession() throws {
        let suite = "existing-install-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        let keychain = InMemoryKeychain()
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = KeychainAuthSessionStore(
            keychain: keychain,
            legacyStore: AuthSessionStore(defaults: defaults),
            defaults: defaults
        )
        store.save(AppUserSession(userId: 42, token: "valid", refreshToken: "refresh",
                                  expiresAt: .distantFuture, userName: "test", email: "test@example.invalid",
                                  onboardingCompleted: true))
        defaults.set(Data(), forKey: AuthAccountStore.storageKey)

        let router = AppRouter(store: store, accountStore: AuthAccountStore(defaults: defaults))
        #expect(router.route == .main)
        #expect(router.session?.token == "valid")
    }

    @Test("만료된 액세스 토큰은 저장된 리프레시 토큰으로 갱신한 뒤 메인으로 간다")
    func restoresExpiredAccessTokenWithRefresh() async throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let store = AuthSessionStore(defaults: defaults)
        store.save(AppUserSession(userId: 42, token: "expired", refreshToken: "refresh",
                                  expiresAt: .distantPast, userName: "test", email: "test@example.invalid",
                                  onboardingCompleted: true))
        let refresher = CountingLoginRefresher(error: nil)
        let router = AppRouter(store: store, accountStore: AuthAccountStore(defaults: defaults),
                               tokenRefresher: refresher)
        await waitUntil { router.route != .loading }
        #expect(router.route == .main)
        #expect(store.load()?.token == "new")
        #expect(await refresher.count == 1)
    }

    @Test("리프레시 토큰이 거부되면 저장된 세션을 지우고 로그인으로 간다")
    func expiredRefreshRequiresLogin() async throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let store = AuthSessionStore(defaults: defaults)
        store.save(AppUserSession(userId: 42, token: "expired", refreshToken: "expired-refresh",
                                  expiresAt: .distantPast, userName: "test", email: "test@example.invalid",
                                  onboardingCompleted: true))
        let router = AppRouter(store: store, accountStore: AuthAccountStore(defaults: defaults),
                               tokenRefresher: CountingLoginRefresher(error: .httpStatus(401)))
        await waitUntil { router.route != .loading }
        #expect(router.route == .auth)
        #expect(store.load() == nil)
    }

    @Test("메인 화면을 열 때 인증 토큰은 이미 저장되어 있다")
    func persistsBeforeOpeningTabs() throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let store = AuthSessionStore(defaults: defaults)
        let router = AppRouter(store: store, accountStore: AuthAccountStore(defaults: defaults))
        router.handleLoginSuccess(loginSession: loginSession)
        #expect(router.route == .main)
        #expect(store.load()?.token == loginSession.accessToken)
        #expect(SessionAuthTokenStore(sessionStore: store).currentAccessToken() == loginSession.accessToken)
    }

    @Test("로그아웃은 저장된 최신 리프레시 토큰을 서버에 폐기 요청하고 로컬 세션을 지운다")
    func logoutRevokesCurrentRefreshToken() async throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let store = AuthSessionStore(defaults: defaults)
        let repository = LogoutRecordingRepository()
        let router = AppRouter(store: store, accountStore: AuthAccountStore(defaults: defaults),
                               loginRepository: repository)
        router.handleLoginSuccess(loginSession: loginSession)

        var rotatedSession = try #require(store.load())
        rotatedSession.refreshToken = "rotated-refresh"
        store.save(rotatedSession)

        router.logout()

        #expect(router.route == .auth)
        #expect(router.session == nil)
        #expect(store.load() == nil)
        for _ in 0..<1000 {
            if await repository.recordedToken != nil { break }
            await Task.yield()
        }
        #expect(await repository.recordedToken == "rotated-refresh")
    }

    @Test("이전 부트스트랩 갱신 응답이 새 로그인 세션을 덮지 않는다")
    func ignoresBootstrapResponseAfterNewLogin() async throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let store = AuthSessionStore(defaults: defaults)
        store.save(AppUserSession(userId: 99, token: "expired", refreshToken: "expired-refresh",
                                 expiresAt: .distantPast, userName: "old", email: "old@test.example",
                                 onboardingCompleted: true))
        let refresher = DelayedLoginRefresher()
        let router = AppRouter(store: store, accountStore: AuthAccountStore(defaults: defaults), tokenRefresher: refresher)
        await refresher.waitUntilStarted()
        router.handleLoginSuccess(loginSession: loginSession)
        await refresher.finish()
        await Task.yield()
        #expect(router.session?.userId == loginSession.userId)
        #expect(store.load()?.token == loginSession.accessToken)
    }

    @Test("401 재시도는 갱신한 인증 헤더를 사용한다")
    func replacesAuthorizationOnRetry() async throws {
        let fixture = AuthNetworkFixture(statuses: [401, 200])
        defer { fixture.remove() }
        let value = try await fixture.client.request(fixture.endpoint, as: AuthTestValue.self)
        #expect(value.value == 1)
        #expect(fixture.state.headers == ["Bearer old", "Bearer new"])
        #expect(await fixture.refresher.count == 1)
    }

    @Test("반복되는 401은 한 번만 갱신하고 종료한다")
    func limitsRepeatedUnauthorizedResponses() async {
        // 세 번째 200은 이전 무한 재시도 구현에서도 테스트가 종료되게 하는 안전장치다.
        let fixture = AuthNetworkFixture(statuses: [401, 401, 200])
        defer { fixture.remove() }
        do {
            _ = try await fixture.client.request(fixture.endpoint, as: AuthTestValue.self)
            Issue.record("두 번째 401에서 실패해야 한다")
        } catch {}
        #expect(fixture.state.headers.count == 2)
        #expect(await fixture.refresher.count == 1)
    }

    @Test("갱신 서버 500은 세션을 지우지 않는다")
    func preservesSessionOnTemporaryRefreshFailure() async {
        let fixture = AuthNetworkFixture(statuses: [401], refreshError: .httpStatus(500))
        defer { fixture.remove() }
        _ = try? await fixture.client.request(fixture.endpoint, as: AuthTestValue.self)
        #expect(fixture.tokens.currentAccessToken() == "old")
        #expect(!AuthRefreshInterceptor.invalidatesSession(URLError(.timedOut)))
        #expect(AuthRefreshInterceptor.invalidatesSession(NetworkError.httpStatus(401)))
    }

    @Test("재실행 시 갱신 서버 500은 저장된 로그인 정보를 유지한다")
    func preservesBootstrapSessionOnTemporaryFailure() async throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let store = AuthSessionStore(defaults: defaults)
        store.save(AppUserSession(userId: 42, token: "expired", refreshToken: "refresh",
                                 expiresAt: .distantPast, userName: "test", email: "test@example.invalid",
                                 onboardingCompleted: true))
        let router = AppRouter(store: store, accountStore: AuthAccountStore(defaults: defaults),
                               tokenRefresher: CountingLoginRefresher(error: .httpStatus(500)))
        await waitUntil { router.route != .loading }
        #expect(router.route == .main)
        #expect(store.load()?.token == "expired")
    }

    @Test("이미 갱신된 토큰의 뒤늦은 401은 추가 갱신을 만들지 않는다")
    func skipsRefreshForSupersededToken() async throws {
        let store = LoginTestTokenStore()
        let refresher = CountingLoginRefresher(error: nil)
        let coordinator = TokenRefreshCoordinator()
        _ = try await coordinator.refresh(using: refresher, token: "old", store: store)
        let late = try await coordinator.refresh(using: refresher, token: "old", store: store)
        #expect(late.accessToken == "new")
        #expect(await refresher.count == 1)
    }

    @Test("이전 세션의 폐기 알림이 새 로그인을 지우지 않는다")
    func ignoresOldClearNotificationAfterNewLogin() async throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let store = AuthSessionStore(defaults: defaults)
        let router = AppRouter(store: store, accountStore: AuthAccountStore(defaults: defaults))
        // receive(on: .main)으로 전달될 때까지 새 로그인 저장이 먼저 끝난다.
        NotificationCenter.default.post(name: .authTokensDidClear, object: nil)
        router.handleLoginSuccess(loginSession: loginSession)
        // 메인 큐 알림 전달 뒤에 검사한다.
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
        #expect(router.route == .main)
        #expect(store.load()?.token == loginSession.accessToken)
    }

    private func waitUntil(_ predicate: () -> Bool) async {
        for _ in 0..<1000 {
            if predicate() { return }
            await Task.yield()
        }
        #expect(predicate())
    }

    private var loginSession: LoginSession {
        LoginSession(userId: 42, email: "new@test.example", nickname: "new", accessToken: "new-login",
                     refreshToken: "new-refresh", accessTokenExpiresIn: 1800, onboardingCompleted: true)
    }
}

nonisolated private final class InMemoryKeychain: KeychainValueStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var entries: [String: Data] = [:]

    func read(account: String) -> Data? {
        lock.withLock { entries[account] }
    }

    func save(_ data: Data, account: String) {
        lock.withLock { entries[account] = data }
    }

    func delete(account: String) {
        lock.withLock { _ = entries.removeValue(forKey: account) }
    }
}

private actor LogoutRecordingRepository: LoginRepositoryProtocol {
    private(set) var recordedToken: String?

    func login(email: String, password: String) async throws -> LoginSession {
        throw NetworkError.invalidResponse
    }

    func oauthLogin(provider: String, authorizationCode: String, redirectURI: String) async throws -> LoginOAuthSession {
        throw NetworkError.invalidResponse
    }

    func logout(refreshToken: String) async throws {
        recordedToken = refreshToken
    }
}

private actor DelayedLoginRefresher: AccessTokenRefreshing {
    private var gate: CheckedContinuation<AuthTokenPayload, Never>?
    private var started: CheckedContinuation<Void, Never>?
    private var didStart = false
    func refreshAccessToken() async throws -> AuthTokenPayload {
        didStart = true
        started?.resume()
        return await withCheckedContinuation { gate = $0 }
    }
    func waitUntilStarted() async {
        if didStart { return }
        await withCheckedContinuation { started = $0 }
    }
    func finish() {
        gate?.resume(returning: AuthTokenPayload(accessToken: "old-refreshed", refreshToken: nil,
                                                 expiresAt: Date().addingTimeInterval(1800)))
        gate = nil
    }
}

private actor CountingLoginRefresher: AccessTokenRefreshing {
    private(set) var count = 0
    let error: NetworkError?
    init(error: NetworkError?) { self.error = error }
    func refreshAccessToken() async throws -> AuthTokenPayload {
        count += 1
        if let error { throw error }
        return AuthTokenPayload(accessToken: "new", refreshToken: "refresh", expiresAt: .distantFuture)
    }
}

nonisolated private final class LoginTestTokenStore: AuthTokenStore, @unchecked Sendable {
    private let lock = NSLock()
    private var token: String? = "old"
    func currentAccessToken() -> String? { lock.withLock { token } }
    func currentRefreshToken() -> String? { "refresh" }
    func currentExpiresAt() -> Date? { .distantFuture }
    func updateTokens(_ payload: AuthTokenPayload) { lock.withLock { token = payload.accessToken } }
    func clearTokens() { lock.withLock { token = nil } }
}

nonisolated private struct AuthTestValue: Decodable { let value: Int }

@MainActor
private struct AuthNetworkFixture {
    let tokens = LoginTestTokenStore()
    let refresher: CountingLoginRefresher
    let state: LoginResponseState
    let client: MoyaAPIClient
    let endpoint: Endpoint

    init(statuses: [Int], refreshError: NetworkError? = nil) {
        let id = UUID().uuidString
        state = LoginResponseState(statuses: statuses)
        LoginResponseProtocol.add(state, for: id)
        refresher = CountingLoginRefresher(error: refreshError)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [LoginResponseProtocol.self]
        let session = Alamofire.Session(configuration: configuration,
            interceptor: AuthRefreshInterceptor(tokenStore: tokens, refresher: refresher))
        client = MoyaAPIClient(session: session, plugins: [AuthorizationHeaderPlugin(tokenStore: tokens)])
        endpoint = Endpoint(baseURL: URL(string: "https://auth-tests.invalid")!, path: "/\(id)",
                            authorizationRequirement: .bearerToken)
    }
    func remove() { LoginResponseProtocol.remove(endpoint.path) }
}

nonisolated private final class LoginResponseState: @unchecked Sendable {
    private let lock = NSLock()
    private var statuses: [Int]
    private var recordedHeaders: [String] = []
    init(statuses: [Int]) { self.statuses = statuses }
    var headers: [String] { lock.withLock { recordedHeaders } }
    func receive(_ request: URLRequest) -> Int {
        lock.withLock {
            recordedHeaders.append(request.value(forHTTPHeaderField: "Authorization") ?? "none")
            return statuses.isEmpty ? 200 : statuses.removeFirst()
        }
    }
}

nonisolated private final class LoginResponseProtocol: URLProtocol, @unchecked Sendable {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var states: [String: LoginResponseState] = [:]
    static func add(_ state: LoginResponseState, for id: String) { lock.withLock { states["/" + id] = state } }
    static func remove(_ path: String) { lock.withLock { states[path] = nil } }
    override class func canInit(with request: URLRequest) -> Bool { request.url?.host == "auth-tests.invalid" }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let url = request.url, let state = Self.lock.withLock({ Self.states[url.path] }) else { return }
        let status = state.receive(request)
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil,
                                       headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(#"{"value":1}"#.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
