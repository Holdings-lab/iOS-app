import SwiftUI

enum PolicyLifecycleState: String {
    case scheduled = "예정"
    case announced = "발표"
    case passed = "통과"
    case delayed = "지연"
    case canceled = "무산"

    var color: Color {
        switch self {
        case .scheduled:
            return .brand
        case .announced:
            return .warning
        case .passed:
            return .success
        case .delayed:
            return .up
        case .canceled:
            return .textQuaternary
        }
    }
}

enum PolicyPortfolioDirection: String {
    case positive = "내 자산 +"
    case negative = "내 자산 -"
    case mixed = "혼합"

    var color: Color {
        switch self {
        case .positive:
            return .success
        case .negative:
            return .up
        case .mixed:
            return .warning
        }
    }
}

enum PolicyImpactDelay: String {
    case immediate = "즉시"
    case oneWeek = "1주"
    case oneMonth = "1개월"
    case threeMonths = "3개월"
}

enum PolicyJudgmentAction: String {
    case increase = "비중 확대 검토"
    case reduce = "줄이기"
    case hedge = "방어 비중 점검"
    case wait = "기다리기"

    var color: Color {
        switch self {
        case .increase:
            return .success
        case .reduce:
            return .brand
        case .hedge:
            return .up
        case .wait:
            return .warning
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

struct PolicyUpdateSummary {
    let updatedAtText: String
    let sourceText: String
    let reviewText: String
}

struct PolicyCardMeta {
    let status: PolicyLifecycleState
    let direction: PolicyPortfolioDirection
    let exposurePercent: Int
    let delay: PolicyImpactDelay
    let confidence: Int
    let supportingEvidence: [String]
    let counterEvidence: String
    let invalidationCondition: String
    let updateSummary: PolicyUpdateSummary
}
