import Foundation
import Testing
@testable import egunHoldings

@MainActor
struct DashboardLoadingTests {
    @Test("오늘과 뉴스룸의 동시/연속 조회는 한 요청을 공유한다")
    func sharesBriefingRequest() async throws {
        let source = CountingNewsroomRepository()
        let cache = CachedNewsroomDigestRepository(repository: source)
        async let today = cache.fetchBriefing(briefingDate: nil)
        async let newsroom = cache.fetchBriefing(briefingDate: nil)
        let (first, second) = try await (today, newsroom)
        #expect(first == second)
        _ = try await cache.fetchBriefing(briefingDate: nil)
        #expect(await source.count == 1)
        _ = try await cache.refreshBriefing()
        #expect(await source.count == 2)
    }

    @Test("만료되거나 자산 변경으로 무효화된 목록은 다시 조회한다")
    func refreshesExpiredAndInvalidatedCache() async throws {
        let source = CountingNewsroomRepository()
        let expiredCache = CachedNewsroomDigestRepository(repository: source, lifetime: 0)
        _ = try await expiredCache.fetchBriefing(briefingDate: nil)
        _ = try await expiredCache.fetchBriefing(briefingDate: nil)
        #expect(await source.count == 2)
        let cache = CachedNewsroomDigestRepository(repository: source)
        _ = try await cache.fetchBriefing(briefingDate: nil)
        await cache.invalidateBriefing()
        _ = try await cache.fetchBriefing(briefingDate: nil)
        #expect(await source.count == 4)
    }

    @Test("강제 새로고침은 이전 뉴스룸 요청을 취소하고 새 요청을 사용한다")
    func refreshCancelsInFlightBriefing() async throws {
        let source = BlockingNewsroomRepository()
        let cache = CachedNewsroomDigestRepository(repository: source)
        let original = Task { try await cache.fetchBriefing(briefingDate: nil) }
        await source.waitUntilFirstRequestStarts()

        let refreshed = try await cache.refreshBriefing()

        do {
            _ = try await original.value
            Issue.record("이전 요청은 취소되어야 한다")
        } catch is CancellationError {}
        #expect(refreshed.title == "두 번째 요청")
        #expect(await source.firstRequestWasCancelled)
        #expect(await source.count == 2)
    }

    @Test("실패 응답은 캐시하지 않고 다음 호출에서 재시도한다")
    func retriesFailedRequest() async throws {
        let source = CountingNewsroomRepository(failFirst: true)
        let cache = CachedNewsroomDigestRepository(repository: source)
        do {
            _ = try await cache.fetchBriefing(briefingDate: nil)
            Issue.record("첫 요청은 실패해야 한다")
        } catch {}
        _ = try await cache.fetchBriefing(briefingDate: nil)
        #expect(await source.count == 2)
    }

    @Test("서버 장애 안내는 캐시하지 않아 다시 시도가 새 요청을 만든다")
    func doesNotCacheServerErrorState() async throws {
        let source = CountingNewsroomRepository(errorStateFirst: true)
        let cache = CachedNewsroomDigestRepository(repository: source)

        #expect(try await cache.fetchBriefing(briefingDate: nil).errorState != nil)
        #expect(try await cache.fetchBriefing(briefingDate: nil).errorState == nil)
        #expect(await source.count == 2)
    }

    @Test("새 로그인 세션과 과거 날짜 조회는 현재 목록 캐시와 분리된다")
    func isolatesSessionsAndDates() async throws {
        let source = CountingNewsroomRepository()
        let firstSession = CachedNewsroomDigestRepository(repository: source)
        let secondSession = CachedNewsroomDigestRepository(repository: source)
        _ = try await firstSession.fetchBriefing(briefingDate: nil)
        _ = try await secondSession.fetchBriefing(briefingDate: nil)
        _ = try await firstSession.fetchBriefing(briefingDate: "2026-08-29")
        _ = try await firstSession.fetchBriefing(briefingDate: nil)
        #expect(await source.count == 3)
    }

    @Test("뉴스 없음/미연동/오류를 샘플 기사로 대체하지 않는다", arguments: ["Quiet", "empty", "failure"])
    func doesNotInventNews(scenario: String) async throws {
        let client = DashboardAPIClient(newsScenario: scenario)
        let dashboard = try await LiveTodayRepository(apiClient: client).fetchDashboard(
            userId: 1, userAssetProfile: AppMockData.userAssetProfile,
            portfolioSnapshot: AppMockData.portfolioSnapshot
        )
        #expect(dashboard.newsItems.isEmpty)
    }

