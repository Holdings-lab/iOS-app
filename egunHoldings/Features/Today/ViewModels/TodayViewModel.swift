import Combine
import SwiftUI

@MainActor
final class TodayViewModel: ObservableObject {
    @Published var activeSheet: TodaySheet?
    @Published private(set) var loadState: TodayLoadState = .idle
    @Published private(set) var userAssetProfile: UserAssetProfile
    @Published private(set) var portfolioSnapshot: PortfolioSnapshot
    @Published private(set) var judgment: TodayJudgment
    @Published private(set) var portfolio: TodayPortfolioSummary
    @Published private(set) var topPolicy: TodayPolicyEvent?
    @Published private(set) var policyEvents: [TodayPolicyEvent]
    @Published private(set) var holdings: [TodayHolding]
    @Published private(set) var noActionReasons: [String]
    @Published private(set) var noActionWatchCondition: String
    @Published private(set) var primaryCheckpointText: String
    @Published private(set) var dataUpdatedAt: String
    @Published private(set) var dataSources: [String]
    @Published private(set) var aiSummaryStatus: String
    @Published private(set) var themeSignals: [PortfolioThemeSignal]
    @Published private(set) var policyReadings: [PolSignalPolicyReading]
    @Published private(set) var adjustmentProposal: PolSignalAdjustmentProposal?
    @Published private(set) var apiConnectionStatuses: [TodayAPIConnectionStatus]

    private let userId: Int64?
    private let repository: TodayRepositoryProtocol
    private var didLoad = false

    init(
        userId: Int64? = nil,
        userAssetProfile: UserAssetProfile,
        portfolioSnapshot: PortfolioSnapshot,
        policyEvents: [TodayPolicyEvent] = TodayMockData.policyEvents,
        holdings: [TodayHolding] = TodayMockData.holdings,
        judgment: TodayJudgment = TodayMockData.judgment,
        repository: TodayRepositoryProtocol? = nil
    ) {
        let dashboard = MockTodayRepository.makeDashboard(
            userId: userId,
            userAssetProfile: userAssetProfile,
            portfolioSnapshot: portfolioSnapshot,
            policyEvents: policyEvents,
            holdings: holdings,
            judgment: judgment
        )

        self.userId = userId
        self.repository = repository ?? TodayRepositoryFactory.makeDefault()
        self.userAssetProfile = dashboard.userAssetProfile
        self.portfolioSnapshot = dashboard.portfolioSnapshot
        self.judgment = dashboard.judgment
        self.portfolio = dashboard.portfolio
        let rankedPolicyEvents = Self.rankByImpact(dashboard.policyEvents)
        self.topPolicy = rankedPolicyEvents.first ?? dashboard.topPolicy
        self.policyEvents = rankedPolicyEvents
        self.holdings = dashboard.holdings
        self.noActionReasons = dashboard.noActionReasons
        self.noActionWatchCondition = dashboard.noActionWatchCondition
        self.primaryCheckpointText = dashboard.primaryCheckpointText
        self.dataUpdatedAt = dashboard.dataUpdatedAt
        self.dataSources = dashboard.dataSources
        self.aiSummaryStatus = dashboard.aiSummaryStatus
        self.themeSignals = dashboard.themeSignals
        self.policyReadings = dashboard.policyReadings
        self.adjustmentProposal = dashboard.adjustmentProposal
        self.apiConnectionStatuses = dashboard.apiConnectionStatuses
    }

    var connectedBrokerStatusText: String {
        userAssetProfile.holdings.isEmpty ? "연결 전" : "한국투자증권 읽기 전용"
    }

    var connectionStatusText: String {
        switch loadState {
        case .idle:
            return "예시 데이터 사용 중"
        case .loading:
            return "서버 동기화 중"
        case .loaded:
            return "서버 데이터 연결됨"
        case .usingFallback:
            return "예시 데이터 사용 중"
        }
    }

