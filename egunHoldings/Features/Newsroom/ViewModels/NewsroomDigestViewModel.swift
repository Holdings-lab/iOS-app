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
    private var prefetchTask: Task<Void, Never>?

    /// 상세 선행 조회를 동시에 보낼 종목 수.
    private static let prefetchBatchSize = 3

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
            // 등락률도 브리핑 응답에 함께 오므로 따로 보존할 상태가 없다.
            let fetched = try await repository.refreshBriefing()
            let unchanged = fetched == briefing
            briefing = fetched
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

    /// 목록에 들어오면 보이는 모든 종목의 상세를 미리 받아둔다 — 어느 카드를 눌러도
    /// 상세가 새 요청 없이 캐시(CachedNewsroomDigestRepository)에서 바로 열린다.
    /// Quiet 종목도 카드를 누르면 같은 상세 화면을 열기 때문에 함께 받는다.
    private func loadSupplementaryContent() {
        prefetchTask?.cancel()
        guard let briefing, briefing.errorState == nil, briefing.emptyState == nil else { return }
        let tickers = briefing.sortedHoldings.map(\.ticker)
        let repository = repository
        prefetchTask = Task {
            // 화면 순서대로 작은 묶음씩 받아, 종목이 많아도 서버에 요청을 한꺼번에 쏟지 않는다.
            for start in stride(from: 0, to: tickers.count, by: Self.prefetchBatchSize) {
                guard !Task.isCancelled else { return }
                let batch = tickers[start..<min(start + Self.prefetchBatchSize, tickers.count)]
                await withTaskGroup(of: Void.self) { group in
                    for ticker in batch {
                        // 출처 피드는 종목과 무관한 한 번의 조회를 모두가 공유한다(NewsroomSourceFeedRepository).
                        group.addTask {
                            guard !Task.isCancelled,
                                  let sources = try? await repository.fetchSources(ticker: ticker),
                                  !Task.isCancelled else { return }
                            await NewsroomImageLoader.shared.preload(
                                urls: [sources.first?.thumbnailURL].compactMap { $0 }
                            )
                        }
                        group.addTask {
                            guard !Task.isCancelled,
                                  let detail = try? await repository.fetchDetail(ticker: ticker, briefingDate: nil),
                                  !Task.isCancelled else { return }
                            await NewsroomImageLoader.shared.preload(urls: detail.imageCandidates)
                        }
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
