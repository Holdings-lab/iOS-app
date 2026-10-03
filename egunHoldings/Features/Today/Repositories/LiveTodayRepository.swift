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
        var news: [TodayNewsItem] = []
        // 목표 진행률은 기기에 저장된 온보딩 목표와 자산 금액으로 뷰모델에서 계산한다.
        onSection?(.goal(isAccountLinked: nil, nil))

        // 가장 느린 API를 기다리지 않고 완료된 섹션부터 화면에 전달한다.
        var fallbackMessage: String?

        await withTaskGroup(of: TodayFetchResult.self) { group in
            group.addTask {
                let result = await fetchBriefing(userId: userId, fallback: fallback.briefing)
                return .briefing(
                    isAccountLinked: result.isAccountLinked,
                    value: result.value,
                    fallbackMessage: result.fallbackMessage
                )
            }
            group.addTask {
                let result = await fetchHoldings(userId: userId, fallback: fallback.holdings)
                return .holdings(
                    isAccountLinked: result.isAccountLinked,
                    value: result.value,
                    fallbackMessage: result.fallbackMessage
                )
            }
            group.addTask { .news(value: await fetchNews()) }

            for await section in group {
                guard !Task<Never, Never>.isCancelled else { continue }
                switch section {
                case let .briefing(linked, value, message):
                    briefing = (linked, value)
                    fallbackMessage = fallbackMessage ?? message
                    onSection?(.briefing(isAccountLinked: linked, value))
                case let .holdings(linked, value, message):
                    holdings = (linked, value)
                    fallbackMessage = fallbackMessage ?? message
                    onSection?(.holdings(isAccountLinked: linked, value))
                case let .news(value):
                    news = value
                    onSection?(.news(value))
                }
            }
        }
        try Task<Never, Never>.checkCancellation()

        return TodayDashboard(
            userAssetProfile: userAssetProfile,
            portfolioSnapshot: portfolioSnapshot,
            isAccountLinked: briefing.isAccountLinked ?? holdings.isAccountLinked ?? fallback.isAccountLinked,
            briefing: briefing.value,
            holdings: holdings.value,
            goalProgress: nil,
            newsItems: news,
            fallbackMessage: fallbackMessage
        )
    }

    private func fetchBriefing(
        userId: Int64,
        fallback: TodayBriefing
    ) async -> (isAccountLinked: Bool?, value: TodayBriefing, fallbackMessage: String?) {
        do {
            let response = try await apiClient.requestResult(
                BackendEndpoint.dailyBriefing(),
                as: TodayDailyBriefingResponseDTO.self
            )
            return (response.isAccountLinked, response.toDomain(fallback: fallback), nil)
        } catch {
            APIFallbackLog.log("GET /api/daily-briefing", error: error)
            return (nil, fallback, Self.liveDataUnavailableMessage)
        }
    }

    private func fetchHoldings(
        userId: Int64,
        fallback: [TodayHolding]
    ) async -> (isAccountLinked: Bool?, value: [TodayHolding], fallbackMessage: String?) {
        do {
            let response = try await apiClient.requestResult(
                BackendEndpoint.todayHoldings(),
                as: TodayHoldingsResponseDTO.self
            )
            return (response.isAccountLinked, response.toDomain(fallback: fallback), nil)
        } catch {
            APIFallbackLog.log("GET /api/holdings", error: error)
            return (nil, fallback, Self.liveDataUnavailableMessage)
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

    private static let liveDataUnavailableMessage = "실시간 데이터를 불러오지 못했어요. 일부 값은 이전 또는 예시 데이터일 수 있습니다."
}

private enum TodayFetchResult: Sendable {
    case briefing(isAccountLinked: Bool?, value: TodayBriefing, fallbackMessage: String?)
    case holdings(isAccountLinked: Bool?, value: [TodayHolding], fallbackMessage: String?)
    case news(value: [TodayNewsItem])
}
