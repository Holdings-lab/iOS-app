import Foundation
import Combine
import SwiftUI

final class SignalViewModel: ObservableObject {
    @Published private var targetWeights: [Int: Double] = [:]
    @Published private(set) var usdKrwRate: Double
    @Published private(set) var exchangeRateUpdatedAt: Date
    @Published private(set) var isExchangeRateLoading: Bool = false

    let actionQueue: [PolicyActionQueueItem]
    let matches: [PolicyETFMatch]
    let simulatorAllocations: [SimulatorETFAllocation]
    let simulator: SimulatorContent
    let rebalancingConfig: RebalancingScoreConfig
    let decisionDashboard: SignalDecisionDashboard

    private let currentWeights: [Int: Double]
    private let exchangeRateProvider: ExchangeRateProviding

    var maxSingleWeightCap: Double {
        rebalancingConfig.singleETFWeightCapPercent
    }

    init(
        repository: SignalRepositoryProtocol = MockSignalRepository(),
        exchangeRateProvider: ExchangeRateProviding = LiveExchangeRateProvider(),
        initialUSDKRWRate: Double = 1_375
    ) {
        actionQueue = repository.fetchActionQueue()
        matches = repository.fetchMatches()
        simulatorAllocations = repository.fetchSimulatorAllocations()
        simulator = repository.fetchSimulatorContent()
        rebalancingConfig = repository.fetchRebalancingScoreConfig()
        decisionDashboard = SignalDecisionMockData.dashboard
        self.exchangeRateProvider = exchangeRateProvider
        usdKrwRate = initialUSDKRWRate
        exchangeRateUpdatedAt = Date()

        let initial = Dictionary(
            uniqueKeysWithValues: simulatorAllocations.map { ($0.id, $0.currentWeight) }
        )
        currentWeights = SignalViewModel.sanitized(
            weights: initial,
            allocations: simulatorAllocations,
            maxSingleWeightCap: rebalancingConfig.singleETFWeightCapPercent
        )
        targetWeights = currentWeights

        refreshExchangeRate()
    }

    func targetWeight(for id: Int) -> Double {
        targetWeights[id] ?? 0
    }

    func updateTargetWeight(for id: Int, to newValue: Double) {
        guard simulatorAllocations.contains(where: { $0.id == id }) else { return }

        let clamped = min(max(newValue, 0), maxSingleWeightCap)
        let otherTotal = simulatorAllocations
            .map(\.id)
            .filter { $0 != id }
            .reduce(0.0) { $0 + (targetWeights[$1] ?? 0) }
        let allowedForSelected = max(0, 100 - otherTotal)

        var draft = targetWeights
        draft[id] = min(clamped, allowedForSelected)
        targetWeights = sanitized(weights: draft)
    }

    func applyRecommendedAllocation() {
        targetWeights = sanitized(
            weights: Dictionary(
                uniqueKeysWithValues: simulatorAllocations.map { ($0.id, $0.recommendedWeight) }
            )
        )
    }

    func resetToCurrentAllocation() {
        targetWeights = currentWeights
    }

    func refreshExchangeRate() {
        guard !isExchangeRateLoading else { return }
        isExchangeRateLoading = true

        Task { [weak self] in
            guard let self else { return }

            do {
                let quote = try await exchangeRateProvider.fetchUSDKRW()
                await MainActor.run {
                    self.usdKrwRate = quote.usdToKrw
                    self.exchangeRateUpdatedAt = quote.fetchedAt
                    self.isExchangeRateLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isExchangeRateLoading = false
                }
            }
        }
    }

    var exchangeRateText: String {
        "1 USD = \(currencyText(usdKrwRate))"
    }

    var exchangeRateUpdatedText: String {
        "업데이트 \(Self.timeFormatter.string(from: exchangeRateUpdatedAt))"
    }

    var totalTargetWeight: Double {
        simulatorAllocations.reduce(0) { $0 + targetWeight(for: $1.id) }
    }

