import Foundation

nonisolated struct LiveSignalRepository: SignalRepositoryProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClientFactory.makeDefault()) {
        self.apiClient = apiClient
    }

    func fetchThemeSignals() async throws -> [PortfolioThemeSignal] {
        let dtos = try await apiClient.requestResult(
            BackendEndpoint.signalThemes(),
            as: [SignalThemeResponseDTO].self
        )
        return dtos.compactMap { $0.toDomain(relatedEventId: $0.relatedEventId) }
    }

    func fetchSignalCards(theme: PortfolioThemeSignal.Theme) async throws -> [SignalCard] {
        let dtos = try await apiClient.requestResult(
            BackendEndpoint.signalCards(theme: theme.tickerId),
            as: [SignalCardResponseDTO].self
        )
        return dtos.compactMap { $0.toDomain() }
    }

    func fetchEvents() async throws -> [PolSignalEvent] {
        // TODO: 백엔드 이벤트 목록 API 연결 시 구현.
        throw URLError(.unsupportedURL)
    }

    func fetchEvent(id: Int) async throws -> PolSignalEvent {
        // TODO: 백엔드 이벤트 상세 API 연결 시 구현.
        throw URLError(.unsupportedURL)
    }
}
