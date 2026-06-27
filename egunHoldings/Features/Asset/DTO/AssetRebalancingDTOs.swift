import Foundation

nonisolated struct RebalancingPreviewRequestDTO: Encodable, Sendable {
    let investmentProfile: String?
    let cash: Double
    let positions: [RebalancingPreviewPositionRequestDTO]
}

nonisolated struct RebalancingPreviewPositionRequestDTO: Encodable, Sendable {
    let assetName: String
    let symbol: String
    let assetClass: String
    let quantity: Int
    let currentPrice: Double
    let locked: Bool?
}

nonisolated struct InvestmentProfileResponseDTO: Decodable {
    let userId: Int64?
    let investmentProfile: String?
    let displayName: String?
}

nonisolated struct RebalancingResponseDTO: Decodable {
    let userId: Int64?
    let investmentProfile: String?
    let investmentProfileDisplayName: String?
    let dataSource: String?
    let policy: RebalancingPolicyDTO?
    let summary: RebalancingSummaryDTO?
    let recommendations: [RebalancingRecommendationDTO]?
    let notes: [String]?

    func toDomain(fallback: RebalancingDashboard? = nil) -> RebalancingDashboard {
        let fallback = fallback ?? MockAssetRebalancingRepository.makeDashboard()
        let profile = InvestmentProfile(rawValue: investmentProfile ?? "") ?? fallback.investmentProfile

        return RebalancingDashboard(
            userId: userId ?? fallback.userId,
            investmentProfile: profile,
            investmentProfileDisplayName: investmentProfileDisplayName ?? profile.displayName,
            dataSource: dataSource ?? fallback.dataSource,
            policy: policy?.toDomain(fallback: fallback.policy) ?? fallback.policy,
            summary: summary?.toDomain(fallback: fallback.summary) ?? fallback.summary,
            recommendations: mappedRecommendations(fallback: fallback.recommendations),
            notes: notes ?? fallback.notes
        )
    }

    private func mappedRecommendations(fallback: [RebalancingRecommendation]) -> [RebalancingRecommendation] {
        guard let recommendations else { return fallback }

        return recommendations.enumerated().map { index, dto in
            dto.toDomain(index: index, fallback: fallback[safe: index])
        }
    }
}

nonisolated struct RebalancingPolicyDTO: Decodable {
    let targetCashWeight: Double?
    let rebalanceThreshold: Double?
    let maxSingleAssetWeight: Double?
    let minTradeAmount: Double?

    func toDomain(fallback: RebalancingPolicy) -> RebalancingPolicy {
        RebalancingPolicy(
            targetCashWeight: targetCashWeight ?? fallback.targetCashWeight,
            rebalanceThreshold: rebalanceThreshold ?? fallback.rebalanceThreshold,
            maxSingleAssetWeight: maxSingleAssetWeight ?? fallback.maxSingleAssetWeight,
            minTradeAmount: minTradeAmount ?? fallback.minTradeAmount
        )
    }
}

nonisolated struct RebalancingSummaryDTO: Decodable {
    let totalAssetValue: Double?
    let investedValue: Double?
    let cash: Double?
    let currentCashWeight: Double?
    let targetCashWeight: Double?
    let targetCashAmount: Double?
    let tradeCount: Int?
    let estimatedBuyAmount: Double?
    let estimatedSellAmount: Double?

    func toDomain(fallback: RebalancingSummary) -> RebalancingSummary {
        RebalancingSummary(
            totalAssetValue: totalAssetValue ?? fallback.totalAssetValue,
            investedValue: investedValue ?? fallback.investedValue,
            cash: cash ?? fallback.cash,
            currentCashWeight: currentCashWeight ?? fallback.currentCashWeight,
            targetCashWeight: targetCashWeight ?? fallback.targetCashWeight,
            targetCashAmount: targetCashAmount ?? fallback.targetCashAmount,
            tradeCount: tradeCount ?? fallback.tradeCount,
            estimatedBuyAmount: estimatedBuyAmount ?? fallback.estimatedBuyAmount,
            estimatedSellAmount: estimatedSellAmount ?? fallback.estimatedSellAmount
        )
    }
}

nonisolated struct RebalancingRecommendationDTO: Decodable {
    let assetName: String?
    let symbol: String?
    let assetClass: String?
    let action: String?
    let shares: Int?
    let currentPrice: Double?
    let currentValue: Double?
    let tradeAmount: Double?
    let currentWeight: Double?
    let targetWeight: Double?
    let drift: Double?
    let reasonCodes: [String]?
    let reasonText: String?

    func toDomain(index: Int, fallback: RebalancingRecommendation?) -> RebalancingRecommendation {
        let fallback = fallback ?? MockAssetRebalancingRepository.makeRecommendation(index: index)
        let symbol = symbol ?? fallback.symbol
        let action = RebalancingAction(rawValue: action ?? "") ?? fallback.action

        return RebalancingRecommendation(
            id: "\(symbol)-\(action.rawValue)-\(index)",
            assetName: assetName ?? fallback.assetName,
            symbol: symbol,
            assetClass: assetClass ?? fallback.assetClass,
            action: action,
            shares: shares ?? fallback.shares,
            currentPrice: currentPrice ?? fallback.currentPrice,
            currentValue: currentValue ?? fallback.currentValue,
            tradeAmount: tradeAmount ?? fallback.tradeAmount,
            currentWeight: currentWeight ?? fallback.currentWeight,
            targetWeight: targetWeight ?? fallback.targetWeight,
            drift: drift ?? fallback.drift,
            reasonCodes: reasonCodes ?? fallback.reasonCodes,
            reasonText: reasonText ?? fallback.reasonText
        )
    }
}

private extension Array {
    nonisolated subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
