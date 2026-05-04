import Foundation
@preconcurrency import Alamofire
@preconcurrency import Moya

nonisolated enum APIClientFactory {
    static func makeDefault() -> APIClient {
        let tokenStore = SessionAuthTokenStore()
        var plugins: [PluginType] = [
            AuthorizationHeaderPlugin(tokenStore: tokenStore),
        ]

        let logger = NetworkLoggerPlugin(configuration: .init(logOptions: [.verbose]))
        plugins.append(logger)

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
