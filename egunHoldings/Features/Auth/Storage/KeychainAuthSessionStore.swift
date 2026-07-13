import Foundation

nonisolated final class KeychainAuthSessionStore: AuthSessionStoring, @unchecked Sendable {
    private let keychain: KeychainStore
    private let account = "policy_finance.auth.session.v1"
    private let legacyStore: AuthSessionStoring
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        keychain: KeychainStore = KeychainStore(),
        legacyStore: AuthSessionStoring = AuthSessionStore()
    ) {
        self.keychain = keychain
        self.legacyStore = legacyStore
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    nonisolated func load() -> AppUserSession? {
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
