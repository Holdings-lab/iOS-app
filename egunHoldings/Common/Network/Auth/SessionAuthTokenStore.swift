import Foundation

extension Notification.Name {
    /// 백그라운드에서 액세스 토큰이 갱신되었을 때 발생 (예: 401 재시도, 선제적 만료 갱신).
    /// userInfo["expiresAt"]에 새 만료 시각(Date)이 담긴다.
    nonisolated static let authTokensDidUpdate = Notification.Name("SessionAuthTokenStore.authTokensDidUpdate")
    /// 리프레시 토큰까지 무효화되어 재로그인이 필요할 때 발생.
    nonisolated static let authTokensDidClear = Notification.Name("SessionAuthTokenStore.authTokensDidClear")
}

nonisolated final class SessionAuthTokenStore: AuthTokenStore, @unchecked Sendable {
    private let sessionStore: AuthSessionStoring

    init(sessionStore: AuthSessionStoring = KeychainAuthSessionStore()) {
        self.sessionStore = sessionStore
    }

    nonisolated func currentAccessToken() -> String? {
        sessionStore.load()?.token
    }

    nonisolated func currentRefreshToken() -> String? {
        sessionStore.load()?.refreshToken
    }

    nonisolated func currentExpiresAt() -> Date? {
        sessionStore.load()?.expiresAt
    }

    nonisolated func updateTokens(_ payload: AuthTokenPayload) {
        guard var session = sessionStore.load() else {
            return
        }

        session.token = payload.accessToken
        session.refreshToken = payload.refreshToken ?? session.refreshToken
        session.expiresAt = payload.expiresAt
        sessionStore.save(session)

        NotificationCenter.default.post(
            name: .authTokensDidUpdate,
            object: self,
            userInfo: ["expiresAt": payload.expiresAt]
        )
    }

    nonisolated func clearTokens() {
        sessionStore.clear()
        NotificationCenter.default.post(name: .authTokensDidClear, object: self)
    }
}
