import SwiftUI

enum AssetSegment: String, CaseIterable, Identifiable {
    case overview = "정책 노출도"
    case rebalance = "시나리오 리밸런싱"

    var id: String { rawValue }
}

struct AssetDashboard {
    let exposureMetrics: [AssetExposureMetric]
    let defenseMetrics: [AssetDefenseMetric]
    let holdingRows: [AssetHoldingRow]
    let hiddenBets: [HiddenAssetBet]
    let rebalanceModes: [AssetRebalanceModeRow]
    let constraints: [AssetConstraint]
    let scenarios: [AssetScenarioChange]
}

struct AssetExposureMetric: Identifiable {
    let id: Int
    let title: String
    let percent: Int
    let symbol: String
    let color: Color
    let trend: AssetTrend
}

enum AssetTrend {
    case up
    case stable
    case down

    var symbol: String {
        switch self {
        case .up:
            return "arrow.up.right"
        case .stable:
            return "minus"
        case .down:
            return "arrow.down.right"
        }
    }

    var color: Color {
        switch self {
        case .up:
            return .emerald
        case .stable:
            return .mutedForeground
        case .down:
            return .policyCoral
        }
    }
}

struct AssetDefenseMetric: Identifiable {
    let id: Int
    let title: String
    let value: String
    let color: Color
}

struct AssetHoldingRow: Identifiable {
    let id: Int
    let name: String
    let weight: String
    let amount: String
    let tags: [AssetPolicyTag]
}

struct AssetPolicyTag: Identifiable {
    let id: Int
    let title: String
    let color: Color
}

struct HiddenAssetBet: Identifiable {
    let id: Int
    let title: String
    let assets: String
    let percent: String
    let note: String
    let color: Color
}

struct AssetRebalanceModeRow: Identifiable {
    let id: Int
    let title: String
    let description: String
    let symbol: String
    let color: Color
}

struct AssetConstraint: Identifiable {
    let id: Int
    let title: String
    let value: String
}

struct AssetScenarioChange: Identifiable {
    let id: Int
    let title: String
    let change: String
    let detail: String
    let color: Color
}
