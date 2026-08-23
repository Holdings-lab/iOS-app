import Foundation

nonisolated struct LivePolicyNewsRepository: PolicyNewsRepositoryProtocol {
    private let userId: Int64?
    private let apiClient: APIClient
    private let fallbackRepository: MockPolicyNewsRepository

    init(
        userId: Int64? = nil,
        apiClient: APIClient = APIClientFactory.makeDefault(),
        fallbackRepository: MockPolicyNewsRepository = MockPolicyNewsRepository()
    ) {
        self.userId = userId
        self.apiClient = apiClient
        self.fallbackRepository = fallbackRepository
    }

    func fetchNews() async throws -> [PolicyNewsItem] {
        guard let userId else {
            return try await fallbackRepository.fetchNews()
        }

        do {
            let response = try await apiClient.requestResult(
                BackendEndpoint.policyFeed(userId: userId, limit: 20, category: "all"),
                as: PolicyNewsFeedResponseDTO.self
            )

            return response.toDomainItems()
        } catch {
            guard Self.shouldUseFallback(for: error) else {
                throw error
            }

            APIFallbackLog.log("GET /api/feeds/policy", error: error)
            return try await fallbackRepository.fetchNews()
        }
    }

    func fetchInsight(for item: PolicyNewsItem, userAssetProfile: UserAssetProfile) async throws -> PolicyNewsInsight {
        try await fallbackRepository.fetchInsight(for: item, userAssetProfile: userAssetProfile)
    }

    private static func shouldUseFallback(for error: Error) -> Bool {
        if error is NetworkError {
            return true
        }

        return (error as NSError).domain == NSURLErrorDomain
    }
}
