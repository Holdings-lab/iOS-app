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
    private var didLoad = false

    init(
        userId: Int64? = nil,
        userAssetProfile: UserAssetProfile,
        portfolioSnapshot: PortfolioSnapshot,
        holdings: [TodayHolding] = TodayMockData.holdings,
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
        self.userAssetProfile = dashboard.userAssetProfile
        self.portfolioSnapshot = dashboard.portfolioSnapshot
        self.isAccountLinked = dashboard.isAccountLinked
        self.briefing = dashboard.briefing
        self.holdings = dashboard.holdings
        self.goalProgress = dashboard.goalProgress
        self.newsItems = dashboard.newsItems
    }

    /// Preview/test-only constructor that bypasses the mock-first init and injects a full dashboard directly.
    init(userId: Int64?, dashboard: TodayDashboard, loadState: TodayLoadState = .loaded, repository: TodayRepositoryProtocol? = nil) {
        self.userId = userId
        self.repository = repository ?? TodayRepositoryFactory.makeDefault()
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
        Array(holdings.sorted { $0.weight > $1.weight }.prefix(3))
    }

    func load() async {
        guard !didLoad else { return }
        didLoad = true
        await refresh()
    }

    func refresh() async {
        guard userId != nil else {
            loadState = .usingFallback(message: nil)
            return
        }

        loadState = .loading

        do {
            let dashboard = try await repository.fetchDashboard(
                userId: userId,
                userAssetProfile: userAssetProfile,
                portfolioSnapshot: portfolioSnapshot
            )
            apply(dashboard)
            loadState = .loaded
        } catch {
            loadState = .usingFallback(message: Self.errorMessage(for: error))
        }
    }

    private func apply(_ dashboard: TodayDashboard) {
        userAssetProfile = dashboard.userAssetProfile
        portfolioSnapshot = dashboard.portfolioSnapshot
        isAccountLinked = dashboard.isAccountLinked
        briefing = dashboard.briefing
        holdings = dashboard.holdings
        goalProgress = dashboard.goalProgress
        newsItems = dashboard.newsItems
    }

    private static func errorMessage(for error: Error) -> String {
        AppVocabulary.ErrorMessage.userFacing(for: error)
    }
}
