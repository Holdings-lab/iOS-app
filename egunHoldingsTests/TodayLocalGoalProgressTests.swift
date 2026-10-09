import Foundation
import Testing
@testable import egunHoldings

@MainActor
struct TodayLocalGoalProgressTests {
    @Test("온보딩 슬라이더는 1억부터 5억원까지 1천만원 단위로 선택한다")
    func targetAmountsUseEokUnits() {
        for goal in FinancialGoal.allCases {
            #expect(goal.targetAmountSliderStep == 10_000_000)
            #expect(goal.targetAmountSliderRange == 100_000_000...500_000_000)
            #expect(goal.defaultTargetAmount % 100_000_000 == 0)
        }
    }

    @Test("저장한 목표와 현재 자산으로 달성률을 계산한다")
    func calculatesProgressFromLocalGoal() {
        let goal = OnboardingResult(
            financialGoal: FinancialGoal.retirement.rawValue,
            targetAmount: 500_000_000
        )
        let progress = TodayLocalGoalProgress.make(
            onboardingResult: goal,
            currentAssetAmount: 134_820_000
        )
        #expect(progress?.progressPercent == 27)
        #expect(progress?.goalLabel == FinancialGoal.retirement.title)
        #expect(progress?.scheduleDeltaText.contains("5억원") == true)
        #expect(TodayLocalGoalProgress.make(onboardingResult: nil, currentAssetAmount: 134_820_000)?.progressPercent == nil)

        let achieved = TodayLocalGoalProgress.make(onboardingResult: goal, currentAssetAmount: 600_000_000)
        #expect(achieved?.progressPercent == 120)
        #expect(achieved?.clampedProgressPercent == 100)
    }

    @Test("잔고가 갱신되면 목표 달성률도 다시 계산한다")
    func updatesWhenBrokerBalanceChanges() {
        let goal = OnboardingResult(
            financialGoal: FinancialGoal.retirement.rawValue,
            targetAmount: 500_000_000
        )
        let viewModel = TodayViewModel(
            userId: 1,
            onboardingResult: goal,
            userAssetProfile: AppMockData.userAssetProfile,
            portfolioSnapshot: AppMockData.portfolioSnapshot,
            repository: MockTodayRepository()
        )
        #expect(viewModel.goalProgress?.progressPercent == 27)

        let mockBalance = AppMockData.brokerBalanceSnapshot
        let updatedBalance = BrokerBalanceSnapshot(
            broker: mockBalance.broker,
            environment: mockBalance.environment,
            accountNumber: mockBalance.accountNumber,
            productCode: mockBalance.productCode,
            totalEvaluationAmount: 250_000_000,
            stockEvaluationAmount: mockBalance.stockEvaluationAmount,
            cashAmount: mockBalance.cashAmount,
            totalPurchaseAmount: mockBalance.totalPurchaseAmount,
            totalProfitLossAmount: mockBalance.totalProfitLossAmount,
            holdings: mockBalance.holdings,
            fetchedAt: mockBalance.fetchedAt
        )
        viewModel.updateSessionData(
            userAssetProfile: AppMockData.userAssetProfile,
            portfolioSnapshot: AppMockData.portfolioSnapshot,
            onboardingResult: goal,
            brokerBalanceSnapshot: updatedBalance
        )
        #expect(viewModel.goalProgress?.progressPercent == 50)
    }
}
