import Foundation
@preconcurrency import Alamofire

nonisolated private struct AuthRefreshRequestDTO: Encodable, Sendable {
    let refreshToken: String
}

/// 서버 `AuthDto.TokenResponse` 계약과 1:1로 대응한다: 만료 시각이 아니라
/// 만료까지 남은 초(accessTokenExpiresIn)를 내려주므로 여기서 절대 시각으로 환산한다.
///
/// 주의: `/api/auth/refresh`는 서버 API LIST에 등재되어 있지 않다. 계약이 확정되기 전까지
/// `accessTokenExpiresIn`은 옵셔널로 두어, 필드가 없다는 이유만으로 갱신이 실패하고
/// 세션이 강제 종료되는 일이 없도록 한다.
nonisolated private struct AuthRefreshResponseDTO: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String?
    let accessTokenExpiresIn: Int64?

    var resolvedExpiresIn: Int64 {
        accessTokenExpiresIn ?? AuthTokenDefaults.assumedAccessTokenLifetime
    }

    func toDomain() -> AuthTokenPayload {
        AuthTokenPayload(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(resolvedExpiresIn))
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
            TokenDebugLog.log("리프레시 실패 → 저장된 refreshToken 없음. 재로그인이 필요합니다.")
            throw NetworkError.missingRefreshToken
        }

        TokenDebugLog.log("액세스 토큰 갱신 요청 시작 → \(refreshURL.absoluteString)")

        let decoder = NetworkJSONCoding.makeDecoder()

        do {
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

            let payload = result.toDomain()
            TokenDebugLog.log("액세스 토큰 갱신 성공 → 새 만료시각까지 \(result.resolvedExpiresIn)초(서버 명시=\(result.accessTokenExpiresIn != nil)), refreshToken 재발급=\(result.refreshToken != nil)")
            return payload
        } catch {
            TokenDebugLog.log("액세스 토큰 갱신 요청 실패 → \(error)")
            throw error
        }
    }
}
