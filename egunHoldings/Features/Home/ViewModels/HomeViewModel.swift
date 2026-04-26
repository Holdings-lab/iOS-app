import Foundation
import Combine
import SwiftUI

final class HomeViewModel: ObservableObject {
    @Published var selectedEventID: Int

    let profile: InvestorProfile
    let events: [HomePolicyEvent]
    let eventDetails: [Int: PolicyEventDetail]
    let userAssetProfile: UserAssetProfile
    let snapshot: PortfolioSnapshot
    let trendPoints: [PortfolioTrendPoint]
    let trendMarkers: [PortfolioMarker]
    let chartGridValues: [Double]
    let policyDashboard: HomePolicyDashboard
    let exposureDashboard: AssetExposureDashboard

    init(
        repository: HomeRepositoryProtocol = MockHomeRepository(),
        userAssetProfile: UserAssetProfile? = nil,
        portfolioSnapshot: PortfolioSnapshot? = nil
    ) {
        profile = repository.fetchProfile()
        events = repository.fetchWeeklyEvents()
        eventDetails = repository.fetchEventDetails()
        self.userAssetProfile = userAssetProfile ?? repository.fetchUserAssetProfile()
        snapshot = portfolioSnapshot ?? repository.fetchPortfolioSnapshot()
        trendPoints = repository.fetchTrendPoints()
        trendMarkers = repository.fetchTrendMarkers()
        chartGridValues = repository.fetchChartGridValues()
        policyDashboard = HomePolicyImpactMockData.dashboard
        exposureDashboard = AssetExposureMockData.dashboard
        selectedEventID = events.first?.id ?? 0
    }

    func selectEvent(_ eventID: Int) {
        selectedEventID = eventID
    }

    func detail(for eventID: Int) -> PolicyEventDetail? {
        eventDetails[eventID]
    }

    func impactPolicy(for id: Int) -> HomeImpactPolicy? {
        policyDashboard.topPolicies.first(where: { $0.id == id })
    }

    var featuredPolicy: HomeImpactPolicy? {
        topPolicies.max { left, right in
            left.meta.exposurePercent < right.meta.exposurePercent
        }
    }

    var topPolicies: [HomeImpactPolicy] {
        policyDashboard.topPolicies
    }

    var prioritizedPolicies: [HomeImpactPolicy] {
        topPolicies.sorted { left, right in
            left.meta.exposurePercent > right.meta.exposurePercent
        }
    }

    var secondaryPolicies: [HomeImpactPolicy] {
        policyDashboard.secondaryPolicies
    }

    var primaryChangeDriver: PortfolioImpactDriver? {
        policyDashboard.changeDrivers.max { left, right in
            left.sharePercent < right.sharePercent
        }
    }

    var reviewStatusText: String? {
        featuredPolicy?.meta.updateSummary.reviewText
    }

    var briefingPolicy: HomeImpactPolicy? {
        featuredPolicy
    }

    var heroDriverSummary: String {
        primaryChangeDriver?.summary ?? snapshot.insightText
    }

    var primaryCheckpoint: WeeklyPolicyCheckpoint? {
        featuredPolicy?.checkpoints.first ?? policyDashboard.checkpoints.first
    }

    var checkpointTeaserPolicy: HomeImpactPolicy? {
        prioritizedPolicies.first { policy in
            policy.id != briefingPolicy?.id && policy.checkpoints.isEmpty == false
        } ?? prioritizedPolicies.first { $0.checkpoints.isEmpty == false }
    }

    var primaryCheckpointAlertSummary: String? {
        guard let alerts = featuredPolicy?.alerts, alerts.isEmpty == false else {
            return nil
        }

        return alerts
            .prefix(2)
            .joined(separator: " · ")
    }

    var checkpointCount: Int {
        policyDashboard.checkpoints.count
    }

    var topSensitivityItems: [PolicyExposureSummaryItem] {
        exposureDashboard.summaryItems
            .sorted { left, right in
                left.exposurePercent > right.exposurePercent
            }
            .prefix(3)
            .map { $0 }
    }

    var homeExposureItems: [PolicyExposureSummaryItem] {
        let preferredKeywords = ["금리", "반도체", "달러"]
        let matched = preferredKeywords.compactMap { keyword in
            exposureDashboard.summaryItems.first { $0.title.contains(keyword) }
        }

        return matched.isEmpty ? topSensitivityItems : matched
    }

    var primaryRiskReadiness: DefenseReadinessItem? {
        exposureDashboard.defenseReadiness.first(where: { $0.title.contains("정책 집중도") })
            ?? exposureDashboard.defenseReadiness.first
    }

    var riskTemperatureScore: Double {
        guard let value = primaryRiskReadiness?.value else {
            return 0.48
        }

        switch value {
        case "양호", "낮음":
            return 0.26
        case "주의":
            return 0.56
        case "위험":
            return 0.84
        default:
            return 0.48
        }
    }

    var activeSignalCount: Int {
        policyDashboard.topPolicies.count
    }

    var homeRiskTitle: String {
        primaryRiskReadiness?.value ?? "주의"
    }

    var homeRiskReason: String {
        primaryRiskReadiness?.summary ?? "정책 변수에 노출이 몰려 있어요."
    }

