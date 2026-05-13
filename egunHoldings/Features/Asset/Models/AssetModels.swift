import SwiftUI

enum AssetSegment: String, CaseIterable, Identifiable {
    case overview
    case rebalance

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .overview:
            return AppVocabulary.Asset.policyExposureTab
        case .rebalance:
            return AppVocabulary.Asset.rebalancingTab
        }
    }
}

enum AssetNavigationDestination: Hashable, Identifiable {
    case overallPolicy
    case account(Int)

    var id: String {
        switch self {
        case .overallPolicy:
            return "overall-policy"
        case .account(let accountId):
            return "account-\(accountId)"
        }
    }
}

struct AssetDashboard {
    let totalAssetAmount: String
    let totalProfitSummary: String
    let totalProfitColor: Color
    let weeklyAdjustmentNotice: AssetAdjustmentNotice?
    let accounts: [AssetAccount]
    let exposureMetrics: [AssetExposureMetric]
    let defenseMetrics: [AssetDefenseMetric]
    let holdingRows: [AssetHoldingRow]
    let hiddenBets: [HiddenAssetBet]
    let rebalanceModes: [AssetRebalanceModeRow]
    let constraints: [AssetConstraint]
    let scenarios: [AssetScenarioChange]
}

struct AssetAdjustmentNotice: Identifiable {
    let id: Int
    let title: String
    let summary: String
    let count: Int
    let color: Color
}

struct AssetAccount: Identifiable {
    let id: Int
    let brokerName: String
    let accountName: String
    let accountNumber: String
    let totalAmount: String
    let cashAmount: String
    let profitSummary: String
    let profitColor: Color
    let symbol: String
    let tint: Color
    let policyTags: [AssetPolicyTag]
    let holdings: [AssetHoldingRow]
    let exposureMetrics: [AssetExposureMetric]
    let hiddenBets: [HiddenAssetBet]
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
