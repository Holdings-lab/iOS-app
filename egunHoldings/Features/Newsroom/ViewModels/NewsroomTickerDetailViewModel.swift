import Combine
import Foundation

/// 상세는 목록과 별개 네트워크 요청이다(서버가 aiJudgement/summary/sources를 상세에서만 준다).
/// `holding`은 목록에서 이미 받은 값이라 로딩 중에도 헤더(티커/이름/등락률)를 바로 보여줄 수 있다.
@MainActor
final class NewsroomTickerDetailViewModel: ObservableObject {
    let holding: NewsroomHoldingBriefing

    @Published private(set) var detail: NewsroomTickerDetail?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var quote: NewsroomMarketQuote?
    @Published private(set) var earlySources: [NewsroomSourceItem] = []

    var imageCandidates: [URL] {
        detail?.imageCandidates ?? [earlySources.first?.thumbnailURL].compactMap { $0 }
    }

    var articleURL: URL? { detail?.primaryArticleURL ?? earlySources.first?.url }

    private let repository: NewsroomDigestRepositoryProtocol
    private let judgementStore: NewsroomAIJudgementStoring

    init(
        holding: NewsroomHoldingBriefing,
        repository: NewsroomDigestRepositoryProtocol,
        judgementStore: NewsroomAIJudgementStoring? = nil
    ) {
        self.holding = holding
        self.repository = repository
        self.judgementStore = judgementStore ?? NewsroomAIJudgementStore.shared
    }

    func loadIfNeeded() {
        guard detail == nil, !isLoading else { return }
        load()
    }

    func load() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        Task { [weak self] in
            guard let self else { return }
            quote = await repository.fetchQuote(ticker: holding.ticker)
        }
        Task { [weak self] in
            guard let self else { return }
            earlySources = (try? await repository.fetchSources(ticker: holding.ticker)) ?? []
        }

        Task { [weak self] in
            guard let self else { return }
            do {
                let fetched = try await repository.fetchDetail(ticker: holding.ticker, briefingDate: nil)
                detail = fetched
                // 브리핑만 캐시와 대조해 갈아끼운다 — 뉴스 요약/출처는 매일 새로 오는 값이라 그대로 쓴다.
                let judgement = await judgementStore.resolve(
                    incoming: fetched.aiJudgement,
                    for: holding.ticker
                )
                detail = fetched.replacingAIJudgement(judgement)
            } catch {
                errorMessage = "상세 정보를 불러오지 못했어요. 잠시 후 다시 시도해주세요."
            }
            isLoading = false
        }
    }
}
