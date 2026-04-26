import Foundation
@preconcurrency import Moya

nonisolated struct AuthorizationHeaderPlugin: PluginType {
    private let tokenStore: AuthTokenStore

    init(tokenStore: AuthTokenStore) {
        self.tokenStore = tokenStore
    }

    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        guard
            let endpointTarget = target as? EndpointTarget,
            endpointTarget.endpoint.authorizationRequirement == .bearerToken,
            let accessToken = tokenStore.currentAccessToken(),
            !accessToken.isEmpty
        else {
            return request
        }

        var request = request
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }
}
