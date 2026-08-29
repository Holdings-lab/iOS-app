import Foundation

protocol SignalRepositoryProtocol {
    /// PolSignalEvent 이벤트 목록 조회.
    func fetchEvents() async throws -> [PolSignalEvent]

    /// 단건 이벤트 상세 조회.
    func fetchEvent(id: Int) async throws -> PolSignalEvent
}
