import Foundation

protocol TodayRepositoryProtocol {
    func fetchDashboard(
        userId: Int64?,
        userAssetProfile: UserAssetProfile,
        portfolioSnapshot: PortfolioSnapshot,
        onSection: (@MainActor @Sendable (TodaySectionUpdate) -> Void)?
    ) async throws -> TodayDashboard
    func invalidateNews() async
    func newsUpdates() async -> AsyncStream<[TodayNewsItem]>
}

extension TodayRepositoryProtocol {
    func fetchDashboard(
        userId: Int64?, userAssetProfile: UserAssetProfile, portfolioSnapshot: PortfolioSnapshot
    ) async throws -> TodayDashboard {
        try await fetchDashboard(userId: userId, userAssetProfile: userAssetProfile,
                                 portfolioSnapshot: portfolioSnapshot, onSection: nil)
    }

    func invalidateNews() async {}
    func newsUpdates() async -> AsyncStream<[TodayNewsItem]> {
        AsyncStream { $0.finish() }
    }
}

enum TodaySection: CaseIterable, Hashable, Sendable {
    case briefing, holdings, goal, news
}

enum TodaySectionUpdate: Sendable {
    case briefing(isAccountLinked: Bool?, TodayBriefing)
    case holdings(isAccountLinked: Bool?, [TodayHolding])
    case goal(isAccountLinked: Bool?, TodayGoalProgress?)
    case news([TodayNewsItem])
}
