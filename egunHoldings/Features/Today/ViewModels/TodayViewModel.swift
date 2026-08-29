import Combine
import SwiftUI

@MainActor
final class TodayViewModel: ObservableObject {
    @Published private(set) var loadState: TodayLoadState = .idle
    @Published private(set) var userAssetProfile: UserAssetProfile
    @Published private(set) var portfolioSnapshot: PortfolioSnapshot
    @Published private(set) var isAccountLinked: Bool
    @Published private(set) var briefing: TodayBriefing
    @Published private(set) var holdings: [TodayHolding]
    @Published private(set) var goalProgress: TodayGoalProgress?
    @Published private(set) var newsItems: [TodayNewsItem]

    private let userId: Int64?
    private let repository: TodayRepositoryProtocol
    private var brokerBalanceSnapshot: BrokerBalanceSnapshot?
    private var didLoad = false
    private var refreshGeneration = 0

    init(
        userId: Int64? = nil,
        userAssetProfile: UserAssetProfile,
        portfolioSnapshot: PortfolioSnapshot,
        holdings: [TodayHolding] = TodayMockData.holdings,
        brokerBalanceSnapshot: BrokerBalanceSnapshot? = nil,
        repository: TodayRepositoryProtocol? = nil
    ) {
        let dashboard = MockTodayRepository.makeDashboard(
            userId: userId,
            userAssetProfile: userAssetProfile,
            portfolioSnapshot: portfolioSnapshot,
            holdings: holdings
        )

        self.userId = userId
        self.repository = repository ?? TodayRepositoryFactory.makeDefault()
        self.brokerBalanceSnapshot = brokerBalanceSnapshot
        self.userAssetProfile = dashboard.userAssetProfile
        self.portfolioSnapshot = dashboard.portfolioSnapshot
        self.isAccountLinked = dashboard.isAccountLinked
        self.briefing = dashboard.briefing
        self.holdings = brokerBalanceSnapshot?.todayHoldings ?? dashboard.holdings
        self.goalProgress = dashboard.goalProgress
        self.newsItems = dashboard.newsItems
    }

    /// Preview/test-only constructor that bypasses the mock-first init and injects a full dashboard directly.
    init(userId: Int64?, dashboard: TodayDashboard, loadState: TodayLoadState = .loaded, repository: TodayRepositoryProtocol? = nil) {
        self.userId = userId
        self.repository = repository ?? TodayRepositoryFactory.makeDefault()
        self.brokerBalanceSnapshot = nil
        self.userAssetProfile = dashboard.userAssetProfile
        self.portfolioSnapshot = dashboard.portfolioSnapshot
        self.isAccountLinked = dashboard.isAccountLinked
        self.briefing = dashboard.briefing
        self.holdings = dashboard.holdings
        self.goalProgress = dashboard.goalProgress
        self.newsItems = dashboard.newsItems
        self.loadState = loadState
        self.didLoad = true
    }

    var connectedBrokerStatusText: String {
        isAccountLinked ? "한국투자증권 읽기 전용" : "연결 전"
    }

    var topHoldings: [TodayHolding] {
        let positions = holdings.filter { $0.ticker != "ETC" }
        let topThree = Array(positions.sorted { $0.weight > $1.weight }.prefix(3))
        let remainder = max(0, 100 - topThree.reduce(0) { $0 + $1.weight })

        guard remainder > 0 else { return topThree }
        return topThree + [
            TodayHolding(
                id: "__rest",
                name: "그 외 보유종목",
                ticker: "ETC",
                category: "ETC",
                weight: remainder
            )
        ]
    }

    func load() async {
        guard !didLoad else { return }
        didLoad = true
        await refresh()
    }

    /// 잔고 조회 응답 등으로 상위(AppRouter) 세션 데이터가 갱신됐을 때 호출한다.
    /// 예전에는 상위에서 `.id(portfolioSnapshot)`으로 화면을 통째로 재생성했는데,
    /// 그러면 뷰모델·네비게이션 경로·스크롤 위치가 전부 초기화되고 로딩 스켈레톤이 다시 노출됐다.
    /// 여기서는 로컬 파생 데이터만 즉시 갱신하고, 서버 재조회는 스켈레톤 없이 조용히 수행한다.
    func updateSessionData(
        userAssetProfile: UserAssetProfile,
        portfolioSnapshot: PortfolioSnapshot,
        brokerBalanceSnapshot: BrokerBalanceSnapshot?
    ) {
        guard userAssetProfile != self.userAssetProfile
                || portfolioSnapshot != self.portfolioSnapshot
                || brokerBalanceSnapshot != self.brokerBalanceSnapshot
        else {
            return
        }

        self.brokerBalanceSnapshot = brokerBalanceSnapshot

        apply(
            MockTodayRepository.makeDashboard(
                userId: userId,
                userAssetProfile: userAssetProfile,
                portfolioSnapshot: portfolioSnapshot,
                holdings: brokerBalanceSnapshot?.todayHoldings ?? holdings
            )
        )

        guard didLoad else { return }
        Task { await refresh(showsLoading: false) }
    }

    func refresh() async {
        await refresh(showsLoading: true)
    }

    private func refresh(showsLoading: Bool) async {
        guard userId != nil else {
            loadState = .usingFallback(message: nil)
            return
        }

        // 이 refresh가 서버 응답을 기다리는 동안 더 최신 refresh(예: 잔고 갱신으로 인한
        // updateSessionData 트리거)가 시작되면, 그 최신 refresh만 결과를 반영하게 한다.
        // 그렇지 않으면 늦게 도착한 이전 응답이 이미 반영된 최신 데이터를 덮어쓸 수 있다.
        refreshGeneration += 1
        let generation = refreshGeneration

        if showsLoading {
            loadState = .loading
        }

        do {
            let dashboard = try await repository.fetchDashboard(
                userId: userId,
                userAssetProfile: userAssetProfile,
                portfolioSnapshot: portfolioSnapshot
            )
            guard generation == refreshGeneration else { return }
            apply(dashboard)
            loadState = .loaded
        } catch {
            guard generation == refreshGeneration else { return }
            loadState = .usingFallback(message: Self.errorMessage(for: error))
        }
    }

    private func apply(_ dashboard: TodayDashboard) {
        userAssetProfile = dashboard.userAssetProfile
        portfolioSnapshot = dashboard.portfolioSnapshot
        isAccountLinked = dashboard.isAccountLinked
        briefing = dashboard.briefing
        holdings = brokerBalanceSnapshot?.todayHoldings ?? dashboard.holdings
        goalProgress = dashboard.goalProgress
        newsItems = dashboard.newsItems
    }

    private static func errorMessage(for error: Error) -> String {
        AppVocabulary.ErrorMessage.userFacing(for: error)
    }
}

private extension BrokerBalanceSnapshot {
    /// 수량이 아닌 각 포지션의 평가금액 합계를 분모로 사용한다.
    var todayHoldings: [TodayHolding] {
        let positions = holdings.filter { $0.evaluationAmount > 0 }
        let totalAmount = positions.reduce(0) { $0 + $1.evaluationAmount }
        guard totalAmount > 0 else { return [] }

        return positions.map { holding in
            TodayHolding(
                id: holding.symbol,
                name: holding.name,
                ticker: holding.symbol,
                category: holding.symbol,
                weight: Int((Double(holding.evaluationAmount) / Double(totalAmount) * 100).rounded())
            )
        }
    }
}
