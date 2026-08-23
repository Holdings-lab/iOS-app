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

        // 4개 섹션은 서로 독립적인 GET이라 병렬로 조회하고, 한 섹션이 실패해도 나머지는 그대로 반영한다.
        async let briefingResult = fetchBriefing(userId: userId, fallback: fallback.briefing)
        async let holdingsResult = fetchHoldings(userId: userId, fallback: fallback.holdings)
        async let goalResult = fetchGoal(userId: userId, fallback: fallback.goalProgress)
        async let newsResult = fetchNews(userId: userId, fallback: fallback.newsItems)

        let (briefing, holdings, goal, news) = await (briefingResult, holdingsResult, goalResult, newsResult)

        return TodayDashboard(
            userAssetProfile: userAssetProfile,
            portfolioSnapshot: portfolioSnapshot,
            isAccountLinked: briefing.isAccountLinked ?? holdings.isAccountLinked ?? goal.isAccountLinked ?? fallback.isAccountLinked,
            briefing: briefing.value,
            holdings: holdings.value,
            goalProgress: goal.value,
            newsItems: news
        )
    }

    private func fetchBriefing(
        userId: Int64,
        fallback: TodayBriefing
    ) async -> (isAccountLinked: Bool?, value: TodayBriefing) {
        do {
            let response = try await apiClient.requestResult(
                BackendEndpoint.dailyBriefing(),
                as: TodayDailyBriefingResponseDTO.self
            )
            return (response.isAccountLinked, response.toDomain(fallback: fallback))
        } catch {
            APIFallbackLog.log("GET /api/users/\(userId)/daily-briefing", error: error)
            return (nil, fallback)
        }
    }

    private func fetchHoldings(
        userId: Int64,
        fallback: [TodayHolding]
    ) async -> (isAccountLinked: Bool?, value: [TodayHolding]) {
        do {
            let response = try await apiClient.requestResult(
                BackendEndpoint.todayHoldings(),
                as: TodayHoldingsResponseDTO.self
            )
            return (response.isAccountLinked, response.toDomain(fallback: fallback))
        } catch {
            APIFallbackLog.log("GET /api/users/\(userId)/holdings", error: error)
            return (nil, fallback)
        }
    }

    private func fetchGoal(
        userId: Int64,
        fallback: TodayGoalProgress?
    ) async -> (isAccountLinked: Bool?, value: TodayGoalProgress?) {
        do {
            let response = try await apiClient.requestResult(
                BackendEndpoint.goal(),
                as: TodayGoalResponseDTO.self
            )
            return (response.isAccountLinked, response.toDomain(fallback: fallback))
        } catch {
            APIFallbackLog.log("GET /api/users/\(userId)/goal", error: error)
            return (nil, fallback)
        }
    }

    private func fetchNews(userId: Int64, fallback: [TodayNewsItem]) async -> [TodayNewsItem] {
        do {
            let response = try await apiClient.requestResult(
                BackendEndpoint.holdingsNews(),
                as: TodayHoldingsNewsResponseDTO.self
            )
            return response.toDomain(fallback: fallback)
        } catch {
            APIFallbackLog.log("GET /api/users/\(userId)/holdings-news", error: error)
            return fallback
        }
    }
}
