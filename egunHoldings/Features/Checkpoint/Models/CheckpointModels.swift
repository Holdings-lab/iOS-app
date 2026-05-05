import SwiftUI

enum CheckpointFilter: String, CaseIterable, Identifiable {
    case all
    case today

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "전체"
        case .today: return "오늘"
        }
    }
}

struct CheckpointPolicyEvent: Identifiable {
    let id: Int
    let date: String
    let day: String
    let title: String
    let institution: String
    let color: Color
    let exposure: Int
    let isToday: Bool
    let evidence: [String]
    let counterEvidence: String
    let verified: Bool
    let updatedAt: String
    let checkpoints: [CheckpointItem]
}

struct CheckpointItem: Identifiable {
    let id: String
    let text: String
    let metric: String
    let baseline: String
    let importance: PSImportance
    var alertOn: Bool
    var completed: Bool
    let linkedPolicyId: Int
    let linkedPolicyTitle: String
    let relatedAssets: [String]
    let conditionMet: String
    let conditionNotMet: String
}

struct CheckpointDecisionItem: Identifiable {
    let id: String
    let title: String
    let reason: String
    let relatedAssets: [String]
    let validUntil: String
    let invalidationCondition: String
    let type: JudgmentType
    let color: Color
    let linkedPolicyId: Int
}
