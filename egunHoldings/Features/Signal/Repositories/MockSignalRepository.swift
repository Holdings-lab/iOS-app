struct MockSignalRepository: SignalRepositoryProtocol {
    func fetchActionQueue() -> [PolicyActionQueueItem] {
        SignalMockData.actionQueue
    }

    func fetchMatches() -> [PolicyETFMatch] {
        SignalMockData.matches
    }
    
    func fetchSimulatorAllocations() -> [SimulatorETFAllocation] {
        SignalMockData.simulatorAllocations
    }

    func fetchSimulatorContent() -> SimulatorContent {
        SignalMockData.simulatorContent
    }

    func fetchRebalancingScoreConfig() -> RebalancingScoreConfig {
        SignalMockData.rebalancingScoreConfig
    }
}
