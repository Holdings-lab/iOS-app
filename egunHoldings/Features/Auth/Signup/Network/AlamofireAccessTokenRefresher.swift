import Foundation
@preconcurrency import Alamofire

nonisolated private struct AuthRefreshRequestDTO: Encodable, Sendable {
    let refreshToken: String
}

nonisolated private struct AuthRefreshResponseDTO: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date?

    func toDomain() -> AuthTokenPayload {
        AuthTokenPayload(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt ?? Date().addingTimeInterval(60 * 60 * 24 * 14)
        )
    }
}

nonisolated final class AlamofireAccessTokenRefresher: AccessTokenRefreshing, @unchecked Sendable {
    private let session: Alamofire.Session
    private let tokenStore: AuthTokenStore
    private let refreshURL: URL

    init(
        session: Alamofire.Session = Alamofire.Session(),
        tokenStore: AuthTokenStore,
        refreshURL: URL
    ) {
        self.session = session
        self.tokenStore = tokenStore
        self.refreshURL = refreshURL
    }

    func refreshAccessToken() async throws -> AuthTokenPayload {
        guard let refreshToken = tokenStore.currentRefreshToken(), !refreshToken.isEmpty else {
            throw NetworkError.missingRefreshToken
        }

        let decoder = NetworkJSONCoding.makeDecoder()

        let response = try await session
            .request(
                refreshURL,
                method: .post,
                parameters: AuthRefreshRequestDTO(refreshToken: refreshToken),
                encoder: JSONParameterEncoder.default
            )
            .validate(statusCode: 200 ..< 300)
            .serializingDecodable(APIResponse<AuthRefreshResponseDTO>.self, decoder: decoder)
            .value

        guard response.isSuccess, let result = response.result else {
            throw NetworkError.apiFailure(
                statusCode: nil,
                code: response.code,
                message: response.message
            )
        }

        return result.toDomain()
    }
}
