import Foundation

nonisolated protocol OnboardingRepositoryProtocol: Sendable {
    func updateSettings(
        userId: Int64,
        investmentHorizon: InvestmentHorizon,
        maxDrawdownTolerance: MaxDrawdownTolerance,
        investmentProfile: InvestmentProfile
    ) async throws

    func updateWatchAssets(userId: Int64, sectors: [WatchAssetSector]) async throws

    func updateGoal(userId: Int64, financialGoal: FinancialGoal, targetAmount: Int64) async throws
}
