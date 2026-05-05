import Foundation

nonisolated struct LiveTodayRepository: TodayRepositoryProtocol {
    private let apiClient: APIClient
    private let fallbackRepository: MockTodayRepository

    init(
        apiClient: APIClient = APIClientFactory.makeDefault(),
        fallbackRepository: MockTodayRepository = MockTodayRepository()
    ) {
        self.apiClient = apiClient
        self.fallbackRepository = fallbackRepository
    }

    func fetchDashboard(
        userId: Int64?,
        userAssetProfile: UserAssetProfile,
        portfolioSnapshot: PortfolioSnapshot
    ) async throws -> TodayDashboard {
        let fallback = try await fallbackRepository.fetchDashboard(
            userId: userId,
            userAssetProfile: userAssetProfile,
            portfolioSnapshot: portfolioSnapshot
        )

        guard let userId else {
            return fallback
        }

        let response = try await apiClient.requestResult(
            BackendEndpoint.todayDashboard(userId: userId),
            as: TodayDashboardResponseDTO.self
        )

        return response.toDomain(fallback: fallback)
    }
}
