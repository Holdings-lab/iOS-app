import Foundation

nonisolated struct MockAssetRebalancingRepository: AssetRebalancingRepositoryProtocol {
    func fetchRebalancing(
        userId: Int64?,
        brokerBalanceSnapshot _: BrokerBalanceSnapshot?
    ) async throws -> RebalancingDashboard {
        Self.makeDashboard(userId: userId)
    }

    static func makeDashboard(userId: Int64? = nil) -> RebalancingDashboard {
        RebalancingDashboard(
            userId: userId,
            investmentProfile: .balanced,
            investmentProfileDisplayName: "중립형",
            dataSource: "MOCK",
            policy: RebalancingPolicy(
                targetCashWeight: 0.1,
                rebalanceThreshold: 0.05,
                maxSingleAssetWeight: 0.25,
                minTradeAmount: 10_000
            ),
            summary: RebalancingSummary(
                totalAssetValue: 38_297_509,
                investedValue: 36_690_133,
                cash: 1_607_376,
                currentCashWeight: 0.042,
                targetCashWeight: 0.1,
                targetCashAmount: 3_829_751,
                tradeCount: 2,
                estimatedBuyAmount: 450_000,
                estimatedSellAmount: 2_650_000
            ),
            recommendations: [
                makeRecommendation(
                    index: 0,
                    assetName: "나스닥 성장주 ETF",
                    symbol: "QQQ",
                    assetClass: "GROWTH",
                    action: .buy,
                    shares: 3,
                    currentPrice: 150_000,
                    currentValue: 3_000_000,
                    tradeAmount: 450_000,
                    currentWeight: 0.21,
                    targetWeight: 0.25,
                    drift: 0.04,
                    reasonCodes: [
                        "ONBOARDING_PROFILE_APPLIED",
                        "TARGET_WEIGHT_CALCULATED",
                        "UNDER_TARGET_WEIGHT"
                    ],
                    reasonText: "중립형 정책 기준으로 나스닥 성장주 ETF의 현재 비중은 21.0%, 목표 비중은 25.0%입니다. 목표보다 낮아 3주 매수를 제안합니다."
                ),
                makeRecommendation(
                    index: 1,
                    assetName: "엔비디아",
                    symbol: "NVDA",
                    assetClass: "SEMICONDUCTOR",
                    action: .sell,
                    shares: 2,
                    currentPrice: 1_325_000,
                    currentValue: 7_256_929,
                    tradeAmount: 2_650_000,
                    currentWeight: 0.24,
                    targetWeight: 0.17,
                    drift: -0.07,
                    reasonCodes: [
                        "DRIFT_EXCEEDS_THRESHOLD",
                        "OVER_TARGET_WEIGHT",
                        "EXCEEDS_SINGLE_ASSET_LIMIT"
                    ],
                    reasonText: "반도체 노출과 현금 비중을 함께 맞추기 위해 엔비디아 2주 매도를 제안합니다. 매도 후 목표 비중과 현금 비중에 더 가까워집니다."
                ),
                makeRecommendation(
                    index: 2,
                    assetName: "장기채 ETF",
                    symbol: "BOND",
                    assetClass: "DEFENSIVE",
                    action: .hold,
                    shares: 0,
                    currentPrice: 100_000,
                    currentValue: 1_000_000,
                    tradeAmount: 0,
                    currentWeight: 0.2,
                    targetWeight: 0.2,
                    drift: 0,
                    reasonCodes: [
                        "TARGET_WEIGHT_CALCULATED",
                        "DRIFT_WITHIN_THRESHOLD"
                    ],
                    reasonText: "현재 비중과 목표 비중 차이가 허용 범위 안에 있어 이번 리밸런싱에서는 유지합니다."
                )
            ],
            notes: [
                "매수/매도 수량은 정수 주식 단위와 최소 거래 금액을 반영해 계산했습니다.",
                "실계좌 보유 종목이 연결되면 현재 수량, 현재 가격, 현금 기준으로 미리보기를 갱신합니다."
            ]
        )
    }

    static func makeRecommendation(index: Int) -> RebalancingRecommendation {
        makeRecommendation(
            index: index,
            assetName: "자산 \(index + 1)",
            symbol: "ASSET\(index + 1)",
            assetClass: "CORE",
            action: .hold,
            shares: 0,
            currentPrice: 0,
            currentValue: 0,
            tradeAmount: 0,
            currentWeight: 0,
            targetWeight: 0,
            drift: 0,
            reasonCodes: ["TARGET_WEIGHT_CALCULATED"],
            reasonText: "목표 비중 계산 결과 유지가 적합합니다."
        )
    }

    static func makeRecommendation(
        index: Int,
        assetName: String,
        symbol: String,
        assetClass: String,
        action: RebalancingAction,
        shares: Int,
        currentPrice: Double,
        currentValue: Double,
        tradeAmount: Double,
        currentWeight: Double,
        targetWeight: Double,
        drift: Double,
        reasonCodes: [String],
        reasonText: String
    ) -> RebalancingRecommendation {
        RebalancingRecommendation(
            id: "\(symbol)-\(action.rawValue)-\(index)",
            assetName: assetName,
            symbol: symbol,
            assetClass: assetClass,
            action: action,
            shares: shares,
            currentPrice: currentPrice,
            currentValue: currentValue,
            tradeAmount: tradeAmount,
            currentWeight: currentWeight,
            targetWeight: targetWeight,
            drift: drift,
            reasonCodes: reasonCodes,
            reasonText: reasonText
        )
    }
}