    var totalETFWeightText: String {
        String(format: "%.0f", totalTargetWeight)
    }

    var cashReserveWeight: Double {
        max(0, 100 - totalTargetWeight)
    }

    var currentCashReserveWeight: Double {
        max(0, 100 - currentWeights.values.reduce(0, +))
    }

    var cashReserveWeightText: String {
        String(format: "%.0f", cashReserveWeight)
    }

    var minimumCashReserveText: String {
        String(format: "%.0f", rebalancingConfig.minimumCashReservePercent)
    }

    var recommendedCashReserveRangeText: String {
        let range = rebalancingConfig.recommendedCashReserveRange
        return "\(Int(range.min))~\(Int(range.max))"
    }

    var currentCashHoldingValueKRW: Double {
        simulator.cashKRWAmount + (simulator.cashUSDAmount * usdKrwRate)
    }

    var currentCashHoldingAmountText: String {
        currencyText(currentCashHoldingValueKRW)
    }

    var currentCashBreakdownText: String {
        let usdKrwAmount = simulator.cashUSDAmount * usdKrwRate
        return "원화 현금 \(currencyText(simulator.cashKRWAmount)) · 달러 현금 \(usdCurrencyText(simulator.cashUSDAmount)) (≈ \(currencyText(usdKrwAmount)))"
    }

    var targetCashHoldingValueKRW: Double {
        portfolioReferenceAmount * cashReserveWeight / 100
    }

    var targetCashHoldingAmountText: String {
        currencyText(targetCashHoldingValueKRW)
    }

    var expectedGrossReturn: Double {
        weightedReturn(using: targetWeights)
    }

    var currentBaselineReturn: Double {
        weightedReturn(using: currentWeights)
    }

    var grossImprovement: Double {
        expectedGrossReturn - currentBaselineReturn
    }

    var turnoverPercent: Double {
        let etfDiff = simulatorAllocations.reduce(0.0) { partial, item in
            partial + abs(targetWeight(for: item.id) - (currentWeights[item.id] ?? 0))
        }
        let cashDiff = abs(cashReserveWeight - currentCashReserveWeight)
        return (etfDiff + cashDiff) / 2.0
    }

    var estimatedTradeAmount: Double {
        portfolioReferenceAmount * turnoverPercent / 100
    }

    var estimatedFeeAmount: Double {
        estimatedTradeAmount * simulator.feeRatePercent / 100
    }

    var feeImpactPercentPoint: Double {
        guard portfolioReferenceAmount > 0 else { return 0 }
        return estimatedFeeAmount / portfolioReferenceAmount * 100
    }

    var netImprovement: Double {
        grossImprovement - feeImpactPercentPoint
    }

    var expectedReturnText: String {
        String(format: "%.1f", expectedGrossReturn)
    }

    var netImprovementText: String {
        signedPercent(netImprovement)
    }

    var feeImpactText: String {
        String(format: "%.2f", feeImpactPercentPoint)
    }

    var turnoverText: String {
        String(format: "%.1f", turnoverPercent)
    }

    var estimatedTradeAmountText: String {
        currencyText(estimatedTradeAmount)
    }

    var estimatedFeeAmountText: String {
        currencyText(estimatedFeeAmount)
    }

    var isFeeCautionNeeded: Bool {
        turnoverPercent >= 20
    }

    var maxSingleWeightCapText: String {
        "\(Int(maxSingleWeightCap))"
    }

    var isCashReserveBelowMinimum: Bool {
        cashReserveWeight + 0.1 < rebalancingConfig.minimumCashReservePercent
    }

    var cashReserveStatusText: String {
        let range = rebalancingConfig.recommendedCashReserveRange
        if cashReserveWeight < rebalancingConfig.minimumCashReservePercent {
            return "현금 여유 부족"
        }
        if cashReserveWeight > range.max {
            return "현금 비중 높음"
        }
        return "현금/달러 균형 양호"
    }

