import SwiftUI

struct HomePolicyJudgment {
    let action: PolicyJudgmentAction
    let relevanceSummary: String
    let keyReason: String
    let thresholdSummary: String
    let validUntilSummary: String
    let failureSummary: String
}

struct HomeImpactPolicy: Identifiable {
    let id: Int
    let title: String
    let dDayText: String
    let summary: String
    let actionHint: String
    let judgment: HomePolicyJudgment
    let meta: PolicyCardMeta
    let transmissionPath: [PolicyTransmissionStep]
    let checkpoints: [WeeklyPolicyCheckpoint]
    let alerts: [String]
}

struct PolicyTransmissionStep: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let symbol: String
    let color: Color
}

enum PolicyBriefingPriority: Equatable {
    case mustRead
    case safeToIgnore

    var title: String {
        switch self {
        case .mustRead:
            return "꼭 봐야 해요"
        case .safeToIgnore:
            return "지금은 넘겨도 돼요"
        }
    }

    var color: Color {
        switch self {
        case .mustRead:
            return .electricBlue
        case .safeToIgnore:
            return .mutedForeground
        }
    }
}

struct PolicyBriefingItem: Identifiable {
    let id: Int
    let title: String
    let relatedPolicy: String
    let reason: String
    let priority: PolicyBriefingPriority
}

struct PortfolioImpactDriver: Identifiable {
    let id: Int
    let title: String
    let sharePercent: Int
    let summary: String
    let symbol: String
    let color: Color
}

enum PolicyCheckpointCategory: String {
    case policy
    case market
}

struct WeeklyPolicyCheckpoint: Identifiable {
    let id: Int
    let title: String
    let metric: String
    let threshold: String
    let whyItMatters: String
    let category: PolicyCheckpointCategory?

    init(
        id: Int,
        title: String,
        metric: String,
        threshold: String,
        whyItMatters: String,
        category: PolicyCheckpointCategory? = nil
    ) {
        self.id = id
        self.title = title
        self.metric = metric
        self.threshold = threshold
        self.whyItMatters = whyItMatters
        self.category = category
    }
}

struct HomePolicyDashboard {
    let topPolicies: [HomeImpactPolicy]
    let policyBriefings: [PolicyBriefingItem]
    let changeDrivers: [PortfolioImpactDriver]
    let checkpoints: [WeeklyPolicyCheckpoint]

    var featuredPolicy: HomeImpactPolicy? {
        topPolicies.first
    }

    var secondaryPolicies: [HomeImpactPolicy] {
        Array(topPolicies.dropFirst().prefix(2))
    }
}
