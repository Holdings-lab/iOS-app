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
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    HStack {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundStyle(Color.textPrimary)
                                .frame(width: 34, height: 34)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("뒤로")

                        Spacer()
                    }

                    VStack(spacing: 12) {
                        CompletionCheckmarkIcon()

                        VStack(spacing: 8) {
                            Text("준비가 끝났어요")
                                .font(.pretendard(28, weight: .bold))
                                .foregroundStyle(Color.textPrimary)

                            Text("선택한 조정 기준으로 홈을 구성해요")
                                .font(.pretendard(15, weight: .regular))
                                .foregroundStyle(OnboardingV3Theme.muted)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    completionSummaryCard

                    Text("이 설정은 조정 제안의 유지할 현금 비중, 한 자산 최대 비중, 매수/매도 민감도에 반영됩니다")
                        .font(.pretendard(13, weight: .regular))
                        .foregroundStyle(OnboardingV3Theme.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    if let errorMessage = viewModel.investmentProfileSaveError {
                        InlineFeedbackText(message: errorMessage, tone: .error, asBanner: true)
                    }
                }
                .padding(.horizontal, OnboardingV3Layout.horizontalPadding)
                .padding(.top, 16)
                .padding(.bottom, 112)
                .frame(maxWidth: OnboardingV3Layout.maxWidth)
                .frame(maxWidth: .infinity)
            }

            OnboardingV3BottomBar {
                OnboardingV3PrimaryButton(
                    title: viewModel.isSavingInvestmentProfile ? "저장 중..." : "저장하고 시작하기",
                    isEnabled: !viewModel.isSavingInvestmentProfile,
                    action: saveAndStart
                )
            }
        }
        .onboardingV3Background()
    }

    private var completionSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("설정 요약")
                .font(.pretendard(15, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            LazyVGrid(columns: summaryColumns, spacing: 8) {
                ForEach(summaryItems) { item in
                    CompletionSummaryTile(item: item)
                }
            }
        }
        .padding(16)
        .background(OnboardingV3Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(OnboardingV3Theme.border, lineWidth: 1)
        }
    }

    private var summaryItems: [CompletionSummaryItem] {
        var items = [
            CompletionSummaryItem(title: "관심 섹터", value: viewModel.selectedSectorSummary),
            CompletionSummaryItem(title: "투자 성향", value: viewModel.selectedStyleSummary),
            CompletionSummaryItem(title: "투자 목적", value: viewModel.selectedInvestmentGoalSummary),
            CompletionSummaryItem(title: "투자 기간", value: viewModel.selectedInvestmentHorizonSummary),
            CompletionSummaryItem(title: "손실 기준", value: viewModel.selectedDrawdownSummary),
            CompletionSummaryItem(title: "하락 대응", value: viewModel.selectedDownturnBehaviorSummary),
            CompletionSummaryItem(title: "현금 비중", value: viewModel.selectedTargetCashWeightSummary),
            CompletionSummaryItem(title: "투자 방식", value: viewModel.selectedAssetPreferenceSummary)
        ]

        if viewModel.connectedInstitution != nil {
            items.append(CompletionSummaryItem(title: "연결 계좌", value: viewModel.connectedInstitutionSummary))
        }

        return items
    }

    private func saveAndStart() {
        Task {
            let didSave = await viewModel.saveInvestmentProfile(userId: userId)
            guard didSave else { return }
            onStart()
        }
    }
}

private struct CompletionCheckmarkIcon: View {
    var body: some View {
        Circle()
            .fill(OnboardingV3Theme.primary)
            .frame(width: 48, height: 48)
            .overlay {
                Image(systemName: "checkmark")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.white)
            }
            .shadow(color: OnboardingV3Theme.primary.opacity(0.22), radius: 18, x: 0, y: 8)
    }
}

private struct CompletionSummaryItem: Identifiable {
    let title: String
    let value: String

    var id: String { title }
}

private struct CompletionSummaryTile: View {
    let item: CompletionSummaryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(item.title)
                .font(.pretendard(11, weight: .medium))
                .foregroundStyle(OnboardingV3Theme.muted)

            Text(item.value)
                .font(.pretendard(15, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(hex: "F8FAFC"), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

#Preview {
    OnboardingPage4View(userId: 1, viewModel: OnboardingFlowViewModel(), onBack: {}, onStart: {})
        .preferredColorScheme(.light)
}
