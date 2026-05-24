import Foundation

nonisolated protocol InvestmentProfileRepositoryProtocol: Sendable {
    func fetchInvestmentProfile(userId: Int64) async throws -> InvestmentProfileResponse
    func updateInvestmentProfile(userId: Int64, profile: InvestmentProfile) async throws -> InvestmentProfileResponse
}

nonisolated struct InvestmentProfileResponse: Decodable, Sendable, Equatable {
    let userId: Int64
    let investmentProfile: InvestmentProfile
    let displayName: String
}

nonisolated private struct InvestmentProfileRequestDTO: Encodable {
    let investmentProfile: String
}

nonisolated struct LiveInvestmentProfileRepository: InvestmentProfileRepositoryProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClientFactory.makeDefault()) {
        self.apiClient = apiClient
    }

    func fetchInvestmentProfile(userId: Int64) async throws -> InvestmentProfileResponse {
        try await apiClient.requestResult(
            BackendEndpoint.investmentProfile(userId: userId),
            as: InvestmentProfileResponse.self
        )
    }

    func updateInvestmentProfile(userId: Int64, profile: InvestmentProfile) async throws -> InvestmentProfileResponse {
        let body = try NetworkJSONCoding.encodeJSON(
            InvestmentProfileRequestDTO(investmentProfile: profile.rawValue)
        )

        do {
            return try await apiClient.requestResult(
                BackendEndpoint.updateInvestmentProfile(userId: userId, body: body),
                as: InvestmentProfileResponse.self
            )
        } catch {
            guard Self.shouldUseLocalProfileFallback(for: error) else {
                throw error
            }

            return InvestmentProfileResponse(
                userId: userId,
                investmentProfile: profile,
                displayName: profile.displayName
            )
        }
    }

    private static func shouldUseLocalProfileFallback(for error: Error) -> Bool {
        if error is NetworkError {
            return true
        }

        return (error as NSError).domain == NSURLErrorDomain
    }
}
