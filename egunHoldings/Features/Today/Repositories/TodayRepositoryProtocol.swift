import Foundation

protocol TodayRepositoryProtocol {
    func fetchDashboard(
        userId: Int64?,
        userAssetProfile: UserAssetProfile,
        portfolioSnapshot: PortfolioSnapshot
    ) async throws -> TodayDashboard
}
