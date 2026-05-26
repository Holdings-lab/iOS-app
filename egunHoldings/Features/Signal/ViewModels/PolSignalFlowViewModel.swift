import Combine
import SwiftUI

@MainActor
final class PolSignalFlowViewModel: ObservableObject {
    @Published var selectedFeedTab: PolSignalFeedTab = .myImpact
    @Published var events: [PolSignalEvent] = []
    @Published var signalCards: [SignalCard] = []
    @Published var isLoading = false

    let vixText: String
    let vixChangeText: String
    let vixCaption: String
    let adjustmentProposal: PolSignalAdjustmentProposal

    private let repository: SignalRepositoryProtocol

    init(
        repository: SignalRepositoryProtocol = SignalRepositoryFactory.makeDefault(),
        vixText: String = PolSignalFlowMockData.vixText,
        vixChangeText: String = PolSignalFlowMockData.vixChangeText,
        vixCaption: String = PolSignalFlowMockData.vixCaption,
        adjustmentProposal: PolSignalAdjustmentProposal = PolSignalFlowMockData.adjustmentProposal
    ) {
        self.repository = repository
        self.vixText = vixText
        self.vixChangeText = vixChangeText
        self.vixCaption = vixCaption
        self.adjustmentProposal = adjustmentProposal
    }

    var filteredEvents: [PolSignalEvent] {
        events.filter { $0.feedTab == selectedFeedTab }
    }

    var topSignalCards: [SignalCard] {
        Array(
            signalCards
                .enumerated()
                .sorted { lhs, rhs in
                    if lhs.element.intensity.sortPriority == rhs.element.intensity.sortPriority {
                        return lhs.offset < rhs.offset
                    }
                    return lhs.element.intensity.sortPriority > rhs.element.intensity.sortPriority
                }
                .prefix(3)
                .map { $0.element }
        )
    }

    func event(id: Int) -> PolSignalEvent {
        events.first { $0.id == id } ?? PolSignalFlowMockData.events[0]
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        events = await fetchEvents()
        signalCards = await fetchSignalCards(theme: .bigTech)
    }

    func loadEvents() async {
        isLoading = true
        defer { isLoading = false }

        events = await fetchEvents()
    }

    func loadSignalCards(theme: PortfolioThemeSignal.Theme) async {
        isLoading = true
        defer { isLoading = false }

        signalCards = await fetchSignalCards(theme: theme)
    }

    private func fetchEvents() async -> [PolSignalEvent] {
        do {
            return try await repository.fetchEvents()
        } catch {
            return PolSignalFlowMockData.events
        }
    }

    private func fetchSignalCards(theme: PortfolioThemeSignal.Theme) async -> [SignalCard] {
        do {
            return try await repository.fetchSignalCards(theme: theme)
        } catch {
            return []
        }
    }
}

private extension SignalCard.Intensity {
    var sortPriority: Int {
        switch self {
        case .veryHigh:
            return 3
        case .high:
            return 2
        case .medium:
            return 1
        }
    }
}
