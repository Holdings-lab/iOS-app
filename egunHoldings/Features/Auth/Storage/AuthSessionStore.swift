import Foundation

protocol AuthSessionStoring: Sendable {
    nonisolated func load() -> AppUserSession?
    nonisolated func save(_ session: AppUserSession)
    nonisolated func clear()
}

nonisolated final class AuthSessionStore: AuthSessionStoring, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key = "policy_finance.auth.session.v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    nonisolated func load() -> AppUserSession? {
        guard let data = defaults.data(forKey: key) else {
            return nil
        }
        return try? decoder.decode(AppUserSession.self, from: data)
    }

    nonisolated func save(_ session: AppUserSession) {
        guard let data = try? encoder.encode(session) else {
            return
        }
        defaults.set(data, forKey: key)
    }

    nonisolated func clear() {
        defaults.removeObject(forKey: key)
    }
}
