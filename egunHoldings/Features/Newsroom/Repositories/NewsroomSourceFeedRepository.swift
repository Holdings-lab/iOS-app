import Foundation

/// 여러 종목의 선행 로딩은 피드 1회 조회를 공유한다. 계정/보유 종목을 공개 API에 보내지 않는다.
actor NewsroomSourceFeedRepository {
    private let apiClient: APIClient
    private let currentDate: @Sendable () -> String
    private var cached: (date: String, feed: NewsroomSourceFeedDTO, expires: Date)?
    private var inFlight: (date: String, task: Task<NewsroomSourceFeedDTO, Error>)?

    init(
        apiClient: APIClient,
        currentDate: @escaping @Sendable () -> String = { NewsroomSourceFeedRepository.kstDateString() }
    ) {
        self.apiClient = apiClient
        self.currentDate = currentDate
    }

    func fetchSources(ticker: String) async throws -> [NewsroomSourceItem] {
        let date = currentDate()
        if let cached, cached.date == date, cached.expires > Date() {
            return cached.feed.sources(for: ticker, on: date)
        }
        if let inFlight, inFlight.date == date {
            return try await inFlight.task.value.sources(for: ticker, on: date)
        }
        let task = Task {
            try await apiClient.requestResult(
                BackendEndpoint.newsroomSourceFeed(date: date),
                as: NewsroomSourceFeedDTO.self
            )
        }
        inFlight = (date, task)
        do {
            let feed = try await task.value
            cached = (date, feed, Date().addingTimeInterval(60))
            inFlight = nil
            return feed.sources(for: ticker, on: date)
        } catch {
            inFlight = nil
            throw error
        }
    }

    nonisolated private static func kstDateString(now: Date = Date()) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        return String(format: "%04d-%02d-%02d", components.year!, components.month!, components.day!)
    }
}
