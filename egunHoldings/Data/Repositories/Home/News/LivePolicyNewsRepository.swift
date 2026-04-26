import Foundation

nonisolated struct LivePolicyNewsRepository: PolicyNewsRepositoryProtocol {
    private let apiClient: APIClient
    private let baseURL: URL

    init(apiClient: APIClient = APIClientFactory.makeDefault(), baseURL: URL) {
        self.apiClient = apiClient
        self.baseURL = baseURL
    }

    func fetchNews() async throws -> [PolicyNewsItem] {
        let response = try await apiClient.request(
            Endpoint(
                baseURL: baseURL,
                path: "/v1/policy-news",
                authorizationRequirement: .bearerToken
            ),
            as: PolicyNewsFeedResponseDTO.self
        )

        return response.items.map { $0.toDomain() }
    }

    func fetchInsight(for item: PolicyNewsItem, userAssetProfile: UserAssetProfile) async throws -> PolicyNewsInsight {
        let requestBody = try JSONEncoder().encode(
            PolicyNewsInsightRequestDTO(item: item, userAssetProfile: userAssetProfile)
        )

        let response = try await apiClient.request(
            Endpoint(
                baseURL: baseURL,
                path: "/v1/policy-news/\(escapedPathComponent(item.id))/insight",
                method: .post,
                headers: ["Content-Type": "application/json"],
                body: requestBody,
                authorizationRequirement: .bearerToken
            ),
            as: PolicyNewsInsightResponseDTO.self
        )

        return response.toDomain()
    }

    private func escapedPathComponent(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? value
    }
}
