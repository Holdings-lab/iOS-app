import Foundation
import Combine

@MainActor
final class NewsroomDigestViewModel: ObservableObject {
    @Published private(set) var briefing: NewsroomBriefing?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    /// pull-to-refresh 결과 토스트. "이미 최신이에요" 등, 1.5초 뒤 자동으로 사라진다.
    @Published private(set) var refreshStatusMessage: String?

    private var repository: NewsroomDigestRepositoryProtocol
    private var quoteTask: Task<Void, Never>?
    private var prefetchTask: Task<Void, Never>?

    init(userId: Int64? = nil, repository: NewsroomDigestRepositoryProtocol? = nil) {
        self.repository = repository ?? NewsroomDigestRepositoryFactory.makeDefault(userId: userId)
    }

    func load() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        Task { [weak self] in
            guard let self else { return }

            do {
                briefing = try await repository.fetchBriefing(briefingDate: nil)
                loadSupplementaryContent()
            } catch {
                if briefing == nil {
                    errorMessage = "뉴스룸을 불러오지 못했어요. 잠시 후 다시 시도해주세요."
                }
            }
            isLoading = false
        }
    }

    func loadIfNeeded() {
        // 탭 재진입 때 공유 캐시의 최신 결과/만료 여부를 확인한다.
        // 기존 내용은 유지하므로 이미 본 화면을 다시 스켈레톤으로 바꾸지 않는다.
        guard !isLoading else { return }
        load()
    }

    @discardableResult
    func refresh() async -> Bool {
        guard !isLoading else { return false }
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await repository.refreshBriefing()
            // 별도 시세를 보존해 새로고침 때 숫자가 사라지지 않도록 한다.
            let previous = briefing
            let merged = fetched.replacingHoldings(fetched.holdings.map { holding in
                guard let old = previous?.holdings.first(where: { $0.ticker == holding.ticker }),
                      let asOf = old.quoteAsOf, let change = old.dailyChangePercent else { return holding }
                return holding.replacingQuote(NewsroomMarketQuote(changePercent: change, asOf: asOf))
            })
            let unchanged = merged == previous
            briefing = merged
            errorMessage = nil
            loadSupplementaryContent()
            if unchanged {
                await showRefreshStatus("이미 최신이에요")
                return false
            } else {
                return true
            }
        } catch {
            await showRefreshStatus("새로고침에 실패했어요")
            return false
        }
    }

    /// 상세 화면은 이제 별도 네트워크 요청이라 자체 뷰모델을 새로 만들어 넘긴다.
    func makeDetailViewModel(for holding: NewsroomHoldingBriefing) -> NewsroomTickerDetailViewModel {
        NewsroomTickerDetailViewModel(holding: holding, repository: repository)
    }

    private func loadSupplementaryContent() {
        quoteTask?.cancel()
        prefetchTask?.cancel()
        guard let briefing, briefing.errorState == nil, briefing.emptyState == nil else { return }
        let holdings = briefing.sortedHoldings.filter { $0.briefingType != .quiet }
        let repository = repository
        quoteTask = Task { [weak self] in
            // 작은 묶음으로 요청해 종목이 많아도 시세 서버에 요청을 한꺼번에 쏟지 않는다.
            for start in stride(from: 0, to: holdings.count, by: 3) {
                guard !Task.isCancelled else { return }
                await withTaskGroup(of: (String, NewsroomMarketQuote?).self) { group in
                    for holding in holdings[start..<min(start + 3, holdings.count)] {
                        group.addTask { (holding.ticker, await repository.fetchQuote(ticker: holding.ticker)) }
                    }
                    for await (ticker, quote) in group {
                        guard !Task.isCancelled, let quote, let current = self?.briefing else { continue }
                        self?.briefing = current.replacingHoldings(current.holdings.map {
                            $0.ticker == ticker ? $0.replacingQuote(quote) : $0
                        })
                    }
                }
            }
        }
        prefetchTask = Task {
            await withTaskGroup(of: Void.self) { group in
                for holding in holdings.prefix(2) {
                    group.addTask {
                        guard !Task.isCancelled,
                              let sources = try? await repository.fetchSources(ticker: holding.ticker),
                              !Task.isCancelled else { return }
                        await NewsroomImageLoader.shared.preload(
                            urls: [sources.first?.thumbnailURL].compactMap { $0 }
                        )
                    }
                    group.addTask {
                        guard !Task.isCancelled,
                              let detail = try? await repository.fetchDetail(ticker: holding.ticker, briefingDate: nil),
                              !Task.isCancelled else { return }
                        await NewsroomImageLoader.shared.preload(urls: detail.imageCandidates)
                    }
                }
            }
        }
    }

    private func showRefreshStatus(_ message: String) async {
        refreshStatusMessage = message
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        if refreshStatusMessage == message {
            refreshStatusMessage = nil
        }
    }

    #if DEBUG
    /// UI/UX 검증용 — Mock 시나리오를 바꿔가며 화면 상태를 확인한다.
    func applyScenario(_ scenario: NewsroomDigestScenario) {
        repository = MockNewsroomDigestRepository(scenario: scenario)
        briefing = nil
        load()
    }
    #endif
}
