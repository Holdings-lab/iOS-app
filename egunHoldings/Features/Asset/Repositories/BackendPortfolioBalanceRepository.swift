import Foundation

private nonisolated struct BackendPortfolioResponseDTO: Decodable {
    let estimatedDepositAsset: Decimal
    let cashBalance: Decimal
    let totalPurchaseAmount: Decimal
    let totalValuationAmount: Decimal
    let totalValuationGainLoss: Decimal
    let positions: [BackendAssetPositionDTO]
    /// 최신 서버 합산 응답에는 계좌별 요약이 포함되지 않는다. 이전 응답과의 호환을 위해
    /// 값이 있을 때만 계좌 번호와 증권사명을 표시용 모델에 반영한다.
    let byBroker: [String: BackendAccountPortfolioDTO]?
    let lastSyncedAt: String?

    func toDomain(now: Date = Date()) -> BrokerBalanceSnapshot {
        let account = byBroker?.values.first
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
    let productType: String?
    let quantity: Decimal
    /// 이전 서버 계약의 평면 금액 필드. 배포 중인 서버는 native/krw 중첩 구조를 쓴다.
    let purchaseUnitPrice: Decimal?
    let presentPrice: Decimal?
    let purchaseAmount: Decimal?
    let valuationAmount: Decimal?
    let valuationGainLoss: Decimal?
    let profitRate: Decimal
    let currencyCode: String?
    let native: BackendPositionNativeDTO?
    let krw: BackendPositionKrwDTO?

    func toDomain() -> BrokerHoldingSnapshot {
        BrokerHoldingSnapshot(
            symbol: itemCode,
            name: itemName,
            productType: productType,
            quantity: quantity.intValue,
            currentPrice: native?.presentPrice ?? presentPrice,
            currencyCode: currencyCode ?? "KRW",
            averagePurchasePrice: (native?.purchaseUnitPrice ?? purchaseUnitPrice ?? 0).intValue,
            purchaseAmount: (native?.purchaseAmount ?? purchaseAmount ?? krw?.purchaseAmount ?? 0).intValue,
            evaluationAmount: (native?.valuationAmount ?? valuationAmount ?? krw?.valuationAmount ?? 0).intValue,
            profitLossAmount: (native?.gainLoss ?? valuationGainLoss ?? krw?.gainLoss ?? 0).intValue,
            profitLossRate: profitRate.doubleValue
        )
    }
}

private nonisolated struct BackendPositionNativeDTO: Decodable {
    let purchaseUnitPrice: Decimal?
    let presentPrice: Decimal?
    let purchaseAmount: Decimal?
    let valuationAmount: Decimal?
    let gainLoss: Decimal?
}

private nonisolated struct BackendPositionKrwDTO: Decodable {
    let purchaseAmount: Decimal?
    let valuationAmount: Decimal?
    let gainLoss: Decimal?
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
