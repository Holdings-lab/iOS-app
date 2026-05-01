import Foundation

nonisolated struct LivePolicyNewsRepository: PolicyNewsRepositoryProtocol {
    private let apiClient: APIClient
    private let fallbackRepository: MockPolicyNewsRepository

    init(
        apiClient: APIClient = APIClientFactory.makeDefault(),
        fallbackRepository: MockPolicyNewsRepository = MockPolicyNewsRepository()
    ) {
        self.apiClient = apiClient
        self.fallbackRepository = fallbackRepository
    }

    func fetchNews() async throws -> [PolicyNewsItem] {
        let requestBody = try NetworkJSONCoding.encodeJSON(
            PolicyNewsFeedRequestDTO(cursor: nil, limit: 20)
        )

        do {
            let response = try await apiClient.requestResult(
                BackendEndpoint.policyFeed(body: requestBody),
                as: PolicyNewsFeedResponseDTO.self
            )

            return response.toDomainItems()
        } catch {
            guard Self.shouldUseFallback(for: error) else {
                throw error
            }

            return try await fallbackRepository.fetchNews()
        }
    }

    func fetchInsight(for item: PolicyNewsItem, userAssetProfile: UserAssetProfile) async throws -> PolicyNewsInsight {
        try await fallbackRepository.fetchInsight(for: item, userAssetProfile: userAssetProfile)
    }

    private static func shouldUseFallback(for error: Error) -> Bool {
        switch error {
        case NetworkError.httpStatus(404), NetworkError.notImplemented:
            return true
        case NetworkError.apiFailure(let statusCode, _, _):
            return statusCode == 404
        default:
            return false
        }
    }
}
