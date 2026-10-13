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

    /// UI 테스트에서 서버 호출 없이 자산 탭의 긴 종목명과 금액 레이아웃을 검증하는 고정 스냅샷.
    static let brokerBalanceSnapshot = BrokerBalanceSnapshot(
        broker: "KIS",
        environment: "MOCK",
        accountNumber: "1234567801",
        productCode: "01",
        totalEvaluationAmount: 134_820_000,
        stockEvaluationAmount: 126_420_000,
        cashAmount: 8_400_000,
        totalPurchaseAmount: 120_000_000,
        totalProfitLossAmount: 14_820_000,
        holdings: [
            BrokerHoldingSnapshot(
                symbol: "381180",
                name: "TIGER 미국필라델피아반도체나스닥",
                productType: "ETF",
                quantity: 500,
                currentPrice: nil,
                currencyCode: "KRW",
                averagePurchasePrice: 106_000,
                purchaseAmount: 53_000_000,
                evaluationAmount: 62_500_000,
                profitLossAmount: 9_500_000,
                profitLossRate: 17.9
            ),
            BrokerHoldingSnapshot(
                symbol: "QQQ",
                name: "Invesco QQQ Trust Series 1",
                productType: "ETF",
                quantity: 100,
                currentPrice: nil,
                currencyCode: "KRW",
                averagePurchasePrice: 295_000,
                purchaseAmount: 29_500_000,
                evaluationAmount: 35_000_000,
                profitLossAmount: 5_500_000,
                profitLossRate: 18.6
            ),
            BrokerHoldingSnapshot(
                symbol: "KODEX",
                name: "KODEX 미국S&P500TR",
                productType: "ETF",
                quantity: 750,
                currentPrice: nil,
                currencyCode: "KRW",
                averagePurchasePrice: 35_500,
                purchaseAmount: 26_625_000,
                evaluationAmount: 28_920_000,
                profitLossAmount: 2_295_000,
                profitLossRate: 8.6
            ),
        ],
        fetchedAt: Date(timeIntervalSince1970: 0)
    )
}
