import Foundation
import SwiftUI

nonisolated enum TodayDashboardBuilder {
    static func makePortfolioSummary(
        from snapshot: PortfolioSnapshot,
        userAssetProfile: UserAssetProfile,
        fallback: TodayPortfolioSummary
    ) -> TodayPortfolioSummary {
        TodayPortfolioSummary(
            totalAsset: parseCurrency(snapshot.amountText) ?? fallback.totalAsset,
            todayChange: parsePercent(snapshot.changePercentText) ?? fallback.todayChange,
            todayChangeAmt: fallback.todayChangeAmt,
            cashDefense: cashDefensePercent(from: userAssetProfile) ?? fallback.cashDefense,
            dollarDefense: dollarDefensePercent(from: userAssetProfile) ?? fallback.dollarDefense,
            overtradeRisk: fallback.overtradeRisk,
            topExposures: exposureItems(from: userAssetProfile, fallback: fallback.topExposures),
            riskLevel: fallback.riskLevel
        )
    }

    private static func exposureItems(
        from userAssetProfile: UserAssetProfile,
        fallback: [TodayExposureItem]
    ) -> [TodayExposureItem] {
        guard !userAssetProfile.holdings.isEmpty else { return fallback }

        let interestExposure = userAssetProfile.holdings.reduce(0) { total, holding in
            let isInterestSensitive = holding.category == .depositSavings
                || holding.category == .loan
                || holding.name.localizedCaseInsensitiveContains("은행")
                || holding.name.localizedCaseInsensitiveContains("국채")
            return total + (isInterestSensitive ? holding.weightPercent : 0)
        }

        let semiconductorExposure = userAssetProfile.holdings.reduce(0) { total, holding in
            let isSemiconductor = holding.name.localizedCaseInsensitiveContains("SOXX")
                || holding.name.localizedCaseInsensitiveContains("반도체")
                || holding.name.localizedCaseInsensitiveContains("삼성전자")
            return total + (isSemiconductor ? holding.weightPercent : 0)
        }

        let dollarExposure = userAssetProfile.holdings.reduce(0) { total, holding in
            let isDollarLinked = holding.name.localizedCaseInsensitiveContains("달러")
                || holding.name.localizedCaseInsensitiveContains("USD")
                || holding.name.localizedCaseInsensitiveContains("SOXX")
            return total + (isDollarLinked ? holding.weightPercent : 0)
        }

        let items = [
            TodayExposureItem(theme: "금리", pct: min(100, interestExposure), color: PSColor.electricBlue),
            TodayExposureItem(theme: "반도체", pct: min(100, semiconductorExposure), color: PSColor.purple),
            TodayExposureItem(theme: "달러", pct: min(100, dollarExposure), color: PSColor.yellow)
        ]

        return items.contains { $0.pct > 0 } ? items : fallback
    }

    private static func cashDefensePercent(from userAssetProfile: UserAssetProfile) -> Int? {
        guard !userAssetProfile.holdings.isEmpty else { return nil }

        return userAssetProfile.holdings.reduce(0) { total, holding in
            total + (holding.category == .depositSavings ? holding.weightPercent : 0)
        }
    }

    private static func dollarDefensePercent(from userAssetProfile: UserAssetProfile) -> Int? {
        guard !userAssetProfile.holdings.isEmpty else { return nil }

        let dollarPercent = userAssetProfile.holdings.reduce(0) { total, holding in
            let isDollarLinked = holding.name.localizedCaseInsensitiveContains("달러")
                || holding.name.localizedCaseInsensitiveContains("USD")
            return total + (isDollarLinked ? holding.weightPercent : 0)
        }

        return dollarPercent > 0 ? dollarPercent : nil
    }

    private static func parseCurrency(_ text: String) -> Int? {
        let digits = text.filter(\.isNumber)
        return Int(digits)
    }

    private static func parsePercent(_ text: String) -> Double? {
        let normalized = text
            .replacingOccurrences(of: "%", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return Double(normalized)
    }
}
