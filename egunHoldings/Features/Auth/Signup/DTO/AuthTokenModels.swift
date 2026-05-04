import Foundation

nonisolated struct AuthTokenPayload: Sendable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date
}

protocol AuthTokenStore: Sendable {
    nonisolated func currentAccessToken() -> String?
    nonisolated func currentRefreshToken() -> String?
    nonisolated func updateTokens(_ payload: AuthTokenPayload)
    nonisolated func clearTokens()
}

protocol AccessTokenRefreshing: Sendable {
    nonisolated func refreshAccessToken() async throws -> AuthTokenPayload
}
