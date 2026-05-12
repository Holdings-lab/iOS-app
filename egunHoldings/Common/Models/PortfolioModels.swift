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

    var displayName: String {
        switch self {
        case .etf:
            return "ETF"
        case .depositSavings:
            return "예적금"
        case .loan:
            return "대출"
        case .stock:
            return "주식"
        }
    }
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
