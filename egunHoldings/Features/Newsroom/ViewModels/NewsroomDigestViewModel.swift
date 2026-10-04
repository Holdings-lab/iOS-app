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
    private var requestTask: Task<NewsroomBriefing, Error>?
    private var loadTask: Task<Void, Never>?
    private var statusTask: Task<Void, Never>?
    private var generation = 0
    private let refreshTimeout: Duration

    /// 상세 선행 조회를 동시에 보낼 종목 수.
    private static let prefetchBatchSize = 3

    init(
        userId: Int64? = nil,
        repository: NewsroomDigestRepositoryProtocol? = nil,
        refreshTimeout: Duration = .seconds(8)
    ) {
        self.repository = repository ?? NewsroomDigestRepositoryFactory.makeDefault(userId: userId)
        self.refreshTimeout = refreshTimeout
    }

    func load() {
        guard !isLoading else { return }
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard !Task.isCancelled else { return }
            _ = await self?.fetch(refresh: false)
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
        await fetch(refresh: true)
    }

    func cancelLoading() {
        generation += 1
        loadTask?.cancel()
        requestTask?.cancel()
        requestTask = nil
        prefetchTask?.cancel()
        statusTask?.cancel()
        refreshStatusMessage = nil
        isLoading = false
    }

    func observeBriefings() async {
        let updates = await repository.briefingUpdates()
        for await fetched in updates {
            guard !Task.isCancelled else { return }
            apply(fetched)
            errorMessage = nil
        }
    }

    private func fetch(refresh: Bool) async -> Bool {
        guard !isLoading, !Task.isCancelled else { return false }
        generation += 1
        let currentGeneration = generation
        isLoading = true
        errorMessage = nil
        let previousBriefing = briefing
        prefetchTask?.cancel()
        let repository = repository
        let task = Task {
            if refresh { return try await repository.refreshBriefing() }
            return try await repository.fetchBriefing(briefingDate: nil)
        }
        requestTask = task
        defer {
            if generation == currentGeneration {
                isLoading = false
                requestTask = nil
            }
        }
        do {
            let fetched = try await AsyncTaskWait.value(
                of: task, timeout: refreshTimeout, cancelsTaskOnInterruption: true
            )
            guard generation == currentGeneration else { return false }
            let unchanged = fetched == previousBriefing
            apply(fetched)
            errorMessage = nil
            if refresh && unchanged {
                showRefreshStatus("이미 최신이에요")
                return false
            } else {
                return true
            }
        } catch is CancellationError {
            return false
        } catch {
            guard generation == currentGeneration else { return false }
            if briefing == nil {
                errorMessage = "뉴스룸을 불러오지 못했어요. 잠시 후 다시 시도해주세요."
            } else if refresh {
                showRefreshStatus("응답이 지연돼 이전 내용을 유지했어요")
            }
            return false
        }
    }

    private func apply(_ fetched: NewsroomBriefing) {
        guard fetched != briefing else { return }
        briefing = fetched
        loadSupplementaryContent()
    }

    /// 상세 화면은 이제 별도 네트워크 요청이라 자체 뷰모델을 새로 만들어 넘긴다.
    func makeDetailViewModel(for holding: NewsroomHoldingBriefing) -> NewsroomTickerDetailViewModel {
        NewsroomTickerDetailViewModel(holding: holding, repository: repository)
    }

    /// 목록에 들어오면 상세로 열 수 있는 종목의 자료를 미리 받아둔다 — 카드를 누르면
    /// 캐시(CachedNewsroomDigestRepository)에서 바로 연다. Quiet 행은 정적 안내라 제외한다.
    private func loadSupplementaryContent() {
        prefetchTask?.cancel()
        guard let briefing, briefing.errorState == nil, briefing.emptyState == nil else { return }
        let tickers = briefing.sortedHoldings
            .filter { $0.briefingType != .quiet }
            .map(\.ticker)
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

    private func showRefreshStatus(_ message: String) {
        statusTask?.cancel()
        refreshStatusMessage = message
        statusTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(1_500))
            guard !Task.isCancelled else { return }
            self?.refreshStatusMessage = nil
        }
    }

    #if DEBUG
    /// UI/UX 검증용 — Mock 시나리오를 바꿔가며 화면 상태를 확인한다.
    func applyScenario(_ scenario: NewsroomDigestScenario) {
        cancelLoading()
        repository = MockNewsroomDigestRepository(scenario: scenario)
        briefing = nil
        load()
    }
    #endif
}
