import Foundation

struct PortfolioSnapshot: Equatable, Hashable {
    let amountText: String
    let changePercentText: String
    let insightText: String
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