    @Test("Quiet을 제외하고 실제 기사만 오늘에 표시한다")
    func filtersQuietHoldings() async throws {
        let dashboard = try await LiveTodayRepository(apiClient: DashboardAPIClient()).fetchDashboard(
            userId: 1, userAssetProfile: AppMockData.userAssetProfile,
            portfolioSnapshot: AppMockData.portfolioSnapshot
        )
        #expect(dashboard.newsItems.map(\.ticker) == ["NVDA"])
    }

    @Test("브리핑이 느려도 나머지 세 섹션은 먼저 도착한다")
    func publishesBeforeSlowestRequest() async throws {
        let gate = RequestGate()
        let repository = LiveTodayRepository(apiClient: DashboardAPIClient(slowBriefing: gate))
        var completed: [TodaySection] = []
        let dashboard = try await repository.fetchDashboard(
            userId: 1, userAssetProfile: AppMockData.userAssetProfile,
            portfolioSnapshot: AppMockData.portfolioSnapshot,
            onSection: { update in
                switch update {
                case .briefing: completed.append(.briefing)
                case .holdings: completed.append(.holdings)
                case .goal: completed.append(.goal)
                case .news: completed.append(.news)
                }
                if completed.count == 3 {
                    #expect(!completed.contains(.briefing))
                    Task { await gate.release() }
                }
            }
        )
        #expect(completed.last == .briefing)
        #expect(dashboard.briefing.drawdownFromPeakPercent == -2)
    }

    @Test("뷰모델은 모든 응답이 끝날 때까지 전체 스켈레톤을 유지한다")
    func viewModelPublishesDashboardAtOnce() async {
        let gate = RequestGate()
        let ready = RequestGate()
        let viewModel = TodayViewModel(
            userId: 1, userAssetProfile: AppMockData.userAssetProfile,
            portfolioSnapshot: AppMockData.portfolioSnapshot,
            repository: PartialTodayRepository(gate: gate, ready: ready)
        )
        let loading = Task { await viewModel.load() }
        await ready.wait()
        #expect(viewModel.holdings.first?.ticker != "LIVE")
        #expect(viewModel.loadingSections.contains(.holdings))
        #expect(viewModel.loadingSections.contains(.news))
        #expect(viewModel.newsItems.isEmpty)
        await gate.release()
        await loading.value
        #expect(viewModel.holdings.first?.ticker == "LIVE")
        #expect(viewModel.loadingSections.isEmpty)
    }

    @Test("새 새로고침은 이전 네트워크 작업을 취소하고 최신 결과만 표시한다")
    func cancelsSupersededRefresh() async {
        let started = RequestGate()
        let cancelled = RequestGate()
        let repository = SupersededTodayRepository(started: started, cancelled: cancelled)
        let viewModel = TodayViewModel(
            userId: 1, userAssetProfile: AppMockData.userAssetProfile,
            portfolioSnapshot: AppMockData.portfolioSnapshot, repository: repository
        )
        let initial = Task { await viewModel.load() }
        await started.wait()
        await viewModel.refresh()
        await cancelled.wait()
        await initial.value
        #expect(viewModel.holdings.first?.ticker == "NEW")
        #expect(viewModel.loadState == .loaded)
    }
}

@MainActor
private final class SupersededTodayRepository: TodayRepositoryProtocol {
    private var calls = 0
    let started: RequestGate
    let cancelled: RequestGate
    init(started: RequestGate, cancelled: RequestGate) {
        self.started = started
        self.cancelled = cancelled
    }
    func fetchDashboard(
        userId: Int64?, userAssetProfile: UserAssetProfile, portfolioSnapshot: PortfolioSnapshot,
        onSection: (@MainActor @Sendable (TodaySectionUpdate) -> Void)?
    ) async throws -> TodayDashboard {
        calls += 1
        if calls == 1 {
            await started.release()
            do {
                try await Task.sleep(for: .seconds(30))
                Issue.record("이전 요청이 취소되지 않았다")
            } catch {
                await cancelled.release()
                throw error
            }
        }
        return MockTodayRepository.makeDashboard(
            userAssetProfile: userAssetProfile, portfolioSnapshot: portfolioSnapshot,
            holdings: [TodayHolding(id: "NEW", name: "최신", ticker: "NEW", category: "NEW", weight: 100)],
            newsItems: []
        )
    }
}