    var cashReserveColor: Color {
        let range = rebalancingConfig.recommendedCashReserveRange
        if cashReserveWeight < rebalancingConfig.minimumCashReservePercent {
            return .policyCoral
        }
        if cashReserveWeight > range.max {
            return .policyAmber
        }
        return .emerald
    }

    var beginnerActionHeadline: String {
        if isCashReserveBelowMinimum {
            return "현금/달러 비중을 조금 남기면 손실 방어에 더 유리해요"
        }
        if netImprovement >= 0 {
            return "수익 기대와 리스크 방어의 균형이 잡힌 조정이에요"
        }
        return "매매를 줄이면 비용 대비 효율이 좋아질 수 있어요"
    }

    var beginnerActionBullets: [String] {
        let reserveGap = max(0, rebalancingConfig.minimumCashReservePercent - cashReserveWeight)
        let reserveMessage: String
        if reserveGap > 0 {
            reserveMessage = "최소 권장 현금/달러 \(minimumCashReserveText)%보다 \(Int(reserveGap.rounded()))%p 부족해요. 급락 대응을 위해 일부 비중을 남겨두세요."
        } else if cashReserveWeight > rebalancingConfig.recommendedCashReserveRange.max {
            reserveMessage = "현금/달러 비중이 \(cashReserveWeightText)%로 높아 기회를 놓칠 수 있어요. ETF를 소폭 늘리면 수익 기대가 개선될 수 있어요."
        } else {
            reserveMessage = "현금/달러 비중이 권장 구간(\(recommendedCashReserveRangeText)%)에 있어 갑작스러운 변동에도 대응하기 좋아요."
        }

        let turnoverGuidance: String
        if turnoverPercent >= 20 {
            turnoverGuidance = "이번 조정은 매매 비중 \(turnoverText)%로 큰 편이에요. 예상 수수료 \(estimatedFeeAmountText) 부담이 있어 2~3회에 나눠 조정하는 편이 안전해요."
        } else {
            turnoverGuidance = "매매 비중 \(turnoverText)% 수준이라 과도한 회전은 아니에요. 예상 수수료는 약 \(estimatedFeeAmountText)로 계산돼요."
        }

        let outcomeGuidance = "수수료 반영 순효과는 \(netImprovementText)%p, 비관 시나리오에서는 \(pessimisticScenarioText)%로 예상돼요."
        let fxGuidance: String
        if usdExposureAmount > 0 {
            fxGuidance = "달러 노출이 있어 환율이 10원 움직이면 평가금액이 약 \(currencyText(fx10WonImpactKRW)) 변할 수 있어요."
        } else {
            fxGuidance = "원화 자산 비중이 높아 환율 변동 영향은 제한적이에요."
        }

        return [
            "현재 배분은 ETF \(totalETFWeightText)%, 현금/달러 \(cashReserveWeightText)%예요. 남는 비중은 안전자금으로 유지됩니다.",
            reserveMessage,
            turnoverGuidance + " " + outcomeGuidance + " " + fxGuidance
        ]
    }

    var isTargetOverAllocated: Bool {
        totalTargetWeight > 100.1
    }

    var concentrationIndex: Double {
        guard totalTargetWeight > 0 else { return 0 }
        return simulatorAllocations.reduce(0.0) { partial, item in
            let weight = targetWeight(for: item.id) / totalTargetWeight
            return partial + (weight * weight)
        } * 10_000
    }

    var diversificationScore: Int {
        guard totalTargetWeight > 0 else { return 100 }
        let lowerBound = 10_000.0 / Double(max(simulatorAllocations.count, 1))
        let upperBound = maxConcentrationIndexWithCap(totalInvestedWeight: totalTargetWeight)
        guard upperBound > lowerBound else { return 100 }
        let raw = (upperBound - concentrationIndex) / (upperBound - lowerBound) * 100
        return Int(raw.clamped(to: 0...100).rounded())
    }

