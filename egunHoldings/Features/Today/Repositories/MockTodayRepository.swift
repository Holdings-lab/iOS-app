import Foundation

nonisolated struct MockTodayRepository: TodayRepositoryProtocol {
    func fetchDashboard(
        userId: Int64?,
        userAssetProfile: UserAssetProfile,
        portfolioSnapshot: PortfolioSnapshot
    ) async throws -> TodayDashboard {
        Self.makeDashboard(
            userAssetProfile: userAssetProfile,
            portfolioSnapshot: portfolioSnapshot
        )
    }

    static func makeDashboard(
        userAssetProfile: UserAssetProfile,
        portfolioSnapshot: PortfolioSnapshot,
        policyEvents: [TodayPolicyEvent] = TodayMockData.policyEvents,
        holdings: [TodayHolding] = TodayMockData.holdings,
        judgment: TodayJudgment = TodayMockData.judgment
    ) -> TodayDashboard {
        let topPolicy = policyEvents.max { $0.myExposure < $1.myExposure }
        let portfolio = TodayDashboardBuilder.makePortfolioSummary(
            from: portfolioSnapshot,
            userAssetProfile: userAssetProfile,
            fallback: TodayMockData.portfolio
        )

        return TodayDashboard(
            userAssetProfile: userAssetProfile,
            portfolioSnapshot: portfolioSnapshot,
            judgment: judgment,
            portfolio: portfolio,
            policyEvents: policyEvents,
            holdings: holdings,
            noActionReasons: TodayMockData.noActionReasons,
            noActionWatchCondition: TodayMockData.noActionWatchCondition,
            primaryCheckpointText: TodayMockData.checkpoints.first?.text ?? judgment.invalidationCondition,
            dataUpdatedAt: topPolicy?.updatedAt ?? "오전 11:24",
            dataSources: ["예시 데이터"],
            aiSummaryStatus: "예시 브리핑"
        )
    }
}
