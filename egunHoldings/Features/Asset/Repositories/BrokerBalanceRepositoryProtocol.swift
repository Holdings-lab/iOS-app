import Foundation

protocol BrokerBalanceRepositoryProtocol {
    func fetchKisSandboxBalance() async throws -> BrokerBalanceSnapshot
}
