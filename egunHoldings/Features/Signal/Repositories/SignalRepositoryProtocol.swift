import Foundation

protocol SignalRepositoryProtocol {
    /// Today Top 3 테마 신호 목록 조회.
    func fetchThemeSignals() async throws -> [PortfolioThemeSignal]

    /// Signal 탭 상세 - 이번 주 눈에 띄는 신호 카드 조회.
    func fetchSignalCards(theme: PortfolioThemeSignal.Theme) async throws -> [SignalCard]

    /// PolSignalEvent 이벤트 목록 조회.
    func fetchEvents() async throws -> [PolSignalEvent]

    /// 단건 이벤트 상세 조회.
    func fetchEvent(id: Int) async throws -> PolSignalEvent
}
