import Foundation

protocol AuthAccountStoring: Sendable {
    nonisolated func loadAll() -> [RegisteredAuthAccount]
    nonisolated func saveAll(_ accounts: [RegisteredAuthAccount])
}

nonisolated final class AuthAccountStore: AuthAccountStoring, @unchecked Sendable {
    nonisolated static let storageKey = "policy_finance.auth.accounts.v1"
    private let defaults: UserDefaults
    private let key = AuthAccountStore.storageKey
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    nonisolated func loadAll() -> [RegisteredAuthAccount] {
        guard let data = defaults.data(forKey: key),
              let storedAccounts = try? decoder.decode([RegisteredAuthAccount].self, from: data)
        else {
            return AuthMockData.defaultRegisteredAccounts
        }

        return storedAccounts
    }

    nonisolated func saveAll(_ accounts: [RegisteredAuthAccount]) {
        guard let data = try? encoder.encode(accounts) else {
            return
        }

        defaults.set(data, forKey: key)
    }

}
