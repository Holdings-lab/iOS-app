import Foundation

nonisolated struct LiveOnboardingRepository: OnboardingRepositoryProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClientFactory.makeDefault()) {
        self.apiClient = apiClient
    }

    func updateProfile(
        userId: Int64,
        investmentHorizon: InvestmentHorizon,
        maxDrawdownTolerance: MaxDrawdownTolerance,
        investmentProfile: InvestmentProfile,
        interests: [WatchAssetSector]
    ) async throws {
        let body = try NetworkJSONCoding.encodeJSON(
            OnboardingProfilePatchRequestDTO(
                investmentHorizon: investmentHorizon.wireValue,
                riskTolerance: maxDrawdownTolerance.wireValue,
                investmentStyle: investmentProfile.wireValue,
                interests: interests.map(\.wireValue)
            )
        )
        _ = try await apiClient.requestResult(
            BackendEndpoint.updateOnboardingProfile(body: body),
            as: EmptyAPIResult.self
        )
    }
}