private actor CountingNewsroomRepository: NewsroomDigestRepositoryProtocol {
    private(set) var count = 0
    let failFirst: Bool
    let errorStateFirst: Bool
    init(failFirst: Bool = false, errorStateFirst: Bool = false) {
        self.failFirst = failFirst
        self.errorStateFirst = errorStateFirst
    }
    func fetchBriefing(briefingDate: String?) async throws -> NewsroomBriefing {
        count += 1
        if failFirst && count == 1 { throw URLError(.timedOut) }
        return NewsroomBriefing(
            title: "뉴스룸",
            asOfAt: nil,
            subtitle: "",
            holdings: [],
            footerMessage: nil,
            emptyState: nil,
            errorState: errorStateFirst && count == 1
                ? NewsroomErrorState(title: "일시 장애", summary: "다시 시도", buttonLabel: "재시도")
                : nil
        )
    }
    func fetchDetail(ticker: String, briefingDate: String?) async throws -> NewsroomTickerDetail {
        throw URLError(.unsupportedURL)
    }
}

private actor BlockingNewsroomRepository: NewsroomDigestRepositoryProtocol {
    private(set) var count = 0
    private(set) var firstRequestWasCancelled = false
    private var firstRequestStarted: CheckedContinuation<Void, Never>?

    func fetchBriefing(briefingDate: String?) async throws -> NewsroomBriefing {
        count += 1
        if count == 1 {
            firstRequestStarted?.resume()
            firstRequestStarted = nil
            do {
                try await Task.sleep(for: .seconds(30))
            } catch {
                firstRequestWasCancelled = true
                throw error
            }
        }

        return NewsroomBriefing(
            title: count == 1 ? "첫 번째 요청" : "두 번째 요청",
            asOfAt: nil,
            subtitle: "",
            holdings: [],
            footerMessage: nil,
            emptyState: nil,
            errorState: nil
        )
    }

    func fetchDetail(ticker: String, briefingDate: String?) async throws -> NewsroomTickerDetail {
        throw URLError(.unsupportedURL)
    }

    func waitUntilFirstRequestStarts() async {
        guard count == 0 else { return }
        await withCheckedContinuation { firstRequestStarted = $0 }
    }
}

private actor RequestGate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []
    func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { waiters.append($0) }
    }
    func release() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters = []
    }
}

private struct DashboardAPIClient: APIClient {
    var newsScenario = "mixed"
    var slowBriefing: RequestGate?
    nonisolated func request<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        let result: String
        switch endpoint.path {
        case "/api/daily-briefing":
            await slowBriefing?.wait()
            result = #"{"isAccountLinked":true,"drawdownPct":-2}"#
        case "/api/holdings":
            result = #"{"isAccountLinked":true,"holdings":[]}"#
        case "/api/goal-progress":
            result = #"{"isAccountLinked":true}"#
        case "/api/newsroom":
            if newsScenario == "failure" { throw URLError(.timedOut) }
            let holdings = newsScenario == "empty" ? "[]" :
                #"[{"ticker":"QQQ","name":"QQQ","weightPct":50,"briefingType":"Quiet"},{"ticker":"NVDA","name":"NVIDIA","weightPct":50,"briefingType":"\#(newsScenario == "Quiet" ? "Quiet" : "Hero")","headline":"실제 뉴스"}]"#
            result = #"{"header":{"title":"뉴스룸","subtitle":""},"holdings":\#(holdings)}"#
        default: throw URLError(.unsupportedURL)
        }
        return try NetworkJSONCoding.makeDecoder().decode(type, from: Data(
            #"{"isSuccess":true,"code":"SUCCESS-200","message":"OK","result":\#(result)}"#.utf8
        ))
    }
}

private struct PartialTodayRepository: TodayRepositoryProtocol {
    let gate: RequestGate
    let ready: RequestGate
    func fetchDashboard(
        userId: Int64?, userAssetProfile: UserAssetProfile, portfolioSnapshot: PortfolioSnapshot,
        onSection: (@MainActor @Sendable (TodaySectionUpdate) -> Void)?
    ) async throws -> TodayDashboard {
        let holding = TodayHolding(id: "LIVE", name: "서버 종목", ticker: "LIVE", category: "LIVE", weight: 100)
        await onSection?(.holdings(isAccountLinked: true, [holding]))
        await ready.release()
        await gate.wait()
        return MockTodayRepository.makeDashboard(userAssetProfile: userAssetProfile,
                                                 portfolioSnapshot: portfolioSnapshot,
                                                 holdings: [holding], newsItems: [])
    }
}
