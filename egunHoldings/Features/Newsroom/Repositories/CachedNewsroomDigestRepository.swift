import Foundation

/// RootTabView가 로그인 세션마다 소유한다. 오늘/뉴스룸이 같은 요청을 기다리며,
/// 성공한 최신 목록만 잠깐 재사용한다. 디스크나 전역 사용자 캐시는 만들지 않는다.
actor CachedNewsroomDigestRepository: NewsroomDigestRepositoryProtocol {
    /// 상세 캐시에 담아 두는 종목 수 한도.
    private static let detailCapacity = 60

    private let repository: NewsroomDigestRepositoryProtocol
    private let lifetime: TimeInterval
    private let now: @Sendable () -> Date
    private var cached: (briefing: NewsroomBriefing, expiresAt: Date)?
    private var inFlight: (id: UUID, task: Task<NewsroomBriefing, Error>)?
    private var subscribers: [UUID: AsyncStream<NewsroomBriefing>.Continuation] = [:]
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
        if let inFlight { return try await AsyncTaskWait.value(of: inFlight.task) }

        return try await startBriefingFetch()
    }

    /// 이미 새 목록을 조회 중이면 같은 결과를 기다린다. 탭 전환/동시 새로고침으로
    /// 진행 중인 요청을 끊거나 같은 서버 계산을 중복 실행하지 않는다.
    func refreshBriefing() async throws -> NewsroomBriefing {
        if let inFlight { return try await AsyncTaskWait.value(of: inFlight.task) }
        invalidateDetails()
        cached = nil
        return try await startBriefingFetch()
    }

    /// 잔고 동기화 같은 다른 탭의 사건으로 캐시만 버리는 경로다(LiveTodayRepository.invalidateNews).
    /// 진행 중인 최신 조회는 두 탭이 계속 공유한다.
    func invalidateBriefing() async {
        invalidateDetails()
        cached = nil
    }

    func briefingUpdates() -> AsyncStream<NewsroomBriefing> {
        let id = UUID()
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            subscribers[id] = continuation
            if let cached, now() < cached.expiresAt { continuation.yield(cached.briefing) }
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeSubscriber(id) }
            }
        }
    }

    private func removeSubscriber(_ id: UUID) { subscribers[id] = nil }

    private func startBriefingFetch() async throws -> NewsroomBriefing {
        let id = UUID()
        let task = Task {
            do {
                let briefing = try await repository.fetchBriefing(briefingDate: nil)
                // 서버가 result에 담아 준 장애 안내는 성공 데이터가 아니다. 캐시하면
                // "다시 시도"가 60초 동안 같은 안내만 다시 보여주게 된다.
                if briefing.errorState == nil {
                    cached = (briefing, now().addingTimeInterval(lifetime))
                    for subscriber in subscribers.values { subscriber.yield(briefing) }
                }
                if inFlight?.id == id { inFlight = nil }
                return briefing
            } catch {
                if inFlight?.id == id { inFlight = nil }
                throw error
            }
        }
        inFlight = (id, task)
        return try await AsyncTaskWait.value(of: task)
    }

    func fetchDetail(ticker: String, briefingDate: String?) async throws -> NewsroomTickerDetail {
        let key = DetailKey(ticker: ticker.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(), date: briefingDate)
        if let cached = details[key], cached.expires > now() { return cached.detail }
        if let request = detailRequests[key] { return try await AsyncTaskWait.value(of: request.task) }
        let id = UUID()
        let task = Task { try await repository.fetchDetail(ticker: key.ticker, briefingDate: key.date) }
        detailRequests[key] = (id, task)
        do {
            let detail = try await task.value
            if detailRequests[key]?.id == id {
                details = details.filter { $0.value.expires > now() }
                // 목록 진입이 보유 종목 전체를 미리 받으므로, 한 화면치 목록은 다 담을 만큼 잡는다.
                if details.count >= Self.detailCapacity,
                   let oldest = details.min(by: { $0.value.expires < $1.value.expires }) {
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

    func fetchSources(ticker: String) async throws -> [NewsroomSourceItem] {
        try await repository.fetchSources(ticker: ticker)
    }

    /// 상세도 같은 이유로 취소하지 않는다. 상세는 목록과 달리 다른 화면(상세 뷰)이 직접
    /// 기다리고 있어서, 목록 새로고침이든 잔고 갱신이든 여기서 취소해 버리면 마침 상세를 연
    /// 사용자만 "상세 정보를 불러오지 못했어요"를 보게 된다.
    private func invalidateDetails() {
        details.removeAll()
        detailRequests.removeAll()
    }
}
