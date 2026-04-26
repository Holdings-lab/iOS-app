import Foundation

struct BrokerHoldingSnapshot: Codable, Equatable, Sendable {
    let symbol: String
    let name: String
    let quantity: Int
    let averagePurchasePrice: Int
    let purchaseAmount: Int
    let evaluationAmount: Int
    let profitLossAmount: Int
    let profitLossRate: Double
}

struct BrokerBalanceSnapshot: Codable, Equatable, Sendable {
    let broker: String
    let environment: String
    let accountNumber: String
    let productCode: String
    let totalEvaluationAmount: Int
    let stockEvaluationAmount: Int
    let cashAmount: Int
    let totalPurchaseAmount: Int
    let totalProfitLossAmount: Int
    let holdings: [BrokerHoldingSnapshot]
    let fetchedAt: Date
}

private struct BrokerWeightEntry {
    let name: String
    let category: AssetCategory
    let amount: Int
}

extension BrokerBalanceSnapshot {
    func toUserAssetProfile() -> UserAssetProfile {
        let totalAmount = max(totalEvaluationAmount, holdings.reduce(cashAmount) { partialResult, item in
            partialResult + item.evaluationAmount
        })

        guard totalAmount > 0 else {
            return UserAssetProfile(holdings: [])
        }

        var entries = holdings
            .filter { $0.evaluationAmount > 0 }
            .map { BrokerWeightEntry(name: $0.name, category: .stock, amount: $0.evaluationAmount) }

        if cashAmount > 0 {
            entries.append(BrokerWeightEntry(name: "예수금", category: .depositSavings, amount: cashAmount))
        }

        let weights = entries.normalizedWeights(total: totalAmount)

        let holdingItems = zip(entries, weights).enumerated().map { index, pair in
            let entry = pair.0
            let weight = pair.1
            return UserHoldingItem(
                id: index + 1,
                name: entry.name,
                category: entry.category,
                weightPercent: weight
            )
        }

        return UserAssetProfile(holdings: holdingItems)
    }

    func toPortfolioSnapshot() -> PortfolioSnapshot {
        let formattedAmount = Self.currencyFormatter.string(from: NSNumber(value: totalEvaluationAmount)) ?? "₩0"

        let changeText: String
        if totalPurchaseAmount > 0 {
            let percent = Double(totalProfitLossAmount) / Double(totalPurchaseAmount) * 100
            let sign = percent > 0 ? "+" : ""
            changeText = String(format: "%@%.1f%%", sign, percent)
        } else {
            changeText = "0.0%"
        }

        let insightText: String
        switch holdings.count {
        case 0:
            insightText = "현재 모의계좌에는 종목 보유 없이 예수금만 있어요."
        case 1:
            let topHolding = holdings[0]
            insightText = "\(topHolding.name) 1종목과 예수금 기준으로 내 자산 현황을 불러왔어요."
        default:
            let sorted = holdings.sorted { $0.evaluationAmount > $1.evaluationAmount }
            let leadName = sorted.first?.name ?? "주요 종목"
            insightText = "\(leadName)을 포함한 \(holdings.count)개 종목 기준으로 내 자산 현황을 불러왔어요."
        }

        return PortfolioSnapshot(
            amountText: formattedAmount,
            changePercentText: changeText,
            insightText: insightText
        )
    }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "KRW"
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}

private extension Array where Element == BrokerWeightEntry {
    func normalizedWeights(total: Int) -> [Int] {
        guard !isEmpty else { return [] }
        guard total > 0 else { return [Int](repeating: 0, count: count) }

        let rawWeights = map { Double($0.amount) / Double(total) * 100 }
        var integerWeights = rawWeights.map { Int(floor($0)) }
        let remainder = Swift.max(0, 100 - integerWeights.reduce(0, +))

        let rankedFractions = rawWeights.enumerated()
            .map { ($0.offset, $0.element - floor($0.element)) }
            .sorted { left, right in
                left.1 > right.1
            }

        for item in rankedFractions.prefix(remainder) {
            integerWeights[item.0] += 1
        }

        return integerWeights
    }
}
