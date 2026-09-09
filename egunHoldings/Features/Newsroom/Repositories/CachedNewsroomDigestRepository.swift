import Foundation

/// RootTabView가 로그인 세션마다 소유한다. 오늘/뉴스룸이 같은 요청을 기다리며,
/// 성공한 최신 목록만 잠깐 재사용한다. 디스크나 전역 사용자 캐시는 만들지 않는다.
actor CachedNewsroomDigestRepository: NewsroomDigestRepositoryProtocol {
    private let repository: NewsroomDigestRepositoryProtocol
    private let lifetime: TimeInterval
    private let now: @Sendable () -> Date
    private var cached: (briefing: NewsroomBriefing, expiresAt: Date)?
    private var inFlight: (id: UUID, task: Task<NewsroomBriefing, Error>)?

    init(
        repository: NewsroomDigestRepositoryProtocol,
        lifetime: TimeInterval = 60,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.repository = repository
        self.lifetime = lifetime
        self.now = now
    }

    func fetchBriefing(briefingDate: String?) async throws -> NewsroomBriefing {
        // 과거 날짜 조회는 현재 목록 캐시와 섞지 않는다.
        guard briefingDate == nil else {
            return try await repository.fetchBriefing(briefingDate: briefingDate)
        }
        if let inFlight { return try await inFlight.task.value }
        if let cached, now() < cached.expiresAt { return cached.briefing }

        let id = UUID()
        let task = Task { try await repository.fetchBriefing(briefingDate: nil) }
        inFlight = (id, task)
        do {
            let briefing = try await task.value
            if inFlight?.id == id {
                cached = (briefing, now().addingTimeInterval(lifetime))
                inFlight = nil
            }
            return briefing
        } catch {
            if inFlight?.id == id { inFlight = nil }
            throw error
        }
    }

    func refreshBriefing() async throws -> NewsroomBriefing {
        cached = nil
        return try await fetchBriefing(briefingDate: nil)
    }

    func invalidateBriefing() async {
        cached = nil
        // 자산 변경 이전 응답은 기존 호출자에게만 반환하고 캐시에 다시 넣지 않는다.
        inFlight = nil
    }

    func fetchDetail(ticker: String, briefingDate: String?) async throws -> NewsroomTickerDetail {
        try await repository.fetchDetail(ticker: ticker, briefingDate: briefingDate)
    }
}
