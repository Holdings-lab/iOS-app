import Foundation

nonisolated enum PolicyNewsRepositoryFactory {
    static func makeDefault() -> PolicyNewsRepositoryProtocol {
        guard let baseURL = NetworkConfiguration.policyBackendBaseURL else {
            return MockPolicyNewsRepository()
        }

        return LivePolicyNewsRepository(baseURL: baseURL)
    }
}