    var dataStatusFootnote: String {
        switch loadState {
        case .loaded:
            return "서버에서 받은 Today 브리핑과 읽기 전용 보유 자산을 기준으로 구성합니다."
        case .loading:
            return "현재 서버 데이터를 동기화하고 있습니다. 동기화 전까지는 마지막 예시 브리핑을 보여줍니다."
        case .usingFallback(let message):
            return message.map { "\($0)" }
                ?? "예시 데이터를 사용 중입니다. 실제 계좌 연결 시 실계좌 기준 분석으로 전환됩니다."
        case .idle:
            return "예시 데이터를 사용 중입니다. 실제 계좌 연결 시 실계좌 기준 분석으로 전환됩니다."
        }
    }

    var dataStatusRows: [(String, String)] {
        [
            ("마지막 업데이트", dataUpdatedAt),
            ("데이터 출처", dataSources.joined(separator: ", ")),
            ("포트폴리오", connectedBrokerStatusText),
            ("AI 요약", aiSummaryStatus)
        ]
    }

    func load() async {
        guard !didLoad else { return }
        didLoad = true
        await refresh()
    }

    func refresh() async {
        guard userId != nil else {
            apiConnectionStatuses = MockTodayRepository.mockConnectionStatuses(userId: nil)
            loadState = .usingFallback(message: nil)
            return
        }

        loadState = .loading

        do {
            let dashboard = try await repository.fetchDashboard(
                userId: userId,
                userAssetProfile: userAssetProfile,
                portfolioSnapshot: portfolioSnapshot
            )
            apply(dashboard)
            loadState = .loaded
        } catch {
            apiConnectionStatuses = MockTodayRepository.mockConnectionStatuses(userId: userId)
            loadState = .usingFallback(message: Self.errorMessage(for: error))
        }
    }

    func present(_ sheet: TodaySheet) {
        activeSheet = sheet
    }

    func relatedPolicies(for item: TodayExposureItem) -> [TodayPolicyEvent] {
        Self.rankByImpact(
            policyEvents.filter { policy in
                policy.myExposure > 20 || policy.relatedAssets.contains { asset in
                    asset.localizedCaseInsensitiveContains(item.theme)
                }
            }
        )
    }

    private func apply(_ dashboard: TodayDashboard) {
        userAssetProfile = dashboard.userAssetProfile
        portfolioSnapshot = dashboard.portfolioSnapshot
        judgment = dashboard.judgment
        portfolio = dashboard.portfolio
        let rankedPolicyEvents = Self.rankByImpact(dashboard.policyEvents)
        topPolicy = rankedPolicyEvents.first ?? dashboard.topPolicy
        policyEvents = rankedPolicyEvents
        holdings = dashboard.holdings
        noActionReasons = dashboard.noActionReasons
        noActionWatchCondition = dashboard.noActionWatchCondition
        primaryCheckpointText = dashboard.primaryCheckpointText
        dataUpdatedAt = dashboard.dataUpdatedAt
        dataSources = dashboard.dataSources
        aiSummaryStatus = dashboard.aiSummaryStatus
        themeSignals = dashboard.themeSignals
        policyReadings = dashboard.policyReadings
        adjustmentProposal = dashboard.adjustmentProposal
        apiConnectionStatuses = dashboard.apiConnectionStatuses
    }

    private static func errorMessage(for error: Error) -> String {
        AppVocabulary.ErrorMessage.userFacing(for: error)
    }

    private static func rankByImpact(_ policies: [TodayPolicyEvent]) -> [TodayPolicyEvent] {
        policies.sorted { lhs, rhs in
            if lhs.myExposure != rhs.myExposure {
                return lhs.myExposure > rhs.myExposure
            }

            if lhs.confidence != rhs.confidence {
                return lhs.confidence > rhs.confidence
            }

            return lhs.id < rhs.id
        }
    }
}
