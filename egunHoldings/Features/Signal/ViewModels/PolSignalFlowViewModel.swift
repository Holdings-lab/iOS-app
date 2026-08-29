import Combine
import SwiftUI

@MainActor
final class PolSignalFlowViewModel: ObservableObject {
    @Published var selectedFeedTab: PolSignalFeedTab = .myImpact
    @Published var events: [PolSignalEvent] = []
    @Published var isLoading = false

    let vixText: String
    let vixChangeText: String
    let vixCaption: String
    let adjustmentProposal: PolSignalAdjustmentProposal

    private let repository: SignalRepositoryProtocol
    private var didLoad = false

    init(
        userId: Int64? = nil,
        repository: SignalRepositoryProtocol? = nil,
        vixText: String = PolSignalFlowMockData.vixText,
        vixChangeText: String = PolSignalFlowMockData.vixChangeText,
        vixCaption: String = PolSignalFlowMockData.vixCaption,
        adjustmentProposal: PolSignalAdjustmentProposal = PolSignalFlowMockData.adjustmentProposal
    ) {
        self.repository = repository ?? SignalRepositoryFactory.makeDefault(userId: userId)
        self.vixText = vixText
        self.vixChangeText = vixChangeText
        self.vixCaption = vixCaption
        self.adjustmentProposal = adjustmentProposal
    }

    func event(id: Int) -> PolSignalEvent {
        events.first { $0.id == id } ?? PolSignalFlowMockData.events[0]
    }

    func loadIfNeeded() async {
        guard !didLoad else { return }
        await load()
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        events = await fetchEvents()
        didLoad = true
    }

    private func fetchEvents() async -> [PolSignalEvent] {
        do {
            return try await repository.fetchEvents()
        } catch {
            return PolSignalFlowMockData.events
        }
    }

}
