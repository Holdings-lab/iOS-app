import Foundation

nonisolated struct LiveSignalRepository: SignalRepositoryProtocol {
    private let userId: Int64?
    private let apiClient: APIClient
    private let fallbackRepository: MockSignalRepository

    init(
        userId: Int64? = nil,
        apiClient: APIClient = APIClientFactory.makeDefault(),
        fallbackRepository: MockSignalRepository = MockSignalRepository()
    ) {
        self.userId = userId
        self.apiClient = apiClient
        self.fallbackRepository = fallbackRepository
    }

    func fetchThemeSignals() async throws -> [PortfolioThemeSignal] {
        do {
            let dtos = try await apiClient.requestResult(
                BackendEndpoint.signalThemes(),
                as: [SignalThemeResponseDTO].self
            )
            let signals = dtos.compactMap { $0.toDomain(relatedEventId: $0.relatedEventId) }
            return signals.isEmpty ? try await fallbackRepository.fetchThemeSignals() : signals
        } catch {
            guard Self.shouldUseFallback(for: error) else {
                throw error
            }

            return try await fallbackRepository.fetchThemeSignals()
        }
    }

    func fetchSignalCards(theme: PortfolioThemeSignal.Theme) async throws -> [SignalCard] {
        do {
            let dtos = try await apiClient.requestResult(
                BackendEndpoint.signalCards(theme: theme.tickerId),
                as: [SignalCardResponseDTO].self
            )
            let cards = dtos.compactMap { $0.toDomain() }
            return cards.isEmpty ? try await fallbackRepository.fetchSignalCards(theme: theme) : cards
        } catch {
            guard Self.shouldUseFallback(for: error) else {
                throw error
            }

            return try await fallbackRepository.fetchSignalCards(theme: theme)
        }
    }

    func fetchEvents() async throws -> [PolSignalEvent] {
        guard let userId else {
            return try await fallbackRepository.fetchEvents()
        }

        do {
            let response = try await apiClient.requestResult(
                BackendEndpoint.events(userId: userId),
                as: TodayEventsResponseDTO.self
            )
            let fallback = try await fallbackRepository.fetchEvents()
            return response.toSignalEvents(fallback: fallback)
        } catch {
            guard Self.shouldUseFallback(for: error) else {
                throw error
            }

            return try await fallbackRepository.fetchEvents()
        }
    }

    func fetchEvent(id: Int) async throws -> PolSignalEvent {
        let events = try await fetchEvents()
        if let event = events.first(where: { $0.id == id }) {
            return event
        }

        return try await fallbackRepository.fetchEvent(id: id)
    }

    private static func shouldUseFallback(for error: Error) -> Bool {
        if error is NetworkError {
            return true
        }

        return (error as NSError).domain == NSURLErrorDomain
    }
}
