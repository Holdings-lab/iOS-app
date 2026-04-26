import Foundation

nonisolated enum NetworkConfiguration {
    // When this value is missing, the app falls back to mock news data and insight responses.
    static var policyBackendBaseURL: URL? {
        configuredURL(forInfoKey: "POLICY_BACKEND_BASE_URL")
    }

    static var tradingServerBaseURL: URL? {
        if let configuredURL = configuredURL(forInfoKey: "TRADING_SERVER_BASE_URL") {
            return configuredURL
        }

#if DEBUG
        return URL(string: "http://localhost:8080")
#else
        return nil
#endif
    }

    static var authRefreshURL: URL? {
        guard let policyBackendBaseURL else {
            return nil
        }

        return policyBackendBaseURL.appendingPathComponent("v1/auth/refresh")
    }

    static var tradingKisAccountNumber: String? {
        if let configured = configuredString(forInfoKey: "TRADING_KIS_ACCOUNT_NUMBER") {
            return configured
        }

#if DEBUG
        return "50181876"
#else
        return nil
#endif
    }

    static var tradingKisProductCode: String? {
        if let configured = configuredString(forInfoKey: "TRADING_KIS_PRODUCT_CODE") {
            return configured
        }

#if DEBUG
        return "01"
#else
        return nil
#endif
    }

    private static func configuredURL(forInfoKey key: String) -> URL? {
        guard let rawValue = configuredString(forInfoKey: key) else {
            return nil
        }

        return URL(string: rawValue)
    }

    private static func configuredString(forInfoKey key: String) -> String? {
        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        return trimmed
    }
}
