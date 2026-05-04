import SwiftUI

struct InvestorProfile: Equatable {
    let dateText: String
    let greeting: String
    let initials: String
}

struct HomePolicyEvent: Identifiable {
    let id: Int
    let date: String
    let day: String
    let title: String
    let symbol: String
    let color: Color
}

struct PortfolioSnapshot: Equatable, Hashable {
    let amountText: String
    let changePercentText: String
    let insightText: String
}

struct PortfolioTrendPoint: Identifiable {
    let id: Int
    let dateLabel: String
    let value: Double
}

struct PortfolioMarker: Identifiable {
    let id: Int
    let dateLabel: String
    let title: String
    let value: Double
}

enum ImpactSentiment: String {
    case positive = "긍정"
    case neutral = "중립"
    case caution = "주의"

    var emoji: String {
        switch self {
        case .positive:
            return "✅"
        case .neutral:
            return "➖"
        case .caution:
            return "⚠️"
        }
    }

    var color: Color {
        switch self {
        case .positive:
            return .emerald
        case .neutral:
            return .electricBlue
        case .caution:
            return .policyCoral
        }
    }
}

struct WalletImpactItem: Identifiable {
    let id: Int
    let title: String
    let message: String
    let symbol: String
}

struct KeyTermItem: Identifiable {
    let id: Int
    let term: String
    let plainDescription: String
}

struct PolicyEventDetail: Identifiable {
    let id: Int
    let summaryBullets: [String]
    let sentiment: ImpactSentiment
    let impactScore: Int
    let impactSummary: String
    let walletImpacts: [WalletImpactItem]
    let keyTerms: [KeyTermItem]
    let watchPoint: String
}

enum AssetCategory: String, Codable {
    case etf
    case depositSavings
    case loan
    case stock
}

struct UserHoldingItem: Identifiable, Codable, Equatable {
    let id: Int
    let name: String
    let category: AssetCategory
    let weightPercent: Int
}

struct UserAssetProfile: Codable, Equatable {
    let holdings: [UserHoldingItem]
}

struct PersonalizationBriefing {
    let headline: String
    let bullets: [String]
}
