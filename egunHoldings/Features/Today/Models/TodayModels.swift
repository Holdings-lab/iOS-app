import SwiftUI

// MARK: - Enums

enum PSPolicyStatus: String {
    case scheduled = "예정"
    case announced = "발표"
    case changed   = "변경"
    case delayed   = "지연"

    var color: Color {
        switch self {
        case .scheduled: return PSColor.electricBlue
        case .announced: return PSColor.emerald
        case .changed:   return PSColor.yellow
        case .delayed:   return PSColor.red
        }
    }
}

enum TrendDirection {
    case positive, negative, mixed

    var color: Color {
        switch self {
        case .positive: return PSColor.emerald
        case .negative: return PSColor.red
        case .mixed:    return PSColor.yellow
        }
    }

    var label: String {
        switch self {
        case .positive: return "긍정"
        case .negative: return "부정"
        case .mixed:    return "혼조"
        }
    }
}

enum PSImportance: String {
    case high   = "높음"
    case medium = "중간"
    case low    = "낮음"

    var color: Color {
        switch self {
        case .high:   return PSColor.red
        case .medium: return PSColor.yellow
        case .low:    return PSColor.gray
        }
    }
}

enum NewsRelevance {
    case high, medium, low

    var label: String {
        switch self {
        case .high:   return "중요"
        case .medium: return "보통"
        case .low:    return "참고"
        }
    }

    var color: Color {
        switch self {
        case .high:   return PSColor.electricBlue
        case .medium: return PSColor.yellow
        case .low:    return PSColor.gray
        }
    }
}

// MARK: - Core Models

struct ImpactFlow {
    let steps: [String]

    var displayText: String {
        steps.joined(separator: " → ")
    }
}

struct TodayPolicyEvent: Identifiable {
    let id: Int
    let title: String
    let institution: String
    let dDay: String
    let date: String
    let status: PSPolicyStatus
    let color: Color
    let myExposure: Int
    let relatedAssets: [String]
    let summary: String
    let direction: TrendDirection
    let evidence: [String]
    let counterEvidence: String
    let invalidationConditions: [String]
    let sources: [String]
    let verified: Bool
    let updatedAt: String
    let impactFlow: ImpactFlow
    let timelag: String
    let confidence: Int
}

struct TodayCheckpoint: Identifiable {
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

struct TodayThemeExposure {
    let theme: String
    let intensity: PSImportance
    let color: Color
}

struct TodayHolding: Identifiable {
    let id: String
    let name: String
    let ticker: String
    let category: String
    let weight: Int
    let value: Int
    let change: Double
    let exposedThemes: [TodayThemeExposure]
    let color: Color
}

struct TodayNewsItem: Identifiable {
    let id: Int
    let title: String
    let source: String
    let time: String
    let summary: String
    let relatedAssets: [String]
    let relevance: NewsRelevance
    let direction: TrendDirection
    let myAssetImpact: String
    let checkCondition: String
    let whyIgnore: String?
    var saved: Bool
    let fullText: String
}

struct TodayJudgment {
    let title: String
    let type: JudgmentType
    let myExposure: Int
    let validUntil: String
    let invalidationCondition: String
    let forEvidence: [String]
    let againstEvidence: [String]
    let deliveryPath: String
}

struct TodayExposureItem {
    let theme: String
    let pct: Int
    let color: Color
}

struct TodayPortfolioSummary {
    let totalAsset: Int
    let todayChange: Double
    let todayChangeAmt: Int
    let cashDefense: Int
    let dollarDefense: Int
    let overtradeRisk: String
    let topExposures: [TodayExposureItem]
    let riskLevel: String
}

enum TodayLoadState: Equatable {
    case idle
    case loading
    case loaded
    case usingFallback(message: String?)
}

struct TodayDashboard {
    let userAssetProfile: UserAssetProfile
    let portfolioSnapshot: PortfolioSnapshot
    let judgment: TodayJudgment
    let portfolio: TodayPortfolioSummary
    let policyEvents: [TodayPolicyEvent]
    let holdings: [TodayHolding]
    let noActionReasons: [String]
    let noActionWatchCondition: String
    let primaryCheckpointText: String
    let dataUpdatedAt: String
    let dataSources: [String]
    let aiSummaryStatus: String

    var topPolicy: TodayPolicyEvent? {
        policyEvents.max { $0.myExposure < $1.myExposure }
    }
}

struct TodayDecisionLane: Identifiable {
    let id: String
    let type: JudgmentType
    let title: String
    let relatedAssets: [String]
    let validUntil: String
}

// MARK: - Sheet Identity

enum TodaySheet: Identifiable {
    case settings
    case dataStatus
    case quickReason
    case saveCheckpoint
    case snooze
    case exposureTheme(TodayExposureItem)
    case policyDetail(TodayPolicyEvent)
    case policyList

    var id: String {
        switch self {
        case .settings:              return "settings"
        case .dataStatus:            return "dataStatus"
        case .quickReason:           return "quickReason"
        case .saveCheckpoint:        return "saveCheckpoint"
        case .snooze:                return "snooze"
        case .exposureTheme(let i):  return "exposure-\(i.theme)"
        case .policyDetail(let p):   return "policy-\(p.id)"
        case .policyList:            return "policyList"
        }
    }
}
