protocol AssetRebalancingRepositoryProtocol {
    func fetchRebalancing(
        userId: Int64?,
        brokerBalanceSnapshot: BrokerBalanceSnapshot?
    ) async throws -> RebalancingDashboard
}
