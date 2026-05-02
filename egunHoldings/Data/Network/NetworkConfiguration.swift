import Foundation

nonisolated enum NetworkConfiguration {
    static var backendBaseURL: URL {
        if let configuredURL = configuredURL(forInfoKey: "BACKEND_BASE_URL")
            ?? configuredURL(forInfoKey: "POLICY_BACKEND_BASE_URL") {
            return configuredURL
        }

        return URL(string: "https://holdings-lab.me")!
    }

    static var mlServiceBaseURL: URL {
        if let configuredURL = configuredURL(forInfoKey: "ML_SERVICE_BASE_URL") {
            return configuredURL
        }

        return backendBaseURL
    }

    static var policyBackendBaseURL: URL? {
        backendBaseURL
    }

    static var tradingServerBaseURL: URL? {
        if let configuredURL = configuredURL(forInfoKey: "TRADING_SERVER_BASE_URL") {
            return configuredURL
        }

        return backendBaseURL
    }

    static var authRefreshURL: URL? {
        configuredURL(forInfoKey: "AUTH_REFRESH_URL")
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