    func homeExposureTitle(for item: PolicyExposureSummaryItem) -> String {
        switch item.title {
        case let title where title.contains("금리"):
            return "금리 노출"
        case let title where title.contains("반도체"):
            return "반도체 노출"
        case let title where title.contains("달러"):
            return "달러 노출"
        case let title where title.contains("친환경"):
            return "친환경 노출"
        default:
            return item.title
        }
    }

    func homeBriefingExposure(for policy: HomeImpactPolicy) -> String {
        let prefix: String

        if policy.title.contains("금리") {
            prefix = "금리 변화 노출"
        } else if policy.title.contains("반도체") {
            prefix = "반도체 정책 노출"
        } else if policy.title.contains("전력망") || policy.title.contains("친환경") {
            prefix = "친환경 정책 노출"
        } else {
            prefix = "내 자산 노출"
        }

        return "\(prefix) \(policy.meta.exposurePercent)%"
    }

    func homeBriefingAction(for policy: HomeImpactPolicy) -> String {
        switch policy.judgment.action {
        case .hedge:
            return "방어 비중 점검"
        case .wait:
            if policy.title.contains("반도체") {
                return "발표 전 추격보다 확인"
            }
            return "지금은 확인이 우선"
        case .increase:
            return "비중 확대 검토"
        case .reduce:
            return "단기 비중 축소 점검"
        }
    }

    func checkpointTeaserTitle(for policy: HomeImpactPolicy) -> String {
        policy.title
            .replacingOccurrences(of: "미국 ", with: "")
            .appending(" 체크포인트")
    }

    func quickCheckValue(for policy: HomeImpactPolicy) -> String {
        policy.checkpoints.first?.threshold ?? policy.judgment.thresholdSummary
    }

    func quickCheckHint(for policy: HomeImpactPolicy) -> String {
        policy.checkpoints.first?.whyItMatters ?? policy.judgment.thresholdSummary
    }

    func personalizedBriefing(for eventID: Int) -> PersonalizationBriefing {
        let etfHoldings = userAssetProfile.holdings.filter { $0.category == .etf }
        let hasDeposit = userAssetProfile.holdings.contains { $0.category == .depositSavings }
        let hasLoan = userAssetProfile.holdings.contains { $0.category == .loan }

        switch eventID {
        case 2:
            let hasSOXX = etfHoldings.contains { $0.name.uppercased().contains("SOXX") }
            let headline = hasSOXX
                ? "보유 중인 SOXX가 직접적으로 반응할 가능성이 있어요."
                : "반도체 관련 ETF 비중을 점검할 타이밍이에요."
            var bullets: [String] = []
            if hasSOXX, let soxx = etfHoldings.first(where: { $0.name.uppercased().contains("SOXX") }) {
                bullets.append("현재 \(soxx.name) 비중이 \(soxx.weightPercent)%라 단기 변동이 수익률에 바로 반영될 수 있어요.")
            }
            bullets.append("정책 발표 직후 급등 구간에 추격매수하기보다 분할 접근이 유리해요.")
            if hasLoan {
                bullets.append("대출 보유 중이면 투자 비중 확대 전 월 이자 부담부터 먼저 확인해보세요.")
            }
            return PersonalizationBriefing(headline: headline, bullets: bullets)

        case 3:
            let hasICLN = etfHoldings.contains { $0.name.uppercased().contains("ICLN") }
            let headline = hasICLN
                ? "보유 중인 ICLN이 정책 수혜 기대의 중심에 있어요."
                : "클린에너지 테마가 포트폴리오 분산 후보로 떠오를 수 있어요."
            var bullets: [String] = []
            if hasICLN, let icln = etfHoldings.first(where: { $0.name.uppercased().contains("ICLN") }) {
                bullets.append("\(icln.name) 비중 \(icln.weightPercent)%는 정책 뉴스에 민감하게 움직일 가능성이 커요.")
            }
            bullets.append("단기 급등락이 크기 때문에 목표 비중을 정해두고 리밸런싱하는 방식이 좋아요.")
            return PersonalizationBriefing(headline: headline, bullets: bullets)

        case 1, 4, 5:
            var bullets: [String] = []
            let headline = "금리·물가 이벤트는 현재 보유 자산 전체에 연결돼 있어요."
            if hasDeposit, let deposit = userAssetProfile.holdings.first(where: { $0.category == .depositSavings }) {
                bullets.append("\(deposit.name) 비중이 \(deposit.weightPercent)%라 신규 예적금 금리 조건 변화를 체크할 가치가 커요.")
            }
            if let bankETF = etfHoldings.first(where: { $0.name.contains("은행") }) {
                bullets.append("\(bankETF.name)는 금리 기대 변화에 따라 단기 방향성이 달라질 수 있어요.")
            }
            if hasLoan, let loan = userAssetProfile.holdings.first(where: { $0.category == .loan }) {
                bullets.append("\(loan.name) 보유 중이면 고정/변동 금리 조건과 다음 이자 납부액을 함께 점검해보세요.")
            }
            if bullets.isEmpty {
                bullets.append("금리 발표일에는 변동성이 커지므로 현금 비중과 손절 기준을 미리 정해두세요.")
            }
            return PersonalizationBriefing(headline: headline, bullets: bullets)

        default:
            return PersonalizationBriefing(
                headline: "현재 포트폴리오 기준으로 변동성 관리가 우선이에요.",
                bullets: ["정책 발표 직후에는 수치 확인 후 대응하는 보수적 접근이 유리해요."]
            )
        }
    }
}
