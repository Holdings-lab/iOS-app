import Combine
import SwiftUI

@MainActor
final class TodayViewModel: ObservableObject {
    @Published var activeSheet: TodaySheet?

    let userAssetProfile: UserAssetProfile
    let portfolioSnapshot: PortfolioSnapshot
    let judgment: TodayJudgment
    let portfolio: TodayPortfolioSummary
    let topPolicy: TodayPolicyEvent?
    let policyEvents: [TodayPolicyEvent]
    let holdings: [TodayHolding]
    let noActionReasons: [String]
    let noActionWatchCondition: String

    init(
        userAssetProfile: UserAssetProfile,
        portfolioSnapshot: PortfolioSnapshot,
        policyEvents: [TodayPolicyEvent] = TodayMockData.policyEvents,
        holdings: [TodayHolding] = TodayMockData.holdings,
        judgment: TodayJudgment = TodayMockData.judgment
    ) {
        self.userAssetProfile = userAssetProfile
        self.portfolioSnapshot = portfolioSnapshot
        self.policyEvents = policyEvents
        self.holdings = holdings
        self.judgment = judgment
        self.topPolicy = policyEvents.max { $0.myExposure < $1.myExposure }
        self.noActionReasons = TodayMockData.noActionReasons
        self.noActionWatchCondition = TodayMockData.noActionWatchCondition
        self.portfolio = Self.makePortfolioSummary(
            from: portfolioSnapshot,
            userAssetProfile: userAssetProfile,
            fallback: TodayMockData.portfolio
        )
    }

    var primaryCheckpointText: String {
        TodayMockData.checkpoints.first?.text ?? judgment.invalidationCondition
    }

    var connectedBrokerStatusText: String {
        userAssetProfile.holdings.isEmpty ? "연결 전" : "한국투자증권 읽기 전용"
    }

    var connectionStatusText: String {
        userAssetProfile.holdings.isEmpty ? "Mock 데이터 사용 중" : "읽기 전용 연결됨"
    }

    var dataStatusFootnote: String {
        userAssetProfile.holdings.isEmpty
            ? "Mock 데이터를 사용 중입니다. 실제 계좌 연결 시 실계좌 기준 분석으로 전환됩니다."
            : "읽기 전용으로 불러온 보유 자산을 기준으로 오늘 브리핑을 구성합니다."
    }

    var dataStatusRows: [(String, String)] {
        [
            ("마지막 업데이트", topPolicy?.updatedAt ?? "오전 11:24"),
            ("데이터 출처", topPolicy?.sources.joined(separator: ", ") ?? "Mock 데이터"),
            ("포트폴리오", connectedBrokerStatusText),
            ("AI 요약", "Mock 브리핑")
        ]
    }

    func present(_ sheet: TodaySheet) {
        activeSheet = sheet
    }

    func relatedPolicies(for item: TodayExposureItem) -> [TodayPolicyEvent] {
        policyEvents
            .filter { policy in
                policy.myExposure > 20 || policy.relatedAssets.contains { asset in
                    asset.localizedCaseInsensitiveContains(item.theme)
                }
            }
    }

    private static func makePortfolioSummary(
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
