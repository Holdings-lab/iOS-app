import SwiftUI

struct OnboardingStep4DrawdownView: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    let onNext: () -> Void
    let onBack: () -> Void

    @State private var isProgressCollapsed = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            OnboardingProgressScrollAnchor()

            VStack(alignment: .leading, spacing: 24) {
                OnboardingV3StepHeader(step: 4, onBack: onBack)

                OnboardingV3QuestionHeader(
                    title: "1,000만원을 투자했다고 가정할게요",
                    subtitle: "어디까지 떨어져도 버틸 수 있나요?"
                )

                VStack(spacing: 12) {
                    ForEach(MaxDrawdownTolerance.onboardingOptions) { tolerance in
                        OnboardingV3OptionCard(
                            symbol: tolerance.symbol,
                            title: tolerance.title,
                            trailingText: tolerance.onboardingAssumedAmountText,
                            isSelected: viewModel.maxDrawdownTolerance == tolerance
                        ) {
                            viewModel.maxDrawdownTolerance = tolerance
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
        .onboardingProgressOverlay(step: 4, totalSteps: 8, isCollapsed: isProgressCollapsed)
        .safeAreaInset(edge: .bottom) {
            OnboardingV3BottomBar {
                OnboardingV3PrimaryButton(
                    title: "다음",
                    isEnabled: viewModel.maxDrawdownTolerance != nil,
                    action: onNext
                )
            }
        }
        .onboardingV3Background()
    }
}

#Preview {
    OnboardingStep4DrawdownView(viewModel: OnboardingFlowViewModel(), onNext: {}, onBack: {})
        .preferredColorScheme(.light)
}
