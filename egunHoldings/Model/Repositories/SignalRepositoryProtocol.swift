protocol SignalRepositoryProtocol {
    func fetchActionQueue() -> [PolicyActionQueueItem]
    func fetchMatches() -> [PolicyETFMatch]
    func fetchSimulatorAllocations() -> [SimulatorETFAllocation]
    func fetchSimulatorContent() -> SimulatorContent
    func fetchRebalancingScoreConfig() -> RebalancingScoreConfig
}
