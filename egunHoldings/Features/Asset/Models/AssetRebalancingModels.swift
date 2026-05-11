import SwiftUI

enum InvestmentProfile: String, CaseIterable, Identifiable, Codable, Sendable {
    case conservative = "CONSERVATIVE"
    case balanced = "BALANCED"
    case aggressive = "AGGRESSIVE"

    nonisolated var id: String { rawValue }

    nonisolated var displayName: String {
        switch self {
        case .conservative:
            return "안정형"
        case .balanced:
            return "중립형"
        case .aggressive:
            return "공격형"
        }
    }
}

enum RebalancingAction: String, CaseIterable, Codable, Sendable {
    case buy = "BUY"
    case sell = "SELL"
    case hold = "HOLD"

    nonisolated var displayTitle: String {
        switch self {
        case .buy:
            return "매수"
        case .sell:
            return "매도"
        case .hold:
            return "유지"
        }
    }

    nonisolated var symbolName: String {
        switch self {
        case .buy:
            return "cart.badge.plus"
        case .sell:
            return "arrow.down.circle.fill"
        case .hold:
            return "pause.circle.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .buy:
            return .emerald
        case .sell:
            return .policyCoral
        case .hold:
            return .mutedForeground
        }
    }
}

enum RebalancingRecommendationFilter: String, CaseIterable, Identifiable {
    case all
    case buy
    case sell
    case hold

    nonisolated var id: String { rawValue }

    nonisolated var displayTitle: String {
        switch self {
        case .all:
            return "전체"
        case .buy:
            return "매수"
        case .sell:
            return "매도"
        case .hold:
            return "유지"
        }
    }

    nonisolated var action: RebalancingAction? {
        switch self {
        case .all:
            return nil
        case .buy:
            return .buy
        case .sell:
            return .sell
        case .hold:
            return .hold
        }
    }
}

enum RebalancingLoadState: Equatable {
    case idle
    case loading
    case loaded
    case usingFallback(message: String?)
}

struct RebalancingDashboard: Equatable {
    let userId: Int64?
    let investmentProfile: InvestmentProfile
    let investmentProfileDisplayName: String
    let dataSource: String
    let policy: RebalancingPolicy
    let summary: RebalancingSummary
    let recommendations: [RebalancingRecommendation]
    let notes: [String]
}

struct RebalancingPolicy: Equatable {
    let targetCashWeight: Double
    let rebalanceThreshold: Double
    let maxSingleAssetWeight: Double
    let minTradeAmount: Double
}

struct RebalancingSummary: Equatable {
    let totalAssetValue: Double
    let investedValue: Double
    let cash: Double
    let currentCashWeight: Double
    let targetCashWeight: Double
    let targetCashAmount: Double
    let tradeCount: Int
    let estimatedBuyAmount: Double
    let estimatedSellAmount: Double
}

struct RebalancingRecommendation: Identifiable, Equatable {
    let id: String
    let assetName: String
    let symbol: String
    let assetClass: String
    let action: RebalancingAction
    let shares: Int
    let currentPrice: Double
    let currentValue: Double
    let tradeAmount: Double
    let currentWeight: Double
    let targetWeight: Double
    let drift: Double
    let reasonCodes: [String]
    let reasonText: String
}
