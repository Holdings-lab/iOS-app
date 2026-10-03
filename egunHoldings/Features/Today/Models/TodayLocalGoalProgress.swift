import Foundation

enum TodayLocalGoalProgress {
    static func make(onboardingResult: OnboardingResult?, currentAssetAmount: Int) -> TodayGoalProgress? {
        guard let onboardingResult, onboardingResult.targetAmount > 0 else { return nil }

        let current = max(currentAssetAmount, 0)
        let target = onboardingResult.targetAmount
        let progress = Int((Double(current) / Double(target) * 100).rounded())
        let goalName = FinancialGoal(rawValue: onboardingResult.financialGoal)?.title ?? "투자 목표"

        return TodayGoalProgress(
            goalLabel: goalName,
            progressPercent: progress,
            status: .inProgress,
            scheduleDeltaText: "현재 \(OnboardingCurrencyFormatter.wonText(Int64(current))) / 목표 \(OnboardingCurrencyFormatter.wonText(target))"
        )
    }
}
