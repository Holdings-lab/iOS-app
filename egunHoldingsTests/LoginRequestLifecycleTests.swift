import Alamofire
import Foundation
import Testing
@testable import egunHoldings

@MainActor
struct LoginRequestLifecycleTests {
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

    private var loginSession: LoginSession {
        LoginSession(userId: 42, email: "new@test.example", nickname: "new", accessToken: "new-login",
                     refreshToken: "new-refresh", accessTokenExpiresIn: 1800, onboardingCompleted: true)
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
