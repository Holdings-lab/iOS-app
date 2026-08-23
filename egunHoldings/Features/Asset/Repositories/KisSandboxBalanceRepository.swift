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

enum BrokerBalanceRepositoryError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "잔고조회 서버 주소가 설정되지 않았습니다."
        }
    }
}

/// 한국투자증권 모의투자 잔고 조회.
///
/// 앱키·시크릿과 그 키에 묶인 계좌는 전부 서버에만 존재한다. 클라이언트가 계좌번호를 따로 들고
/// 있으면 서버의 앱키와 어긋날 수 있어, 어느 계좌를 조회할지는 전적으로 서버가 결정한다.
/// 계좌번호는 응답으로 받아서 화면에 보여주기만 한다.
nonisolated struct KisSandboxBalanceRepository: BrokerBalanceRepositoryProtocol {
    private let apiClient: APIClient
    private let baseURL: URL
    private let isAvailable: Bool

    init(
        apiClient: APIClient = APIClientFactory.makeDefault(),
        baseURL: URL? = NetworkConfiguration.tradingServerBaseURL
    ) {
        guard let baseURL else {
            self.apiClient = StubAPIClient()
            self.baseURL = URL(string: "http://localhost")!
            self.isAvailable = false
            return
        }

        self.apiClient = apiClient
        self.baseURL = baseURL
        self.isAvailable = true
    }

    func fetchKisSandboxBalance() async throws -> BrokerBalanceSnapshot {
        guard isAvailable else {
            throw BrokerBalanceRepositoryError.unavailable
        }

        let response = try await apiClient.requestResult(
            Endpoint(
                baseURL: baseURL,
                path: "/api/brokers/kis/sandbox/balance",
                method: .post,
                body: nil
            ),
            as: BrokerBalanceResponseDTO.self
        )

        return response.toDomain()
    }
}
