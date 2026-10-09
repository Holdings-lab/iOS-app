import Foundation
import Testing
@testable import egunHoldings

@MainActor
struct GoalSettingsFlowTests {
    @Test("설정 목표 슬라이더는 모든 목적에서 1억부터 15억원까지 1천만원 간격이다")
    func settingsGoalRangeMatchesOnboarding() {
        for goal in FinancialGoal.allCases {
            let preset = goal.settingsPreset
            #expect(preset.min == 100_000_000)
            #expect(preset.max == 1_500_000_000)
            #expect(preset.step == 10_000_000)
            #expect((preset.min...preset.max).contains(preset.amount))
        }
    }

    @Test("서버 목표가 있어도 로컬 목표가 없으면 서버 목표를 사용하지 않는다")
    func ignoresServerGoal() async {
        let settings = SettingsViewModel(notificationCenter: .shared, repository: GoalSettingsRepository())
        await settings.loadSettings()
        #expect(settings.financialGoal == .retirement)
        #expect(settings.targetAmount == FinancialGoal.retirement.defaultTargetAmount)
    }

    @Test("설정에서 저장한 목표가 홈 계산과 재실행 세션에 반영된다")
    func persistsSettingsGoalAndRecalculatesToday() async throws {
        let suite = "goal-flow-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = AuthSessionStore(defaults: defaults)
        let accounts = AuthAccountStore(defaults: defaults)
        store.save(AppUserSession(userId: 11, token: "test-token", expiresAt: Date().addingTimeInterval(3600),
                                  userName: "테스트", email: "goal@test.example", onboardingCompleted: true,
                                  onboardingResult: nil, brokerBalanceSnapshot: AppMockData.brokerBalanceSnapshot))
        let router = AppRouter(store: store, accountStore: accounts)
        let settings = SettingsViewModel(notificationCenter: .shared,
                                         onboardingResult: router.session?.onboardingResult,
                                         onGoalSaved: router.updateGoal)
        let todayRepository = GoalCountingTodayRepository()
        let today = TodayViewModel(userId: 11, userAssetProfile: router.userAssetProfile,
                                   portfolioSnapshot: router.portfolioSnapshot,
                                   brokerBalanceSnapshot: router.session?.brokerBalanceSnapshot,
                                   repository: todayRepository)
        await today.load()
        settings.saveGoal(goal: .seedMoney, amount: 1_500_000_000)
        today.updateSessionData(userAssetProfile: router.userAssetProfile,
                                portfolioSnapshot: router.portfolioSnapshot,
                                onboardingResult: router.session?.onboardingResult,
                                brokerBalanceSnapshot: router.session?.brokerBalanceSnapshot)
        #expect(today.goalProgress?.goalLabel == FinancialGoal.seedMoney.title)
        #expect(today.goalProgress?.progressPercent == 9)
        #expect(todayRepository.count == 1)
        #expect(store.load()?.onboardingResult?.targetAmount == 1_500_000_000)
        #expect(accounts.loadAll().first { $0.normalizedEmail == "goal@test.example" }?.onboardingResult?.targetAmount == 1_500_000_000)
        let restarted = AppRouter(store: store, accountStore: accounts)
        let reopened = SettingsViewModel(notificationCenter: .shared,
                                         repository: GoalSettingsRepository(),
                                         onboardingResult: restarted.session?.onboardingResult)
        await reopened.loadSettings()
        #expect(reopened.financialGoal == .seedMoney)
        #expect(reopened.targetAmount == 1_500_000_000)
        #expect(restarted.session?.onboardingResult?.targetAmount == 1_500_000_000)
    }
}

@MainActor
private final class GoalCountingTodayRepository: TodayRepositoryProtocol {
    private(set) var count = 0
    func fetchDashboard(userId: Int64?, userAssetProfile: UserAssetProfile, portfolioSnapshot: PortfolioSnapshot,
                        onSection: (@MainActor @Sendable (TodaySectionUpdate) -> Void)?) async throws -> TodayDashboard {
        count += 1
        return MockTodayRepository.makeDashboard(userAssetProfile: userAssetProfile, portfolioSnapshot: portfolioSnapshot)
    }
}

private struct GoalSettingsRepository: SettingsRepositoryProtocol {
    func fetchSettings() async throws -> SettingsHomeResponseDTO {
        try NetworkJSONCoding.makeDecoder().decode(SettingsHomeResponseDTO.self, from: Data(#"{"user":{"nickname":"테스트","email":"goal@test.example","avatarText":"테"},"notifications":{"policyChangeAlert":false,"briefingTime":"09:00"},"investment":{"goal":{"code":"HOME_PURCHASE","label":"내 집 마련"},"connectedAccounts":{"count":1,"expiredCount":0},"interests":{"count":0}}}"#.utf8))
    }
    func updateNotifications(policyChangeAlert: Bool?, briefingTime: String?) async throws -> NotificationSettingsResponseDTO {
        throw URLError(.unsupportedURL)
    }
    func sendTestNotification() async throws -> TestNotificationResponseDTO { throw URLError(.unsupportedURL) }
}
