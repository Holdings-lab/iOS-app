import Foundation

nonisolated struct LiveAssetRebalancingRepository: AssetRebalancingRepositoryProtocol {
    private let apiClient: APIClient
    private let fallbackRepository: MockAssetRebalancingRepository

    init(
        apiClient: APIClient = APIClientFactory.makeDefault(),
        fallbackRepository: MockAssetRebalancingRepository = MockAssetRebalancingRepository()
    ) {
        self.apiClient = apiClient
        self.fallbackRepository = fallbackRepository
    }

    func fetchRebalancing(
        userId: Int64?,
        brokerBalanceSnapshot: BrokerBalanceSnapshot?
    ) async throws -> RebalancingDashboard {
        let fallback = try await fallbackRepository.fetchRebalancing(
            userId: userId,
            brokerBalanceSnapshot: brokerBalanceSnapshot
        )

        guard let userId else {
            return fallback
        }

        do {
            if let brokerBalanceSnapshot, brokerBalanceSnapshot.holdings.isEmpty == false {
                return try await fetchPreview(
                    userId: userId,
                    brokerBalanceSnapshot: brokerBalanceSnapshot,
                    fallback: fallback
                )
            }

            let response = try await apiClient.requestResult(
                BackendEndpoint.portfolioRebalancing(userId: userId),
                as: RebalancingResponseDTO.self
            )

            return response.toDomain(fallback: fallback)
        } catch {
            guard Self.shouldUseFallback(for: error) else {
                throw error
            }

            return fallback
        }
    }

    private func fetchPreview(
        userId: Int64,
        brokerBalanceSnapshot: BrokerBalanceSnapshot,
        fallback: RebalancingDashboard
    ) async throws -> RebalancingDashboard {
        let requestBody = try NetworkJSONCoding.encodeJSON(
            Self.makePreviewRequest(from: brokerBalanceSnapshot)
        )

        let response = try await apiClient.requestResult(
            BackendEndpoint.portfolioRebalancingPreview(userId: userId, body: requestBody),
            as: RebalancingResponseDTO.self
        )

        return response.toDomain(fallback: fallback)
    }

    private static func makePreviewRequest(from snapshot: BrokerBalanceSnapshot) -> RebalancingPreviewRequestDTO {
        RebalancingPreviewRequestDTO(
            investmentProfile: nil,
            cash: Double(snapshot.cashAmount),
            positions: snapshot.holdings
                .filter { $0.quantity > 0 }
                .map { holding in
                    RebalancingPreviewPositionRequestDTO(
                        assetName: holding.name,
                        symbol: holding.symbol,
                        assetClass: assetClass(for: holding),
                        quantity: holding.quantity,
                        currentPrice: currentPrice(for: holding),
                        locked: nil
                    )
                }
        )
    }

    private static func currentPrice(for holding: BrokerHoldingSnapshot) -> Double {
        guard holding.quantity > 0 else {
            return Double(holding.averagePurchasePrice)
        }

        return Double(holding.evaluationAmount) / Double(holding.quantity)
    }

    private static func assetClass(for holding: BrokerHoldingSnapshot) -> String {
        let searchable = "\(holding.symbol) \(holding.name)".lowercased()

        if searchable.contains("bond")
            || searchable.contains("채권")
            || searchable.contains("국채")
            || searchable.contains("cash")
            || searchable.contains("달러") {
            return "DEFENSIVE"
        }

        if searchable.contains("qqq")
            || searchable.contains("nasdaq")
            || searchable.contains("나스닥")
            || searchable.contains("growth")
            || searchable.contains("성장") {
            return "GROWTH"
        }

        if searchable.contains("tsla")
            || searchable.contains("crypto")
            || searchable.contains("비트")
            || searchable.contains("코인") {
            return "SPECULATIVE"
        }

        return "CORE"
    }

    private static func shouldUseFallback(for error: Error) -> Bool {
        switch error {
        case NetworkError.httpStatus(404), NetworkError.notImplemented:
            return true
        case NetworkError.apiFailure(let statusCode, _, _):
            return statusCode == 404
        default:
            return false
        }
    }
}
