import Foundation

nonisolated struct MockTodayRepository: TodayRepositoryProtocol {
    func fetchDashboard(
        userId: Int64?,
        userAssetProfile: UserAssetProfile,
        portfolioSnapshot: PortfolioSnapshot
    ) async throws -> TodayDashboard {
        Self.makeDashboard(
            userId: userId,
            userAssetProfile: userAssetProfile,
            portfolioSnapshot: portfolioSnapshot
        )
    }

    static func makeDashboard(
        userId: Int64? = nil,
        userAssetProfile: UserAssetProfile,
        portfolioSnapshot: PortfolioSnapshot,
        holdings: [TodayHolding] = TodayMockData.holdings,
        briefing: TodayBriefing = TodayMockData.briefing,
        goalProgress: TodayGoalProgress? = TodayMockData.goalProgress,
        newsItems: [TodayNewsItem] = TodayMockData.newsItems
    ) -> TodayDashboard {
        let resolvedBriefing = TodayDashboardBuilder.makeBriefing(from: portfolioSnapshot, fallback: briefing)

        return TodayDashboard(
            userAssetProfile: userAssetProfile,
            portfolioSnapshot: portfolioSnapshot,
            isAccountLinked: !userAssetProfile.holdings.isEmpty,
            briefing: resolvedBriefing,
            holdings: holdings,
            goalProgress: goalProgress,
            newsItems: newsItems
        )
    }
}
