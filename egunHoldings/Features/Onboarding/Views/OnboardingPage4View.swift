import SwiftUI

struct OnboardingPage4View: View {
    let userId: Int64?
    @ObservedObject var viewModel: OnboardingFlowViewModel
    let onStart: () -> Void

    var body: some View {
        PFContentScrollView(
            spacing: 28,
            horizontalPadding: MidnightLayout.horizontal,
            topPadding: 16,
            bottomPadding: 120
        ) {
            FlowProgressHeader(currentStep: 5, totalSteps: 5, stepTitle: "맞춤 설정 · 완료", showsBack: false, onBack: {})

            Spacer(minLength: 24)

            VStack(spacing: 18) {
                CompletionCheckAnimationView()

                VStack(spacing: 10) {
                    Text("준비가 끝났어요")
                        .font(.pretendard(28, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    Text(completionSubtitle)
                        .font(.pretendard(15, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
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
                    FlowSummaryRow(title: "투자 목적", value: viewModel.selectedInvestmentGoalSummary)
                    FlowSummaryRow(title: "투자 기간", value: viewModel.selectedInvestmentHorizonSummary)
                    FlowSummaryRow(title: "손실 기준", value: viewModel.selectedDrawdownSummary)
                    FlowSummaryRow(title: "하락 대응", value: viewModel.selectedDownturnBehaviorSummary)
                    FlowSummaryRow(title: "현금 비중", value: viewModel.selectedTargetCashWeightSummary)
                    FlowSummaryRow(title: "투자 방식", value: viewModel.selectedAssetPreferenceSummary)
                    FlowSummaryRow(title: "연결 계좌", value: viewModel.connectedInstitutionSummary)
                }
            }

            Text("이 설정은 리밸런싱 추천의 목표 현금 비중, 단일 자산 한도, 매수/매도 민감도에 반영됩니다.")
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true)

            if let errorMessage = viewModel.investmentProfileSaveError {
                InlineFeedbackText(message: errorMessage, tone: .error, asBanner: true)
            }

            Spacer(minLength: 0)
        }
        .safeAreaInset(edge: .bottom) {
            FlowPrimaryButton(
                title: viewModel.isSavingInvestmentProfile ? "투자성향 저장 중..." : "저장하고 시작하기",
                isEnabled: !viewModel.isSavingInvestmentProfile,
                action: saveAndStart
            )
                .padding(.horizontal, MidnightLayout.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 12)
        }
        .background(PFGradientBackground())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var completionSubtitle: String {
        if viewModel.connectedInstitution == nil {
            return "계좌는 나중에 연결하고, 선택한 리밸런싱 기준으로 홈을 구성해요"
        }

        return "선택한 리밸런싱 기준으로 홈을 구성해요"
    }

    private func saveAndStart() {
        Task {
            let didSave = await viewModel.saveInvestmentProfile(userId: userId)
            guard didSave else { return }
            onStart()
        }
    }
}

#Preview {
    OnboardingPage4View(userId: 1, viewModel: OnboardingFlowViewModel(), onStart: {})
        .preferredColorScheme(.light)
}
