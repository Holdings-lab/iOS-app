import SwiftUI

struct OnboardingPage4View: View {
    let userId: Int64?
    @ObservedObject var viewModel: OnboardingFlowViewModel
    let onBack: () -> Void
    let onStart: () -> Void

    private let summaryColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        VStack(spacing: 12) {
            FlowProgressHeader(currentStep: 5, totalSteps: 5, stepTitle: "맞춤 설정 · 완료", onBack: onBack)

            VStack(spacing: 10) {
                CompletionCheckAnimationView()

                VStack(spacing: 6) {
                    Text("준비가 끝났어요")
                        .font(.pretendard(25, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    Text(completionSubtitle)
                        .font(.pretendard(13, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)

            completionSummaryCard

            Text("이 설정은 조정 제안의 유지할 현금 비중, 한 자산 최대 비중, 매수/매도 민감도에 반영됩니다.")
                .font(.pretendard(11, weight: .medium))
                .foregroundStyle(Color.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true)

            if let errorMessage = viewModel.investmentProfileSaveError {
                InlineFeedbackText(message: errorMessage, tone: .error, asBanner: true)
            }

            Spacer(minLength: 0)

            FlowPrimaryButton(
                title: viewModel.isSavingInvestmentProfile ? "투자성향 저장 중..." : "저장하고 시작하기",
                isEnabled: !viewModel.isSavingInvestmentProfile,
                action: saveAndStart
            )
        }
        .padding(.horizontal, MidnightLayout.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(PFGradientBackground())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var completionSummaryCard: some View {
        FlowSurfaceCard(padding: 14, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("설정 요약")
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                LazyVGrid(columns: summaryColumns, spacing: 8) {
                    ForEach(summaryItems) { item in
                        CompletionSummaryTile(item: item)
                    }
                }
            }
        }
    }

    private var summaryItems: [CompletionSummaryItem] {
        [
            CompletionSummaryItem(title: "관심 섹터", value: viewModel.selectedSectorSummary),
            CompletionSummaryItem(title: "투자 성향", value: viewModel.selectedStyleSummary),
            CompletionSummaryItem(title: "투자 목적", value: viewModel.selectedInvestmentGoalSummary),
            CompletionSummaryItem(title: "투자 기간", value: viewModel.selectedInvestmentHorizonSummary),
            CompletionSummaryItem(title: "손실 기준", value: viewModel.selectedDrawdownSummary),
            CompletionSummaryItem(title: "하락 대응", value: viewModel.selectedDownturnBehaviorSummary),
            CompletionSummaryItem(title: "현금 비중", value: viewModel.selectedTargetCashWeightSummary),
            CompletionSummaryItem(title: "투자 방식", value: viewModel.selectedAssetPreferenceSummary),
            CompletionSummaryItem(title: "연결 계좌", value: viewModel.connectedInstitutionSummary)
        ]
    }

    private var completionSubtitle: String {
        if viewModel.connectedInstitution == nil {
            return "계좌는 나중에 연결하고, 선택한 조정 기준으로 홈을 구성해요"
        }

        return "선택한 조정 기준으로 홈을 구성해요"
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
    OnboardingPage4View(userId: 1, viewModel: OnboardingFlowViewModel(), onBack: {}, onStart: {})
        .preferredColorScheme(.light)
}

private struct CompletionSummaryItem: Identifiable {
    let title: String
    let value: String

    var id: String { title }
}

private struct CompletionSummaryTile: View {
    let item: CompletionSummaryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(.pretendard(10, weight: .medium))
                .foregroundStyle(Color.textTertiary)

            Text(item.value)
                .font(.pretendard(12, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.subtle, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
