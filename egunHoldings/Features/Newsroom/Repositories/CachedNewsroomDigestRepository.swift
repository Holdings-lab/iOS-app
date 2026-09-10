import Foundation

/// RootTabView가 로그인 세션마다 소유한다. 오늘/뉴스룸이 같은 요청을 기다리며,
/// 성공한 최신 목록만 잠깐 재사용한다. 디스크나 전역 사용자 캐시는 만들지 않는다.
actor CachedNewsroomDigestRepository: NewsroomDigestRepositoryProtocol {
    private let repository: NewsroomDigestRepositoryProtocol
    private let lifetime: TimeInterval
    private let now: @Sendable () -> Date
    private var cached: (briefing: NewsroomBriefing, expiresAt: Date)?
    private var inFlight: (id: UUID, task: Task<NewsroomBriefing, Error>)?
    private struct DetailKey: Hashable { let ticker: String; let date: String? }
    private var details: [DetailKey: (detail: NewsroomTickerDetail, expires: Date)] = [:]
    private var detailRequests: [DetailKey: (id: UUID, task: Task<NewsroomTickerDetail, Error>)] = [:]

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
        if let cached, now() < cached.expiresAt { return cached.briefing }
        if let inFlight { return try await inFlight.task.value }

        return try await startBriefingFetch()
    }

    func refreshBriefing() async throws -> NewsroomBriefing {
        invalidateDetails()
        cached = nil
        cancelInFlightBriefing()
        return try await startBriefingFetch()
    }

    func invalidateBriefing() async {
        invalidateDetails()
        cached = nil
        cancelInFlightBriefing()
    }

    private func startBriefingFetch() async throws -> NewsroomBriefing {
        let id = UUID()
        let task = Task { try await repository.fetchBriefing(briefingDate: nil) }
        inFlight = (id, task)
        do {
            let briefing = try await task.value
            if inFlight?.id == id {
                // 서버가 result에 담아 준 장애 안내는 성공 데이터가 아니다. 캐시하면
                // "다시 시도"가 60초 동안 같은 안내만 다시 보여주게 된다.
                if briefing.errorState == nil {
                    cached = (briefing, now().addingTimeInterval(lifetime))
                }
                inFlight = nil
            }
            return briefing
        } catch {
            if inFlight?.id == id { inFlight = nil }
            throw error
        }
    }

    private func cancelInFlightBriefing() {
        // 새로고침/자산 변경 전의 응답은 새 캐시에 들어갈 수 없고, 서버 부하도 남길 이유가 없다.
        inFlight?.task.cancel()
        inFlight = nil
    }

    func fetchDetail(ticker: String, briefingDate: String?) async throws -> NewsroomTickerDetail {
        let key = DetailKey(ticker: ticker.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(), date: briefingDate)
        if let cached = details[key], cached.expires > now() { return cached.detail }
        if let request = detailRequests[key] { return try await request.task.value }
        let id = UUID()
        let task = Task { try await repository.fetchDetail(ticker: key.ticker, briefingDate: key.date) }
        detailRequests[key] = (id, task)
        do {
            let detail = try await task.value
            if detailRequests[key]?.id == id {
                details = details.filter { $0.value.expires > now() }
                if details.count >= 20, let oldest = details.min(by: { $0.value.expires < $1.value.expires }) {
                    details[oldest.key] = nil
                }
                details[key] = (detail, now().addingTimeInterval(300))
                detailRequests[key] = nil
            }
            return detail
        } catch {
            if detailRequests[key]?.id == id { detailRequests[key] = nil }
            throw error
        }
    }

    func fetchQuote(ticker: String) async -> NewsroomMarketQuote? {
        await repository.fetchQuote(ticker: ticker)
    }

    func fetchSources(ticker: String) async throws -> [NewsroomSourceItem] {
        try await repository.fetchSources(ticker: ticker)
    }

    private func invalidateDetails() {
        details.removeAll()
        detailRequests.values.forEach { $0.task.cancel() }
        detailRequests.removeAll()
    }
}
