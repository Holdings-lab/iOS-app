import SwiftUI

struct PolicyActionQueueItem: Identifiable {
    let id: Int
    let dateRange: String
    let title: String
    let summary: String
    let recommendedAction: String
    let isHoldingMatched: Bool
    let color: Color
}

struct PolicyETFMatch: Identifiable {
    let id: Int
    let policy: String
    let etf: String
    let score: Int
    let history: String
    let symbol: String
    let color: Color
}

struct SimulatorETFAllocation: Identifiable {
    enum PriceCurrency {
        case krw
        case usd
    }

    let id: Int
    let ticker: String
    let name: String
    let currentWeight: Double
    let recommendedWeight: Double
    let expectedMonthlyReturn: Double
    let heldShares: Double
    let unitPrice: Double
    let unitPriceCurrency: PriceCurrency
    let color: Color
}

struct SimulatorContent: Equatable {
    let title: String
    let subtitle: String
    let disclaimer: String
    let ctaTitle: String
    let etfPoolAmount: Double
    let feeRatePercent: Double
    let cashKRWAmount: Double
    let cashUSDAmount: Double
}

struct RebalancingScoreConfig {
    struct PercentRange {
        let min: Double
        let max: Double
    }

    let singleETFWeightCapPercent: Double
    let minimumCashReservePercent: Double
    let recommendedCashReserveRange: PercentRange
    let reserveExpectedMonthlyReturn: Double

    let baseDownturnPenalty: Double
    let turnoverPenaltyPerPercent: Double
    let concentrationPenaltyStart: Double
    let concentrationPenaltyDivisor: Double
    let cashDeficitPenaltyPerPercent: Double

    let netBaseScore: Double
    let netImprovementWeight: Double
    let turnoverPenaltyStart: Double
    let turnoverPenaltyWeight: Double
    let netConcentrationPenaltyStart: Double
    let netConcentrationPenaltyDivisor: Double
    let netCashDeficitPenaltyPerPercent: Double

    let diversificationGoodMin: Int
    let diversificationWarningMin: Int
    let netEffectGoodMin: Int
    let netEffectWarningMin: Int
}
