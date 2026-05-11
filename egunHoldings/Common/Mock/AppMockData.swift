import Foundation

struct AppMockData {
    static let portfolioSnapshot = PortfolioSnapshot(
        amountText: "₩134,820,000",
        changePercentText: "+1.2%",
        insightText: "오늘 자산이 1.2% 올랐어요. 정책 영향은 관리 가능한 범위에 있습니다."
    )

    static let userAssetProfile = UserAssetProfile(
        holdings: [
            UserHoldingItem(id: 1, name: "SOXX", category: .etf, weightPercent: 18),
            UserHoldingItem(id: 2, name: "ICLN", category: .etf, weightPercent: 12),
            UserHoldingItem(id: 3, name: "KODEX 은행 ETF", category: .etf, weightPercent: 9),
            UserHoldingItem(id: 4, name: "정기예금", category: .depositSavings, weightPercent: 34),
            UserHoldingItem(id: 5, name: "주택담보대출", category: .loan, weightPercent: 27)
        ]
    )
}
