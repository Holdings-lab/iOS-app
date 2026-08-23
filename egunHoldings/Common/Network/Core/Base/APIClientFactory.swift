import Foundation
@preconcurrency import Alamofire
@preconcurrency import Moya

nonisolated enum APIClientFactory {
    private static let shared: APIClient = makeClient()

    static func makeDefault() -> APIClient {
        shared
    }

    private static func makeClient() -> APIClient {
        let tokenStore = SessionAuthTokenStore()
        var plugins: [PluginType] = [
            AuthorizationHeaderPlugin(tokenStore: tokenStore),
        ]

        // NetworkLoggerPlugin(.verbose)는 요청/응답 바디(액세스 토큰 헤더 포함)를 그대로 콘솔에 찍는다.
        // 릴리즈 빌드에서 계속 켜져 있으면 응답이 큰 API에서 로깅 자체가 지연을 유발하고,
        // 토큰이 프로덕션 콘솔 로그에 남는 보안 문제도 있어 DEBUG 빌드로 한정한다.
        #if DEBUG
        plugins.append(NetworkLoggerPlugin(configuration: .init(logOptions: [.verbose])))
        plugins.append(TokenDebugLoggerPlugin(tokenStore: tokenStore))
        #endif

        let session = makeSession(tokenStore: tokenStore)
        return MoyaAPIClient(session: session, plugins: plugins)
    }

    private static func makeSession(tokenStore: AuthTokenStore) -> Alamofire.Session {
        let refresher = AlamofireAccessTokenRefresher(
            tokenStore: tokenStore,
            refreshURL: NetworkConfiguration.authRefreshURL
        )

        let interceptor = AuthRefreshInterceptor(
            tokenStore: tokenStore,
            refresher: refresher
        )

        return Alamofire.Session(
            interceptor: interceptor
        )
    }
}
