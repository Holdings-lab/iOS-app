import Combine
import SwiftUI

@MainActor
final class CheckpointViewModel: ObservableObject {
    @Published var selectedFilter: CheckpointFilter = .all
    @Published var expandedPolicyIds: Set<Int> = [1]
    @Published var detailCheckpoint: CheckpointItem?
    @Published private(set) var checkpoints: [CheckpointItem]

    let policyEvents: [CheckpointPolicyEvent]
    let decisionItems: [CheckpointDecisionItem]

    init(
        policyEvents: [CheckpointPolicyEvent] = CheckpointMockData.policyEvents,
        decisionItems: [CheckpointDecisionItem] = CheckpointMockData.decisionItems
    ) {
        self.policyEvents = policyEvents
        self.decisionItems = decisionItems
        self.checkpoints = policyEvents.flatMap(\.checkpoints)
    }

    var headerSummary: String {
        let total = checkpoints.count
        let done = checkpoints.filter(\.completed).count
        return "이번 주 일정 \(policyEvents.count)개 · 체크리스트 \(done)/\(total) 완료"
    }

    var filteredCheckpoints: [CheckpointItem] {
        let base: [CheckpointItem]
        switch selectedFilter {
        case .all:
            base = checkpoints
        case .today:
            base = checkpoints.filter { checkpoint in
                policyEvents.first { $0.id == checkpoint.linkedPolicyId }?.isToday == true
            }
        }
        return base.sorted { lhs, rhs in
            if lhs.completed == rhs.completed { return false }
            return !lhs.completed && rhs.completed
        }
    }

    func policy(for checkpoint: CheckpointItem) -> CheckpointPolicyEvent? {
        policyEvents.first { $0.id == checkpoint.linkedPolicyId }
    }

    func decisions(for policyId: Int) -> [CheckpointDecisionItem] {
        decisionItems.filter { $0.linkedPolicyId == policyId }
    }

    func isExpanded(_ policy: CheckpointPolicyEvent) -> Bool {
        expandedPolicyIds.contains(policy.id)
    }

    func togglePolicy(_ policy: CheckpointPolicyEvent) {
        if expandedPolicyIds.contains(policy.id) {
            expandedPolicyIds.remove(policy.id)
        } else {
            expandedPolicyIds.insert(policy.id)
        }
    }

    func toggleCheckpointCompletion(_ checkpoint: CheckpointItem) {
        guard let index = checkpoints.firstIndex(where: { $0.id == checkpoint.id }) else { return }
        checkpoints[index].completed.toggle()
    }

    func toggleCheckpointAlert(_ checkpoint: CheckpointItem) {
        guard let index = checkpoints.firstIndex(where: { $0.id == checkpoint.id }) else { return }
        checkpoints[index].alertOn.toggle()
    }

    func presentDetail(_ checkpoint: CheckpointItem) {
        detailCheckpoint = checkpoints.first(where: { $0.id == checkpoint.id }) ?? checkpoint
    }
}
