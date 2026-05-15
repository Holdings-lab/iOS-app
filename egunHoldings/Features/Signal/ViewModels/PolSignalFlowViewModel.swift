import Combine
import SwiftUI

final class PolSignalFlowViewModel: ObservableObject {
    @Published var selectedFeedTab: PolSignalFeedTab = .myImpact

    let vixText: String
    let vixChangeText: String
    let vixCaption: String
    let events: [PolSignalEvent]
    let adjustmentProposal: PolSignalAdjustmentProposal

    init(
        vixText: String = PolSignalFlowMockData.vixText,
        vixChangeText: String = PolSignalFlowMockData.vixChangeText,
        vixCaption: String = PolSignalFlowMockData.vixCaption,
        events: [PolSignalEvent] = PolSignalFlowMockData.events,
        adjustmentProposal: PolSignalAdjustmentProposal = PolSignalFlowMockData.adjustmentProposal
    ) {
        self.vixText = vixText
        self.vixChangeText = vixChangeText
        self.vixCaption = vixCaption
        self.events = events
        self.adjustmentProposal = adjustmentProposal
    }

    var filteredEvents: [PolSignalEvent] {
        events.filter { $0.feedTab == selectedFeedTab }
    }

    func event(id: Int) -> PolSignalEvent {
        events.first { $0.id == id } ?? events[0]
    }
}
