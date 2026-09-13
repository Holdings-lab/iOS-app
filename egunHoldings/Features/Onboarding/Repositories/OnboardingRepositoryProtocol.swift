import Foundation

nonisolated protocol OnboardingRepositoryProtocol: Sendable {
    func updateProfile(
        userId: Int64,
        investmentHorizon: InvestmentHorizon,
        maxDrawdownTolerance: MaxDrawdownTolerance,
        investmentProfile: InvestmentProfile,
        interests: [WatchAssetSector]
    ) async throws

    func updateGoal(userId: Int64, financialGoal: FinancialGoal, targetAmount: Int64) async throws

    func skipBrokerageConnection() async throws
}