    var concentrationGradeText: String {
        switch diversificationScore {
        case rebalancingConfig.diversificationGoodMin...100:
            return "좋음"
        case rebalancingConfig.diversificationWarningMin..<rebalancingConfig.diversificationGoodMin:
            return "주의"
        default:
            return "위험"
        }
    }

    var concentrationColor: Color {
        switch diversificationScore {
        case rebalancingConfig.diversificationGoodMin...100:
            return .emerald
        case rebalancingConfig.diversificationWarningMin..<rebalancingConfig.diversificationGoodMin:
            return .policyAmber
        default:
            return .policyCoral
        }
    }

    var concentrationScoreText: String {
        "\(diversificationScore)점"
    }

    var pessimisticScenarioReturn: Double {
        let cashDeficit = max(0, rebalancingConfig.minimumCashReservePercent - cashReserveWeight)
        let downturnPenalty = rebalancingConfig.baseDownturnPenalty
            + (turnoverPercent * rebalancingConfig.turnoverPenaltyPerPercent)
            + max(0, concentrationIndex - rebalancingConfig.concentrationPenaltyStart) / rebalancingConfig.concentrationPenaltyDivisor
            + (cashDeficit * rebalancingConfig.cashDeficitPenaltyPerPercent)
        return expectedGrossReturn - downturnPenalty
    }

    var pessimisticScenarioText: String {
        signedPercent(pessimisticScenarioReturn)
    }

    var netEffectScore: Int {
        let cashDeficit = max(0, rebalancingConfig.minimumCashReservePercent - cashReserveWeight)
        let raw = rebalancingConfig.netBaseScore
            + netImprovement * rebalancingConfig.netImprovementWeight
            - max(0, turnoverPercent - rebalancingConfig.turnoverPenaltyStart) * rebalancingConfig.turnoverPenaltyWeight
            - max(0, concentrationIndex - rebalancingConfig.netConcentrationPenaltyStart) / rebalancingConfig.netConcentrationPenaltyDivisor
            - (cashDeficit * rebalancingConfig.netCashDeficitPenaltyPerPercent)
        return Int(raw.clamped(to: 0...100).rounded())
    }

    var netEffectScoreText: String {
        "\(netEffectScore)점"
    }

    var netEffectGradeText: String {
        switch netEffectScore {
        case rebalancingConfig.netEffectGoodMin...100:
            return "우수"
        case rebalancingConfig.netEffectWarningMin..<rebalancingConfig.netEffectGoodMin:
            return "보통"
        default:
            return "주의"
        }
    }

    var netEffectColor: Color {
        switch netEffectScore {
        case rebalancingConfig.netEffectGoodMin...100:
            return .emerald
        case rebalancingConfig.netEffectWarningMin..<rebalancingConfig.netEffectGoodMin:
            return .policyAmber
        default:
            return .policyCoral
        }
    }

    var riskLevelText: String {
        switch turnoverPercent {
        case 0..<10:
            return "낮음"
        case 10..<25:
            return "보통"
        default:
            return "높음"
        }
    }

    var riskColor: Color {
        switch turnoverPercent {
        case 0..<10:
            return .emerald
        case 10..<25:
            return .policyAmber
        default:
            return .policyCoral
        }
    }

    func heldSharesText(for id: Int) -> String {
        guard let allocation = simulatorAllocations.first(where: { $0.id == id }) else { return "-" }
        return "\(Int(allocation.heldShares.rounded()))주"
    }

    func unitPriceText(for id: Int) -> String {
        guard let allocation = simulatorAllocations.first(where: { $0.id == id }) else { return "-" }

        switch allocation.unitPriceCurrency {
        case .krw:
            return "\(currencyText(allocation.unitPrice)) /주"
        case .usd:
            let krw = allocation.unitPrice * usdKrwRate
            return "\(usdCurrencyText(allocation.unitPrice)) (≈ \(currencyText(krw))) /주"
        }
    }

