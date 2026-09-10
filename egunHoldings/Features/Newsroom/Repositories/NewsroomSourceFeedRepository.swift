import Foundation

/// 여러 종목의 선행 로딩은 피드 1회 조회를 공유한다. 계정/보유 종목을 공개 API에 보내지 않는다.
actor NewsroomSourceFeedRepository {
    private let apiClient: APIClient
    private var cached: (feed: NewsroomSourceFeedDTO, expires: Date)?
    private var inFlight: Task<NewsroomSourceFeedDTO, Error>?

    init(apiClient: APIClient) { self.apiClient = apiClient }

    func fetchSources(ticker: String) async throws -> [NewsroomSourceItem] {
        if let cached, cached.expires > Date() { return cached.feed.sources(for: ticker) }
        if let inFlight { return try await inFlight.value.sources(for: ticker) }
        let task = Task {
            try await apiClient.requestResult(BackendEndpoint.newsroomSourceFeed(), as: NewsroomSourceFeedDTO.self)
        }
        inFlight = task
        do {
            let feed = try await task.value
            cached = (feed, Date().addingTimeInterval(60))
            inFlight = nil
            return feed.sources(for: ticker)
        } catch {
            inFlight = nil
            throw error
        }
    }
}
