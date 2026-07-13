import SwiftUI

struct OnboardingStep2TargetAmountView: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    let onNext: () -> Void
    let onBack: () -> Void

    @State private var isProgressCollapsed = false
    @State private var sliderValue: Double = 0

    private var goal: FinancialGoal {
        viewModel.financialGoal
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            OnboardingProgressScrollAnchor()

            VStack(alignment: .leading, spacing: 24) {
                OnboardingV3StepHeader(step: 2, onBack: onBack)

                OnboardingV3QuestionHeader(
                    title: "목표 금액을 알려주세요",
                    subtitle: "\(goal.title) 목적으로 자주 설정하는 금액이에요"
                )

                VStack(spacing: 20) {
                    Text(OnboardingCurrencyFormatter.wonText(viewModel.targetAmount))
                        .font(.pretendard(32, weight: .bold))
                        .foregroundStyle(OnboardingV3Theme.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)

                    Slider(
                        value: $sliderValue,
                        in: goal.targetAmountSliderRange,
                        step: goal.targetAmountSliderStep
                    ) { editing in
                        guard !editing else { return }
                        viewModel.updateTargetAmount(Int64(sliderValue))
                    }
                    .tint(OnboardingV3Theme.primary)
                    .onChange(of: sliderValue) { _, newValue in
                        viewModel.updateTargetAmount(Int64(newValue))
                    }

                    HStack {
                        Text(OnboardingCurrencyFormatter.wonText(Int64(goal.targetAmountSliderRange.lowerBound)))
                        Spacer()
                        Text(OnboardingCurrencyFormatter.wonText(Int64(goal.targetAmountSliderRange.upperBound)))
                    }
                    .font(.pretendard(12, weight: .medium))
                    .foregroundStyle(OnboardingV3Theme.muted)
                }
                .padding(16)
                .background(OnboardingV3Theme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(OnboardingV3Theme.border, lineWidth: 1)
                }
            }
            .padding(.horizontal, OnboardingV3Layout.horizontalPadding)
            .padding(.top, OnboardingV3Layout.progressContentTopPadding)
            .padding(.bottom, 140)
            .frame(maxWidth: OnboardingV3Layout.maxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .trackOnboardingProgressScroll(isCollapsed: $isProgressCollapsed)
        .onboardingProgressOverlay(step: 2, totalSteps: 8, isCollapsed: isProgressCollapsed)
        .safeAreaInset(edge: .bottom) {
            OnboardingV3BottomBar {
                OnboardingV3PrimaryButton(title: "다음", action: onNext)
            }
        }
        .onboardingV3Background()
        .onAppear {
            sliderValue = Double(viewModel.targetAmount)
        }
        .onChange(of: goal) { _, _ in
            sliderValue = Double(viewModel.targetAmount)
        }
    }
}

#Preview {
    OnboardingStep2TargetAmountView(viewModel: OnboardingFlowViewModel(), onNext: {}, onBack: {})
        .preferredColorScheme(.light)
}
