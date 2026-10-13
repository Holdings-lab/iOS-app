import Foundation

nonisolated protocol OnboardingRepositoryProtocol: Sendable {
    func updateProfile(
        userId: Int64,
        investmentHorizon: InvestmentHorizon,
        maxDrawdownTolerance: MaxDrawdownTolerance,
        investmentProfile: InvestmentProfile,
        interests: [WatchAssetSector]
    ) async throws
}
