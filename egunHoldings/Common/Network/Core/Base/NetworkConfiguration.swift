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

    /// 액세스 토큰 갱신 엔드포인트. Info.plist에 별도 오버라이드가 없으면
    /// 백엔드 베이스 URL의 `/api/auth/refresh`로 폴백한다(별도 설정 없이도 항상 동작하도록).
    /// 항상 유효한 URL을 반환하므로(옵셔널 아님) 리프레시 관련 코드가 매번 nil 분기를 신경 쓸 필요가 없다.
    static var authRefreshURL: URL {
        if let configuredURL = configuredURL(forInfoKey: "AUTH_REFRESH_URL") {
            return configuredURL
        }

        return backendBaseURL.appendingPathComponent("api/auth/refresh")
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
