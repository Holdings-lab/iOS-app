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

        // TokenDebugLoggerPlugin은 토큰 값이나 응답 본문 없이 경로·상태만 남긴다.
        // Moya의 verbose logger는 DEBUG 빌드에서도 Authorization 헤더와 응답 본문을
        // 콘솔에 기록할 수 있어, 민감정보 노출과 큰 응답의 로깅 지연을 피하기 위해 쓰지 않는다.
        #if DEBUG
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
            configuration: NetworkConfiguration.makeSessionConfiguration(),
            interceptor: interceptor
        )
    }
}
