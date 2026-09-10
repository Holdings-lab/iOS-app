import Foundation

nonisolated struct LiveTodayRepository: TodayRepositoryProtocol {
    private let apiClient: APIClient
    private let fallbackRepository: MockTodayRepository
    private let newsroomRepository: NewsroomDigestRepositoryProtocol
    private let newsTimeout: Duration

    init(
        apiClient: APIClient = APIClientFactory.makeDefault(),
        fallbackRepository: MockTodayRepository = MockTodayRepository(),
        newsroomRepository: NewsroomDigestRepositoryProtocol? = nil,
        newsTimeout: Duration = .seconds(5)
    ) {
        self.apiClient = apiClient
        self.fallbackRepository = fallbackRepository
        self.newsroomRepository = newsroomRepository ?? LiveNewsroomDigestRepository(apiClient: apiClient)
        self.newsTimeout = newsTimeout
    }

    func fetchDashboard(
        userId: Int64?,
        userAssetProfile: UserAssetProfile,
        portfolioSnapshot: PortfolioSnapshot,
        onSection: (@MainActor @Sendable (TodaySectionUpdate) -> Void)? = nil
    ) async throws -> TodayDashboard {
        let fallback = try await fallbackRepository.fetchDashboard(
            userId: userId,
            userAssetProfile: userAssetProfile,
            portfolioSnapshot: portfolioSnapshot
        )

        guard let userId else {
            return fallback
        }

        var briefing: (isAccountLinked: Bool?, value: TodayBriefing) = (nil, fallback.briefing)
        var holdings: (isAccountLinked: Bool?, value: [TodayHolding]) = (nil, fallback.holdings)
        var goal: (isAccountLinked: Bool?, value: TodayGoalProgress?) = (nil, fallback.goalProgress)
        var news: [TodayNewsItem] = []

        // 가장 느린 API를 기다리지 않고 완료된 섹션부터 화면에 전달한다.
        await withTaskGroup(of: TodaySectionUpdate.self) { group in
            group.addTask {
                let result = await fetchBriefing(userId: userId, fallback: fallback.briefing)
                return .briefing(isAccountLinked: result.isAccountLinked, result.value)
            }
            group.addTask {
                let result = await fetchHoldings(userId: userId, fallback: fallback.holdings)
                return .holdings(isAccountLinked: result.isAccountLinked, result.value)
            }
            group.addTask {
                let result = await fetchGoal(userId: userId, fallback: fallback.goalProgress)
                return .goal(isAccountLinked: result.isAccountLinked, result.value)
            }
            group.addTask { .news(await fetchNews()) }

            for await section in group {
                guard !Task<Never, Never>.isCancelled else { continue }
                switch section {
                case let .briefing(linked, value): briefing = (linked, value)
                case let .holdings(linked, value): holdings = (linked, value)
                case let .goal(linked, value): goal = (linked, value)
                case let .news(value): news = value
                }
                onSection?(section)
            }
        }
        try Task<Never, Never>.checkCancellation()

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
            APIFallbackLog.log("GET /api/daily-briefing", error: error)
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
            APIFallbackLog.log("GET /api/holdings", error: error)
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
            APIFallbackLog.log("GET /api/goal-progress", error: error)
            return (nil, fallback)
        }
    }

    func invalidateNews() async {
        await newsroomRepository.invalidateBriefing()
    }

    private func fetchNews() async -> [TodayNewsItem] {
        await withTaskGroup(of: [TodayNewsItem].self) { group in
            group.addTask { await fetchLiveNews() }
            group.addTask {
                try? await Task.sleep(for: newsTimeout)
                return []
            }

            let first = await group.next() ?? []
            group.cancelAll()
            return first
        }
    }

    private func fetchLiveNews() async -> [TodayNewsItem] {
        do {
            let response = try await newsroomRepository.fetchBriefing(briefingDate: nil)
            return response.holdings.filter { $0.briefingType != .quiet }.prefix(3).map { holding in
                TodayNewsItem(
                    id: holding.ticker,
                    title: holding.headline ?? holding.name,
                    summary: holding.summary ?? "새로운 뉴스를 확인해 보세요.",
                    ticker: holding.ticker
                )
            }
        } catch is CancellationError {
            return []
        } catch {
            APIFallbackLog.log("GET /api/newsroom", error: error)
            return []
        }
    }
}
