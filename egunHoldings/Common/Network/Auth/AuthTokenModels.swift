import Foundation

nonisolated struct AuthTokenPayload: Sendable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date
}

nonisolated enum AuthTokenDefaults {
    /// 서버 응답에 `accessTokenExpiresIn`이 없을 때 가정하는 액세스 토큰 수명(초).
    ///
    /// 서버 API LIST의 로그인 응답 예시에는 이 필드가 없다(`userId`/`email`/`nickname`/
    /// `accessToken`/`refreshToken`/`onboardingCompleted`만 명시). 필수 필드로 두면 서버가
    /// 실제로 내려주지 않는 순간 로그인 전체가 디코딩 실패로 죽으므로, 누락 시 이 값으로
    /// 만료 시각을 잡고 진짜 만료 판정은 401 리액티브 갱신(AuthRefreshInterceptor.retry)에 맡긴다.
    /// 선제적 갱신이 조기에 트리거되지 않도록 짧게 잡지 않는다.
    static let assumedAccessTokenLifetime: Int64 = 3600
}

protocol AuthTokenStore: Sendable {
    nonisolated func currentAccessToken() -> String?
    nonisolated func currentRefreshToken() -> String?
    nonisolated func currentExpiresAt() -> Date?
    nonisolated func updateTokens(_ payload: AuthTokenPayload)
    nonisolated func clearTokens()
}

extension AuthTokenStore {
    /// 액세스 토큰이 이미 만료되었거나 `leeway` 이내로 임박했는지 여부.
    nonisolated func isAccessTokenExpiring(leeway: TimeInterval = 30) -> Bool {
        guard let expiresAt = currentExpiresAt() else {
            return false
        }
        return Date().addingTimeInterval(leeway) >= expiresAt
    }
}

protocol AccessTokenRefreshing: Sendable {
    nonisolated func refreshAccessToken() async throws -> AuthTokenPayload
}
