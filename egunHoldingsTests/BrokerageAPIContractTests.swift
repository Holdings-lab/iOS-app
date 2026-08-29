import Foundation
import Testing
@testable import egunHoldings

struct BrokerageAPIContractTests {
    @Test("KIS 모의투자 계좌를 body 없이 /api/accounts에 연결한다")
    func connectsServerManagedKISAccount() async throws {
        let queue = APIRequestQueue(responses: [
            envelope(resultJSON: "[]"),
            envelope(resultJSON: linkedAccountJSON),
            envelope(resultJSON: #"{"status":"SUCCESS"}"#),
        ])
        let repository = LiveBrokerageConnectionRepository(apiClient: QueueAPIClient(queue: queue))

        let connection = try await repository.connectKISDemoAccount(
            institutionID: AccountInstitution.koreaInvestmentID
        )
        try await repository.sync(accountId: connection.accountId)

        let requests = await queue.recordedRequests()
        #expect(connection.accountId == 17)
        #expect(connection.brokerage == .kis)
        #expect(connection.accountNumber == "1234567801")
        #expect(requests.map(\.path) == ["/api/accounts", "/api/accounts", "/api/accounts/17/sync"])
        #expect(requests.map(\.method.rawValue) == ["GET", "POST", "POST"])
        #expect(requests[1].body == nil)
    }

    @Test("서버 포트폴리오 응답을 앱 잔고 모델로 변환한다")
    @MainActor
    func mapsBackendPortfolio() async throws {
        let queue = APIRequestQueue(responses: [envelope(resultJSON: portfolioJSON)])
        let repository = BackendPortfolioBalanceRepository(apiClient: QueueAPIClient(queue: queue))

        let balance = try await repository.fetchPortfolioBalance()

        let requests = await queue.recordedRequests()
        #expect(requests.map(\.path) == ["/api/portfolio"])
        #expect(balance.accountNumber == "1234567801")
        #expect(balance.productCode == "01")
        #expect(balance.totalEvaluationAmount == 1_250_000)
        #expect(balance.cashAmount == 250_000)
        #expect(balance.holdings.first?.symbol == "005930")
        #expect(balance.holdings.first?.evaluationAmount == 1_000_000)
        #expect(balance.holdings.first?.currentPrice == 100_000)
        #expect(balance.holdings.first?.marketValue == 1_000_000)
        #expect(balance.holdings.first?.currencyCode == "USD")
        #expect(AssetPortfolioDisplay(snapshot: balance).holdings.first?.amountText == "$1,000,000")
    }

    @Test("계좌 연결 요청이 실패하면 온보딩을 연결 완료로 표시하지 않는다")
    @MainActor
    func failedConnectionDoesNotAdvanceState() async {
        let viewModel = OnboardingFlowViewModel(
            onboardingRepository: NoopOnboardingRepository(),
            brokerageConnectionRepository: FailingBrokerageRepository(),
            brokerBalanceRepository: FailingBalanceRepository()
        )
        viewModel.selectInstitution(viewModel.recommendedInstitution)

        let didConnect = await viewModel.connectBrokerage(userId: 1, reduceMotion: true)

        #expect(didConnect == false)
        #expect(viewModel.isBrokerageConnected == false)
        #expect(viewModel.linkedAccount == nil)
        #expect(viewModel.brokerageLinkErrorMessage != nil)
    }

    private var linkedAccountJSON: String {
        #"[{"accountId":17,"brokerName":"KIS","accountNumber":"1234567801","status":"CONNECTED","accountSnapshot":{"accountProductCode":"01"}}]"#
    }

    private var portfolioJSON: String {
        #"{"estimatedDepositAsset":1250000,"cashBalance":250000,"totalPurchaseAmount":800000,"totalValuationAmount":1000000,"totalValuationGainLoss":200000,"totalProfitRate":25,"positions":[{"itemCode":"005930","itemName":"삼성전자","quantity":10,"purchaseUnitPrice":80000,"presentPrice":100000,"purchaseAmount":800000,"valuationAmount":1000000,"valuationGainLoss":200000,"profitRate":25,"currencyCode":"USD"}],"byBroker":{"KIS_1234567801":{"accountId":17,"accountNumber":"1234567801","brokerName":"KIS","estimatedDepositAsset":1250000,"cashBalance":250000,"positions":[],"lastSyncedAt":"2026-08-27T10:00:00"}},"lastSyncedAt":"2026-08-27T10:00:00"}"#
    }

    private func envelope(resultJSON: String) -> Data {
        Data(#"{"isSuccess":true,"code":"SUCCESS-200","message":"OK","result":\#(resultJSON)}"#.utf8)
    }
}

private enum QueueError: Error {
    case missingResponse
}

private actor APIRequestQueue {
    private var responses: [Data]
    private var requests: [Endpoint] = []

    init(responses: [Data]) {
        self.responses = responses
    }

    func nextResponse(for endpoint: Endpoint) throws -> Data {
        requests.append(endpoint)
        guard !responses.isEmpty else { throw QueueError.missingResponse }
        return responses.removeFirst()
    }

    func recordedRequests() -> [Endpoint] {
        requests
    }
}

private struct QueueAPIClient: APIClient {
    let queue: APIRequestQueue

    nonisolated func request<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        let data = try await queue.nextResponse(for: endpoint)
        return try NetworkJSONCoding.makeDecoder().decode(type, from: data)
    }
}

private struct FailingBrokerageRepository: BrokerageConnectionRepositoryProtocol {
    func connectKISDemoAccount(institutionID _: String) async throws -> BrokerageConnection {
        throw BrokerageConnectionError.connectionRejected
    }

    func sync(accountId _: Int64) async throws {}
}

private struct FailingBalanceRepository: BrokerBalanceRepositoryProtocol {
    func fetchPortfolioBalance() async throws -> BrokerBalanceSnapshot {
        throw QueueError.missingResponse
    }
}

private struct NoopOnboardingRepository: OnboardingRepositoryProtocol {
    func updateSettings(
        userId _: Int64,
        investmentHorizon _: InvestmentHorizon,
        maxDrawdownTolerance _: MaxDrawdownTolerance,
        investmentProfile _: InvestmentProfile
    ) async throws {}

    func updateWatchAssets(userId _: Int64, sectors _: [WatchAssetSector]) async throws {}

    func updateGoal(userId _: Int64, financialGoal _: FinancialGoal, targetAmount _: Int64) async throws {}
}
