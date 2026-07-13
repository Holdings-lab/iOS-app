import Foundation

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

    nonisolated func updateTokens(_ payload: AuthTokenPayload) {
        guard var session = sessionStore.load() else {
            return
        }

        session.token = payload.accessToken
        session.refreshToken = payload.refreshToken
        session.expiresAt = payload.expiresAt
        sessionStore.save(session)
    }

    nonisolated func clearTokens() {
        sessionStore.clear()
    }
}
