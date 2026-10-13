import Foundation

/// 뉴스룸 목록/상세를 각각 별도로 가져온다 — 서버가 두 엔드포인트로 나눠 응답하므로
/// (목록에는 aiJudgement/summary/sources가 없다) 예전처럼 한 번에 다 담아오지 않는다.
nonisolated protocol NewsroomDigestRepositoryProtocol: Sendable {
    func fetchBriefing(briefingDate: String?) async throws -> NewsroomBriefing
    func refreshBriefing() async throws -> NewsroomBriefing
    func invalidateBriefing() async
    func briefingUpdates() async -> AsyncStream<NewsroomBriefing>
    func fetchDetail(ticker: String, briefingDate: String?) async throws -> NewsroomTickerDetail
    func fetchSources(ticker: String) async throws -> [NewsroomSourceItem]
}

extension NewsroomDigestRepositoryProtocol {
    func refreshBriefing() async throws -> NewsroomBriefing {
        try await fetchBriefing(briefingDate: nil)
    }

    func invalidateBriefing() async {}
    func briefingUpdates() async -> AsyncStream<NewsroomBriefing> {
        AsyncStream { $0.finish() }
    }
    func fetchSources(ticker: String) async throws -> [NewsroomSourceItem] { [] }
}
