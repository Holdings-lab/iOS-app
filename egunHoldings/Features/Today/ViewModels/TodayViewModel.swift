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
    @Published private(set) var loadingSections: Set<TodaySection> = []

    private let userId: Int64?
    private let repository: TodayRepositoryProtocol
    private var onboardingResult: OnboardingResult?
    private var brokerBalanceSnapshot: BrokerBalanceSnapshot?
    private var didLoad = false
    private var refreshGeneration = 0
    private var hasLoadedDashboard = false
    private var refreshTask: Task<Void, Never>?

    init(
        userId: Int64? = nil,
        onboardingResult: OnboardingResult? = nil,
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
        self.onboardingResult = onboardingResult
        self.brokerBalanceSnapshot = brokerBalanceSnapshot
        self.userAssetProfile = dashboard.userAssetProfile
        self.portfolioSnapshot = dashboard.portfolioSnapshot
        self.isAccountLinked = dashboard.isAccountLinked
        self.briefing = dashboard.briefing
        self.holdings = brokerBalanceSnapshot?.todayHoldings ?? dashboard.holdings
        self.goalProgress = Self.goalProgress(
            userId: userId,
            onboardingResult: onboardingResult,
            brokerBalanceSnapshot: brokerBalanceSnapshot,
            fallback: dashboard.goalProgress
        )
        self.newsItems = userId == nil ? dashboard.newsItems : []
        self.loadingSections = userId == nil ? [] : Set(TodaySection.allCases).subtracting([.goal])
    }

    /// Preview/test-only constructor that bypasses the mock-first init and injects a full dashboard directly.
    init(userId: Int64?, dashboard: TodayDashboard, loadState: TodayLoadState = .loaded, repository: TodayRepositoryProtocol? = nil) {
        self.userId = userId
        self.repository = repository ?? TodayRepositoryFactory.makeDefault()
        self.onboardingResult = nil
        self.brokerBalanceSnapshot = nil
        self.userAssetProfile = dashboard.userAssetProfile
        self.portfolioSnapshot = dashboard.portfolioSnapshot
        self.isAccountLinked = dashboard.isAccountLinked
        self.briefing = dashboard.briefing
        self.holdings = dashboard.holdings
        self.goalProgress = dashboard.goalProgress
        self.newsItems = dashboard.newsItems
        self.loadState = loadState
        self.loadingSections = loadState == .loading ? Set(TodaySection.allCases) : []
        self.didLoad = true
        self.hasLoadedDashboard = true
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
        await refresh(showsLoading: true)
    }

    /// 잔고 조회 응답 등으로 상위(AppRouter) 세션 데이터가 갱신됐을 때 호출한다.
    /// 예전에는 상위에서 `.id(portfolioSnapshot)`으로 화면을 통째로 재생성했는데,
    /// 그러면 뷰모델·네비게이션 경로·스크롤 위치가 전부 초기화되고 로딩 스켈레톤이 다시 노출됐다.
    /// 여기서는 로컬 파생 데이터만 즉시 갱신하고, 서버 재조회는 스켈레톤 없이 조용히 수행한다.
    func updateSessionData(
        userAssetProfile: UserAssetProfile,
        portfolioSnapshot: PortfolioSnapshot,
        onboardingResult: OnboardingResult?,
        brokerBalanceSnapshot: BrokerBalanceSnapshot?
    ) {
        guard userAssetProfile != self.userAssetProfile
                || portfolioSnapshot != self.portfolioSnapshot
                || onboardingResult?.financialGoal != self.onboardingResult?.financialGoal
                || onboardingResult?.targetAmount != self.onboardingResult?.targetAmount
                || brokerBalanceSnapshot != self.brokerBalanceSnapshot
        else {
            return
        }

        self.onboardingResult = onboardingResult
        self.brokerBalanceSnapshot = brokerBalanceSnapshot

        self.userAssetProfile = userAssetProfile
        self.portfolioSnapshot = portfolioSnapshot
        goalProgress = Self.goalProgress(
            userId: userId,
            onboardingResult: onboardingResult,
            brokerBalanceSnapshot: brokerBalanceSnapshot,
            fallback: goalProgress
        )
        if let brokerBalanceSnapshot {
            holdings = brokerBalanceSnapshot.todayHoldings
        }

        guard didLoad else { return }
        // 다음 refresh의 세대 번호를 즉시 올려 이전 응답의 반영을 막는다.
        refreshGeneration += 1
        let generation = refreshGeneration
        refreshTask?.cancel()
        Task {
            guard generation == refreshGeneration else { return }
            await repository.invalidateNews()
            guard generation == refreshGeneration else { return }
            await refresh(showsLoading: false)
        }
    }

    func refresh() async {
        await repository.invalidateNews()
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
        refreshTask?.cancel()
        let task = Task { [weak self] in
            guard let self else { return }
            await performRefresh(showsLoading: showsLoading, generation: generation)
        }
        refreshTask = task
        await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
        if generation == refreshGeneration { refreshTask = nil }
    }

    private func performRefresh(showsLoading: Bool, generation: Int) async {
        if showsLoading {
            loadState = .loading
        }
        if !hasLoadedDashboard {
            loadingSections = Set(TodaySection.allCases).subtracting([.goal])
        }

        do {
            let dashboard = try await repository.fetchDashboard(
                userId: userId,
                userAssetProfile: userAssetProfile,
                portfolioSnapshot: portfolioSnapshot
            )
            try Task<Never, Never>.checkCancellation()
            guard generation == refreshGeneration else { return }
            apply(dashboard)
            hasLoadedDashboard = true
            loadingSections = []
            loadState = dashboard.fallbackMessage.map(TodayLoadState.usingFallback) ?? .loaded
        } catch {
            guard generation == refreshGeneration else { return }
            loadingSections = []
            if error is CancellationError {
                didLoad = false
                loadState = .idle
                return
            }
            loadState = .usingFallback(message: Self.errorMessage(for: error))
        }
    }

    private func apply(_ dashboard: TodayDashboard) {
        userAssetProfile = dashboard.userAssetProfile
        portfolioSnapshot = dashboard.portfolioSnapshot
        isAccountLinked = dashboard.isAccountLinked
        briefing = dashboard.briefing
        holdings = brokerBalanceSnapshot?.todayHoldings ?? dashboard.holdings
        goalProgress = Self.goalProgress(
            userId: userId,
            onboardingResult: onboardingResult,
            brokerBalanceSnapshot: brokerBalanceSnapshot,
            fallback: dashboard.goalProgress
        )
        newsItems = dashboard.newsItems
    }

    private static func goalProgress(
        userId: Int64?,
        onboardingResult: OnboardingResult?,
        brokerBalanceSnapshot: BrokerBalanceSnapshot?,
        fallback: TodayGoalProgress?
    ) -> TodayGoalProgress? {
        if let onboardingResult {
            let currentAssetAmount = brokerBalanceSnapshot?.totalEvaluationAmount
                ?? AppMockData.brokerBalanceSnapshot.totalEvaluationAmount
            return TodayLocalGoalProgress.make(
                onboardingResult: onboardingResult,
                currentAssetAmount: currentAssetAmount
            )
        }
        return userId == nil ? fallback : nil
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
