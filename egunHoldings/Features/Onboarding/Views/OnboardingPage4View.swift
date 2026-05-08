import SwiftUI

struct OnboardingPage4View: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    let onStart: () -> Void

    var body: some View {
        PFContentScrollView(
            spacing: 28,
            horizontalPadding: MidnightLayout.horizontal,
            topPadding: 16,
            bottomPadding: 120
        ) {
            FlowProgressHeader(currentStep: 4, totalSteps: 4, showsBack: false, onBack: {})

            Spacer(minLength: 24)

            VStack(spacing: 18) {
                CompletionCheckAnimationView()

                VStack(spacing: 10) {
                    Text("준비가 끝났어요")
                        .font(.pretendard(28, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    Text("맞춤 설정 기준으로 홈을 구성했어요")
                        .font(.pretendard(15, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)

            FlowSurfaceCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("설정 요약")
                        .font(.pretendard(15, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)

                    FlowSummaryRow(title: "관심 섹터", value: viewModel.selectedSectorSummary)
                    FlowSummaryRow(title: "투자 성향", value: viewModel.selectedStyleSummary)
                    FlowSummaryRow(title: "연결 계좌", value: viewModel.connectedInstitutionSummary)
                }
            }

            Text("설정은 언제든지 변경할 수 있어요")
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Spacer(minLength: 0)
        }
        .safeAreaInset(edge: .bottom) {
            FlowPrimaryButton(title: "시작하기 →", action: onStart)
                .padding(.horizontal, MidnightLayout.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 12)
        }
        .background(PFGradientBackground())
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    OnboardingPage4View(viewModel: OnboardingFlowViewModel(), onStart: {})
        .preferredColorScheme(.light)
}
