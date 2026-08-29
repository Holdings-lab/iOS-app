import Foundation

nonisolated struct MockSignalRepository: SignalRepositoryProtocol {
    func fetchEvents() async throws -> [PolSignalEvent] {
        PolSignalFlowMockData.events
    }

    func fetchEvent(id: Int) async throws -> PolSignalEvent {
        PolSignalFlowMockData.event(id: id)
    }
}
