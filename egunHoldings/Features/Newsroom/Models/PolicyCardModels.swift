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