    func holdingValueText(for id: Int) -> String {
        guard let allocation = simulatorAllocations.first(where: { $0.id == id }) else { return "-" }
        return currencyText(holdingValueKRW(of: allocation))
    }

    private var portfolioReferenceAmount: Double {
        let marketBased = currentETFTotalValueKRW + currentCashHoldingValueKRW
        if marketBased > 0 { return marketBased }
        return simulator.etfPoolAmount + simulator.cashKRWAmount + (simulator.cashUSDAmount * usdKrwRate)
    }

    private var currentETFTotalValueKRW: Double {
        simulatorAllocations.reduce(0.0) { $0 + holdingValueKRW(of: $1) }
    }

    private var usdExposureAmount: Double {
        simulatorAllocations.reduce(0.0) { partial, allocation in
            guard allocation.unitPriceCurrency == .usd else { return partial }
            return partial + (allocation.heldShares * allocation.unitPrice)
        }
    }

    private var fx10WonImpactKRW: Double {
        usdExposureAmount * 10
    }

    private func holdingValueKRW(of allocation: SimulatorETFAllocation) -> Double {
        allocation.heldShares * unitPriceKRW(of: allocation)
    }

    private func unitPriceKRW(of allocation: SimulatorETFAllocation) -> Double {
        switch allocation.unitPriceCurrency {
        case .krw:
            return allocation.unitPrice
        case .usd:
            return allocation.unitPrice * usdKrwRate
        }
    }

    private func weightedReturn(using weights: [Int: Double]) -> Double {
        let etfReturn = simulatorAllocations.reduce(0.0) { partial, item in
            let weight = weights[item.id] ?? 0
            return partial + (weight * item.expectedMonthlyReturn / 100)
        }
        let reserveWeight = max(0, 100 - weights.values.reduce(0, +))
        let reserveReturn = reserveWeight * rebalancingConfig.reserveExpectedMonthlyReturn / 100
        return etfReturn + reserveReturn
    }

    private func sanitized(weights: [Int: Double]) -> [Int: Double] {
        SignalViewModel.sanitized(
            weights: weights,
            allocations: simulatorAllocations,
            maxSingleWeightCap: maxSingleWeightCap
        )
    }

    private static func sanitized(
        weights: [Int: Double],
        allocations: [SimulatorETFAllocation],
        maxSingleWeightCap: Double
    ) -> [Int: Double] {
        var adjusted: [Int: Double] = [:]
        for allocation in allocations {
            let raw = weights[allocation.id] ?? 0
            adjusted[allocation.id] = min(max(raw, 0), maxSingleWeightCap)
        }

        let total = adjusted.values.reduce(0, +)
        guard total > 100 else { return adjusted }

        let scale = 100 / total
        adjusted.keys.forEach { id in
            adjusted[id] = (adjusted[id] ?? 0) * scale
        }
        return adjusted
    }

    private func maxConcentrationIndexWithCap(totalInvestedWeight: Double) -> Double {
        guard totalInvestedWeight > 0 else { return 0 }
        var remaining = totalInvestedWeight
        var buckets: [Double] = []
        let count = max(simulatorAllocations.count, 1)

        for _ in 0..<count {
            let next = min(maxSingleWeightCap, remaining)
            buckets.append(next)
            remaining -= next
            if remaining <= 0 { break }
        }
        while buckets.count < count { buckets.append(0) }

        return buckets.reduce(0.0) { partial, value in
            partial + pow(value / totalInvestedWeight, 2)
        } * 10_000
    }

    private func signedPercent(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", value))"
    }

    private func currencyText(_ value: Double) -> String {
        Self.krwFormatter.string(from: NSNumber(value: value)) ?? "₩0"
    }

    private func usdCurrencyText(_ value: Double) -> String {
        Self.usdFormatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private static let krwFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "KRW"
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private static let usdFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
