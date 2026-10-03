import Foundation
import Testing
@testable import egunHoldings

struct AuthAccountStoreGoalTests {
    @Test("데모 계정도 저장한 온보딩 목표를 다시 읽는다")
    func preservesSavedGoalForDefaultAccount() throws {
        let suiteName = "goal-store-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = AuthAccountStore(defaults: defaults)
        var account = try #require(store.loadAll().first)
        account.onboardingCompleted = true
        account.onboardingResult = OnboardingResult(
            financialGoal: FinancialGoal.homePurchase.rawValue,
            targetAmount: 800_000_000
        )
        store.saveAll([account])

        let restored = try #require(AuthAccountStore(defaults: defaults).loadAll().first {
            $0.normalizedEmail == account.normalizedEmail
        })
        #expect(restored.onboardingCompleted)
        #expect(restored.onboardingResult?.targetAmount == 800_000_000)
    }
}
