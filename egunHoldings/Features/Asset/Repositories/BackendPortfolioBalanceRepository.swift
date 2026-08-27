import Foundation

private nonisolated struct BackendPortfolioResponseDTO: Decodable {
    let estimatedDepositAsset: Decimal
    let cashBalance: Decimal
    let totalPurchaseAmount: Decimal
    let totalValuationAmount: Decimal
    let totalValuationGainLoss: Decimal
    let positions: [BackendAssetPositionDTO]
    let byBroker: [String: BackendAccountPortfolioDTO]
    let lastSyncedAt: String?

    func toDomain(now: Date = Date()) -> BrokerBalanceSnapshot {
        let account = byBroker.values.first
        let totalAsset = estimatedDepositAsset.positiveValue
            ?? (totalValuationAmount + cashBalance)

        return BrokerBalanceSnapshot(
            broker: account?.brokerName ?? "KIS",
            environment: "MOCK",
            accountNumber: account?.accountNumber ?? "",
            productCode: account?.accountNumber.suffixProductCode ?? "01",
            totalEvaluationAmount: totalAsset.intValue,
            stockEvaluationAmount: totalValuationAmount.intValue,
            cashAmount: cashBalance.intValue,
            totalPurchaseAmount: totalPurchaseAmount.intValue,
            totalProfitLossAmount: totalValuationGainLoss.intValue,
            holdings: positions.map { $0.toDomain() },
            fetchedAt: lastSyncedAt.flatMap(BackendLocalDateTime.parse) ?? now
        )
    }
}

private nonisolated enum BackendLocalDateTime {
    static func parse(_ value: String) -> Date? {
        if let date = NetworkJSONCoding.parseISO8601(value) {
            return date
        }

        return formatter.date(from: value)
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()
}

private nonisolated struct BackendAccountPortfolioDTO: Decodable {
    let accountNumber: String
    let brokerName: String
}

private nonisolated struct BackendAssetPositionDTO: Decodable {
    let itemCode: String
    let itemName: String
    let quantity: Decimal
    let purchaseUnitPrice: Decimal
    let purchaseAmount: Decimal
    let valuationAmount: Decimal
    let valuationGainLoss: Decimal
    let profitRate: Decimal

    func toDomain() -> BrokerHoldingSnapshot {
        BrokerHoldingSnapshot(
            symbol: itemCode,
            name: itemName,
            quantity: quantity.intValue,
            averagePurchasePrice: purchaseUnitPrice.intValue,
            purchaseAmount: purchaseAmount.intValue,
            evaluationAmount: valuationAmount.intValue,
            profitLossAmount: valuationGainLoss.intValue,
            profitLossRate: profitRate.doubleValue
        )
    }
}

private nonisolated extension Decimal {
    var intValue: Int { NSDecimalNumber(decimal: self).intValue }
    var doubleValue: Double { NSDecimalNumber(decimal: self).doubleValue }
    var positiveValue: Decimal? { self > 0 ? self : nil }
}

private nonisolated extension String {
    var suffixProductCode: String? {
        guard count >= 2 else { return nil }
        return String(suffix(2))
    }
}

/// 로그인한 사용자의 서버 저장 KIS 계좌를 합산한 포트폴리오를 조회한다.
nonisolated struct BackendPortfolioBalanceRepository: BrokerBalanceRepositoryProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClientFactory.makeDefault()) {
        self.apiClient = apiClient
    }

    func fetchPortfolioBalance() async throws -> BrokerBalanceSnapshot {
        let response = try await apiClient.requestResult(
            BackendEndpoint.portfolio(),
            as: BackendPortfolioResponseDTO.self
        )
        return response.toDomain()
    }
}
