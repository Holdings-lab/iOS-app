import SwiftUI

struct PolicyExposureSummaryItem: Identifiable {
    let id: Int
    let title: String
    let exposurePercent: Int
    let summary: String
    let color: Color
}

struct PolicyExposureChip: Identifiable {
    let id: Int
    let title: String
    let exposureText: String
    let color: Color
}

struct HoldingPolicyExposureRow: Identifiable {
    let id: Int
    let holdingName: String
    let holdingWeightPercent: Int
    let exposures: [PolicyExposureChip]
    let note: String
}

struct HiddenPolicyBet: Identifiable {
    let id: Int
    let title: String
    let overlapPercent: Int
    let summary: String
    let color: Color
}

struct DefenseReadinessItem: Identifiable {
    let id: Int
    let title: String
    let value: String
    let summary: String
    let color: Color
}

enum RebalanceMode: String, CaseIterable, Identifiable {
    case defense = "방어형"
    case balanced = "균형형"
    case opportunity = "기회형"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .defense:
            return "현금과 달러를 더 남기는 보수적 모드"
        case .balanced:
            return "과도한 매매 없이 정책 노출을 정리하는 기본 모드"
        case .opportunity:
            return "정책 수혜 섹터 비중을 조금 더 늘리는 모드"
        }
    }
}

struct RebalanceConstraint: Identifiable {
    let id: Int
    let title: String
    let value: String
}

struct RebalanceScenarioVariant: Identifiable {
    let id: Int
    let title: String
    let suggestedChange: String
    let note: String
    let color: Color
}

struct RebalanceExecutionStep: Identifiable {
    let id: Int
    let title: String
    let detail: String
}

struct NoTradeZoneNote {
    let title: String
    let summary: String
    let bullets: [String]
}

struct RebalanceWhyCard {
    let supportingLines: [String]
    let opposingLine: String
    let projectedExposureChange: String
}

struct AssetExposureDashboard {
    let summaryItems: [PolicyExposureSummaryItem]
    let holdingRows: [HoldingPolicyExposureRow]
    let hiddenBets: [HiddenPolicyBet]
    let defenseReadiness: [DefenseReadinessItem]
    let noTradeZone: NoTradeZoneNote
    let constraints: [RebalanceConstraint]
    let scenarioVariants: [RebalanceScenarioVariant]
    let executionPlan: [RebalanceExecutionStep]
    let whyCard: RebalanceWhyCard
}
