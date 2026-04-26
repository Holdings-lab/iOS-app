import Foundation

protocol AuthAccountStoring: Sendable {
    nonisolated func loadAll() -> [RegisteredAuthAccount]
    nonisolated func saveAll(_ accounts: [RegisteredAuthAccount])
}

nonisolated final class AuthAccountStore: AuthAccountStoring, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key = "policy_finance.auth.accounts.v1"
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

        return mergedWithDefaultAccounts(storedAccounts)
    }

    nonisolated func saveAll(_ accounts: [RegisteredAuthAccount]) {
        guard let data = try? encoder.encode(accounts) else {
            return
        }

        defaults.set(data, forKey: key)
    }

    private nonisolated func mergedWithDefaultAccounts(_ storedAccounts: [RegisteredAuthAccount]) -> [RegisteredAuthAccount] {
        var mergedAccounts = storedAccounts

        for defaultAccount in AuthMockData.defaultRegisteredAccounts {
            if let existingIndex = mergedAccounts.firstIndex(where: { account in
                account.normalizedEmail == defaultAccount.normalizedEmail
            }) {
                // Demo accounts should remain deterministic even if an older local copy exists.
                mergedAccounts[existingIndex] = defaultAccount
            } else {
                mergedAccounts.append(defaultAccount)
            }
        }

        return mergedAccounts
    }
}
