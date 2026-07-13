import SwiftUI

struct OnboardingStep3HorizonView: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    let onNext: () -> Void
    let onBack: () -> Void

    @State private var isProgressCollapsed = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            OnboardingProgressScrollAnchor()

            VStack(alignment: .leading, spacing: 24) {
                OnboardingV3StepHeader(step: 3, onBack: onBack)

                OnboardingV3QuestionHeader(
                    title: "이 자금은 언제쯤 필요하신가요?",
                    subtitle: "투자 기간에 맞춰 자산 배분 기준을 조정해요"
                )

                VStack(spacing: 12) {
                    ForEach(InvestmentHorizon.allCases) { horizon in
                        OnboardingV3OptionCard(
                            symbol: horizon.symbol,
                            title: horizon.title,
                            subtitle: horizon.subtitle,
                            isSelected: viewModel.investmentHorizon == horizon
                        ) {
                            viewModel.investmentHorizon = horizon
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
        .onboardingProgressOverlay(step: 3, totalSteps: 8, isCollapsed: isProgressCollapsed)
        .safeAreaInset(edge: .bottom) {
            OnboardingV3BottomBar {
                OnboardingV3PrimaryButton(
                    title: "다음",
                    isEnabled: viewModel.investmentHorizon != nil,
                    action: onNext
                )
            }
        }
        .onboardingV3Background()
    }
}

#Preview {
    OnboardingStep3HorizonView(viewModel: OnboardingFlowViewModel(), onNext: {}, onBack: {})
        .preferredColorScheme(.light)
}
