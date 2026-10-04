import Foundation
import Testing
@testable import egunHoldings

@MainActor
struct GoalSettingsFlowTests {
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
        settings.saveGoal(goal: .homePurchase, amount: 400_000_000)
        today.updateSessionData(userAssetProfile: router.userAssetProfile,
                                portfolioSnapshot: router.portfolioSnapshot,
                                onboardingResult: router.session?.onboardingResult,
                                brokerBalanceSnapshot: router.session?.brokerBalanceSnapshot)
        #expect(today.goalProgress?.goalLabel == FinancialGoal.homePurchase.title)
        #expect(today.goalProgress?.progressPercent == 34)
        #expect(todayRepository.count == 1)
        #expect(store.load()?.onboardingResult?.targetAmount == 400_000_000)
        #expect(accounts.loadAll().first { $0.normalizedEmail == "goal@test.example" }?.onboardingResult?.targetAmount == 400_000_000)
        let restarted = AppRouter(store: store, accountStore: accounts)
        let reopened = SettingsViewModel(notificationCenter: .shared,
                                         repository: GoalSettingsRepository(),
                                         onboardingResult: restarted.session?.onboardingResult)
        await reopened.loadSettings()
        #expect(reopened.financialGoal == .homePurchase)
        #expect(reopened.targetAmount == 400_000_000)
        #expect(restarted.session?.onboardingResult?.targetAmount == 400_000_000)
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
        try NetworkJSONCoding.makeDecoder().decode(SettingsHomeResponseDTO.self, from: Data(#"{"user":{"nickname":"테스트","email":"goal@test.example","avatarText":"테"},"notifications":{"policyChangeAlert":false,"briefingTime":"09:00"},"investment":{"goal":{"code":"RETIREMENT","label":"은퇴"},"connectedAccounts":{"count":1,"expiredCount":0},"interests":{"count":0}}}"#.utf8))
    }
    func updateNotifications(policyChangeAlert: Bool?, briefingTime: String?) async throws -> NotificationSettingsResponseDTO {
        throw URLError(.unsupportedURL)
    }
    func sendTestNotification() async throws -> TestNotificationResponseDTO { throw URLError(.unsupportedURL) }
}
