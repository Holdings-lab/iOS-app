import Foundation

private struct BrokerBalanceResponseDTO: Decodable {
    let broker: String
    let environment: String
    let accountNumber: String
    let productCode: String
    let totalEvaluationAmount: Int
    let stockEvaluationAmount: Int
    let cashAmount: Int
    let totalPurchaseAmount: Int
    let totalProfitLossAmount: Int
    let holdings: [BrokerHoldingResponseDTO]
    let fetchedAt: Date

    func toDomain() -> BrokerBalanceSnapshot {
        BrokerBalanceSnapshot(
            broker: broker,
            environment: environment,
            accountNumber: accountNumber,
            productCode: productCode,
            totalEvaluationAmount: totalEvaluationAmount,
            stockEvaluationAmount: stockEvaluationAmount,
            cashAmount: cashAmount,
            totalPurchaseAmount: totalPurchaseAmount,
            totalProfitLossAmount: totalProfitLossAmount,
            holdings: holdings.map { $0.toDomain() },
            fetchedAt: fetchedAt
        )
    }
}

private struct BrokerHoldingResponseDTO: Decodable {
    let symbol: String
    let name: String
    let quantity: Int
    let averagePurchasePrice: Int
    let purchaseAmount: Int
    let evaluationAmount: Int
    let profitLossAmount: Int
    let profitLossRate: Double

    func toDomain() -> BrokerHoldingSnapshot {
        BrokerHoldingSnapshot(
            symbol: symbol,
            name: name,
            quantity: quantity,
            averagePurchasePrice: averagePurchasePrice,
            purchaseAmount: purchaseAmount,
            evaluationAmount: evaluationAmount,
            profitLossAmount: profitLossAmount,
            profitLossRate: profitLossRate
        )
    }
}

nonisolated struct BrokerBalanceLookupRequestDTO: Encodable, Sendable {
    let accountNumber: String?
    let productCode: String?
}

enum BrokerBalanceRepositoryError: LocalizedError {
    case unavailable
    case invalidRequestEncoding

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "잔고조회 서버 주소가 설정되지 않았습니다."
        case .invalidRequestEncoding:
            return "잔고조회 요청 데이터를 만들지 못했습니다."
        }
    }
}

nonisolated struct KisSandboxBalanceRepository: BrokerBalanceRepositoryProtocol {
    private let apiClient: APIClient
    private let baseURL: URL
    private let isAvailable: Bool
    private let accountNumber: String?
    private let productCode: String?

    init(
        apiClient: APIClient = APIClientFactory.makeDefault(),
        baseURL: URL? = NetworkConfiguration.tradingServerBaseURL,
        accountNumber: String? = NetworkConfiguration.tradingKisAccountNumber,
        productCode: String? = NetworkConfiguration.tradingKisProductCode
    ) {
        guard let baseURL else {
            self.apiClient = StubAPIClient()
            self.baseURL = URL(string: "http://localhost")!
            self.isAvailable = false
            self.accountNumber = accountNumber
            self.productCode = productCode
            return
        }

        self.apiClient = apiClient
        self.baseURL = baseURL
        self.isAvailable = true
        self.accountNumber = accountNumber
        self.productCode = productCode
    }

    func fetchKisSandboxBalance() async throws -> BrokerBalanceSnapshot {
        guard isAvailable else {
            throw BrokerBalanceRepositoryError.unavailable
        }

        let requestBody = try Self.makeRequestBody(
            accountNumber: accountNumber,
            productCode: productCode
        )

        let response = try await apiClient.request(
            Endpoint(
                baseURL: baseURL,
                path: "/api/v1/brokers/kis/sandbox/balance",
                method: .post,
                headers: ["Content-Type": "application/json"],
                body: requestBody
            ),
            as: BrokerBalanceResponseDTO.self
        )

        return response.toDomain()
    }

    private static func makeRequestBody(accountNumber: String?, productCode: String?) throws -> Data? {
        let normalizedAccountNumber = accountNumber?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedProductCode = productCode?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            normalizedAccountNumber?.isEmpty == false || normalizedProductCode?.isEmpty == false
        else {
            return nil
        }

        let payload = BrokerBalanceLookupRequestDTO(
            accountNumber: normalizedAccountNumber,
            productCode: normalizedProductCode
        )

        do {
            return try JSONEncoder().encode(payload)
        } catch {
            throw BrokerBalanceRepositoryError.invalidRequestEncoding
        }
    }
}
