import SwiftUI

enum PolicyActionLane: String, CaseIterable, Identifiable {
    case increase = "늘리기"
    case reduce = "줄이기"
    case hedge = "방어 비중 점검"
    case wait = "기다리기"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .increase:
            return .emerald
        case .reduce:
            return .policyCoral
        case .hedge:
            return .policyAmber
        case .wait:
            return .electricBlue
        }
    }

    var symbol: String {
        switch self {
        case .increase:
            return "arrow.up.forward"
        case .reduce:
            return "arrow.down.forward"
        case .hedge:
            return "shield.lefthalf.filled"
        case .wait:
            return "pause.circle.fill"
        }
    }
}

struct PolicyActionOption: Identifiable {
    let id: Int
    let lane: PolicyActionLane
    let title: String
    let reason: String
    let affectedAssets: [String]
    let effectiveWindow: String
    let recommendation: String
    let meta: PolicyCardMeta
}

struct TransmissionMatchFactor: Identifiable {
    let id: Int
    let title: String
    let detail: String
}

struct PolicyTransmissionMatch: Identifiable {
    let id: Int
    let policyTitle: String
    let assetName: String
    let summary: String
    let factors: [TransmissionMatchFactor]
    let meta: PolicyCardMeta
}

struct PolicyScenarioSnapshot: Identifiable {
    let id: Int
    let title: String
    let portfolioBias: String
    let targetPositioning: String
    let note: String
    let accentColor: Color
}

struct DecisionEvidenceLedger: Identifiable {
    let id: Int
    let title: String
    let supportingEvidence: [String]
    let counterEvidence: String
    let sourceText: String
    let updatedAtText: String
    let expiresAtText: String
}

struct SignalDecisionDashboard {
    let actionOptions: [PolicyActionOption]
    let transmissionMatches: [PolicyTransmissionMatch]
    let scenarios: [PolicyScenarioSnapshot]
    let ledgers: [DecisionEvidenceLedger]
}
