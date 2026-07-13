import SwiftUI

struct OnboardingStep1GoalView: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    let onNext: () -> Void
    var onBack: () -> Void = {}

    @State private var isProgressCollapsed = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            OnboardingProgressScrollAnchor()

            VStack(alignment: .leading, spacing: 24) {
                OnboardingV3StepHeader(step: 1, onBack: onBack)

                OnboardingV3QuestionHeader(
                    title: "왜 투자하시나요?",
                    subtitle: "가장 가까운 목적을 골라주세요"
                )

                VStack(spacing: 12) {
                    ForEach(FinancialGoal.allCases) { goal in
                        OnboardingV3OptionCard(
                            symbol: goal.symbol,
                            title: goal.title,
                            isSelected: viewModel.financialGoal == goal
                        ) {
                            viewModel.selectFinancialGoal(goal)
                        }
                    }
                }
            }
            .padding(.horizontal, OnboardingV3Layout.horizontalPadding)
            .padding(.top, OnboardingV3Layout.progressContentTopPadding)
            .padding(.bottom, 140)
            .frame(maxWidth: OnboardingV3Layout.maxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .trackOnboardingProgressScroll(isCollapsed: $isProgressCollapsed)
        .onboardingProgressOverlay(step: 1, totalSteps: 8, isCollapsed: isProgressCollapsed)
        .safeAreaInset(edge: .bottom) {
            OnboardingV3BottomBar {
                OnboardingV3PrimaryButton(title: "다음", action: onNext)
            }
        }
        .onboardingV3Background()
    }
}

#Preview {
    OnboardingStep1GoalView(viewModel: OnboardingFlowViewModel(), onNext: {})
        .preferredColorScheme(.light)
}
