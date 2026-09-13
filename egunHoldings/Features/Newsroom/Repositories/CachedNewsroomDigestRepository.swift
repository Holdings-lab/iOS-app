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

    /// 사용자가 직접 당겨서 새로고침한 경우다. 목록을 기다리던 화면이 곧 이 함수의
    /// 새 결과를 받으므로, 이전 요청은 취소해 서버 부하를 남기지 않는다.
    func refreshBriefing() async throws -> NewsroomBriefing {
        invalidateDetails()
        cached = nil
        cancelInFlightBriefing()
        return try await startBriefingFetch()
    }

    /// 잔고 동기화 같은 다른 탭의 사건으로 캐시만 버리는 경로다(LiveTodayRepository.invalidateNews).
    /// 여기서 취소하면 마침 뉴스룸을 보고 있던 사용자의 화면이 대신 실패하므로 떼어내기만 한다.
    func invalidateBriefing() async {
        invalidateDetails()
        cached = nil
        detachInFlightBriefing()
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
        inFlight?.task.cancel()
        inFlight = nil
    }

    /// 진행 중인 요청을 캐시에서 떼어낼 뿐, 취소하지는 않는다.
    /// 공유 Task라서 취소하면 그 응답을 기다리던 화면까지 같이 실패한다 —
    /// 결과가 새 캐시에 들어가지 않는 건 `startBriefingFetch`의 세대(id) 비교가 이미 보장한다.
    private func detachInFlightBriefing() {
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
