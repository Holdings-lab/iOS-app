import Foundation

struct AppMockData {
    static let portfolioSnapshot = PortfolioSnapshot(
        amountText: "₩13,550,000",
        changePercentText: "+1.2%",
        insightText: "오늘 자산이 1.2% 올랐어요. 주로 반도체 보조금 기대감으로 SOXX가 끌어올렸어요."
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
