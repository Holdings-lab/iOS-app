import Foundation
@preconcurrency import Alamofire
@preconcurrency import Moya

nonisolated enum APIClientFactory {
    static func makeDefault() -> APIClient {
        let tokenStore = SessionAuthTokenStore()
        var plugins: [PluginType] = [
            AuthorizationHeaderPlugin(tokenStore: tokenStore),
        ]

#if DEBUG
        plugins.append(ConsoleNetworkLoggerPlugin())
#endif

        let session = makeSession(tokenStore: tokenStore)
        return MoyaAPIClient(session: session, plugins: plugins)
    }

    private static func makeSession(tokenStore: AuthTokenStore) -> Alamofire.Session {
        guard let refreshURL = NetworkConfiguration.authRefreshURL else {
            return Alamofire.Session()
        }

        let refresher = AlamofireAccessTokenRefresher(
            tokenStore: tokenStore,
            refreshURL: refreshURL
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
