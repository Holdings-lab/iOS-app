import Foundation

nonisolated final class KeychainAuthSessionStore: AuthSessionStoring, @unchecked Sendable {
    private let keychain: any KeychainValueStoring
    private let account = "policy_finance.auth.session.v1"
    private let firstLaunchKey = "policy_finance.auth.install_initialized.v1"
    private let legacyStore: AuthSessionStoring
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        keychain: any KeychainValueStoring = KeychainStore(),
        legacyStore: AuthSessionStoring = AuthSessionStore(),
        defaults: UserDefaults = .standard
    ) {
        self.keychain = keychain
        self.legacyStore = legacyStore
        self.defaults = defaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    nonisolated func load() -> AppUserSession? {
        if !defaults.bool(forKey: firstLaunchKey) {
            // Keychain survives app deletion, while UserDefaults does not. A genuinely fresh install
            // must start at login even if this device still has a session from an earlier install.
            // Existing installations have either an account record or a legacy session to preserve.
            if defaults.data(forKey: AuthAccountStore.storageKey) == nil && legacyStore.load() == nil {
                keychain.delete(account: account)
            }
            defaults.set(true, forKey: firstLaunchKey)
        }

        if let data = keychain.read(account: account),
           let session = try? decoder.decode(AppUserSession.self, from: data) {
            return session
        }

        // 기존 UserDefaults 세션을 1회 마이그레이션한다 (Keychain 전환 이전 설치 대응).
        guard let legacySession = legacyStore.load() else {
            return nil
        }

        save(legacySession)
        legacyStore.clear()
        return legacySession
    }

    nonisolated func save(_ session: AppUserSession) {
        guard let data = try? encoder.encode(session) else {
            return
        }
        keychain.save(data, account: account)
    }

    nonisolated func clear() {
        keychain.delete(account: account)
    }
}
