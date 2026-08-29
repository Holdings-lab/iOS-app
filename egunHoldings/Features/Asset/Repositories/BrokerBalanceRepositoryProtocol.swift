import Foundation

protocol BrokerBalanceRepositoryProtocol {
    func fetchPortfolioBalance() async throws -> BrokerBalanceSnapshot
}
