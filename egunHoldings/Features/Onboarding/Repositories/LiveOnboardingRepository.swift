import Foundation

nonisolated struct LiveOnboardingRepository: OnboardingRepositoryProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClientFactory.makeDefault()) {
        self.apiClient = apiClient
    }

    func updateSettings(
        userId: Int64,
        investmentHorizon: InvestmentHorizon,
        maxDrawdownTolerance: MaxDrawdownTolerance,
        investmentProfile: InvestmentProfile
    ) async throws {
        let body = try NetworkJSONCoding.encodeJSON(
            OnboardingSettingsPatchRequestDTO(
                investmentHorizon: investmentHorizon.rawValue,
                maxDrawdownTolerance: maxDrawdownTolerance.percentValue,
                investmentProfile: investmentProfile.rawValue
            )
        )
        _ = try await apiClient.requestResult(
            BackendEndpoint.updateMeSettings(userId: userId, body: body),
            as: EmptyAPIResult.self
        )
    }

    func updateWatchAssets(userId: Int64, sectors: [WatchAssetSector]) async throws {
        let body = try NetworkJSONCoding.encodeJSON(
            WatchAssetsUpdateRequestDTO(sectors: sectors.map(\.rawValue))
        )
        _ = try await apiClient.requestResult(
            BackendEndpoint.updateWatchAssets(userId: userId, body: body),
            as: EmptyAPIResult.self
        )
    }

    func updateGoal(userId: Int64, financialGoal: FinancialGoal, targetAmount: Int64) async throws {
        let body = try NetworkJSONCoding.encodeJSON(
            GoalUpdateRequestDTO(financialGoal: financialGoal.rawValue, targetAmount: targetAmount)
        )
        _ = try await apiClient.requestResult(
            BackendEndpoint.updateGoal(userId: userId, body: body),
            as: EmptyAPIResult.self
        )
    }
}
