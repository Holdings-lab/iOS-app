import SwiftUI

struct OnboardingPage1View: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    let onNext: () -> Void
    var onBack: () -> Void = {}
    @State private var isProgressCollapsed = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var previewItem: OnboardingNewsPreviewItem? {
        viewModel.previewItems.first
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            OnboardingProgressScrollAnchor()

            VStack(alignment: .leading, spacing: 24) {
                OnboardingV3StepHeader(step: 1, onBack: onBack)

                OnboardingV3QuestionHeader(
                    title: "어떤 산업을 주로 보시나요?",
                    subtitle: "선택하면 아래 뉴스 미리보기가 즉시 바뀌어요"
                )

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.allSectors) { sector in
                        SectorSelectionCard(
                            sector: sector,
                            isSelected: viewModel.selectedSectors.contains(sector)
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.toggleSector(sector)
                            }
                        }
                    }
                }

                SectorNewsPreviewCard(item: previewItem)
            }
            .padding(.horizontal, OnboardingV3Layout.horizontalPadding)
            .padding(.top, OnboardingV3Layout.progressContentTopPadding)
            .padding(.bottom, 120)
            .frame(maxWidth: OnboardingV3Layout.maxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .trackOnboardingProgressScroll(isCollapsed: $isProgressCollapsed)
        .onboardingProgressOverlay(step: 1, isCollapsed: isProgressCollapsed)
        .safeAreaInset(edge: .bottom) {
            OnboardingV3BottomBar {
                OnboardingV3PrimaryButton(
                    title: "다음",
                    isEnabled: viewModel.canAdvanceFromSectorStep,
                    action: onNext
                )
            }
        }
        .onboardingV3Background()
    }
}

private struct SectorSelectionCard: View {
    let sector: InterestSector
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Text(sector.emoji)
                        .font(.system(size: 32))
                        .frame(width: 38, height: 38, alignment: .leading)

                    Spacer(minLength: 8)

                    OnboardingV3SelectionCheck(isSelected: isSelected)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(sector.title)
                        .font(.pretendard(15, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    Text(sector.description)
                        .font(.pretendard(13, weight: .regular))
                        .foregroundStyle(OnboardingV3Theme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
            .padding(14)
            .background(
                isSelected ? OnboardingV3Theme.selectedBackground : OnboardingV3Theme.cardBackground,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? OnboardingV3Theme.primary : OnboardingV3Theme.border, lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(ScalingSelectionButtonStyle())
    }
}

private struct SectorNewsPreviewCard: View {
    let item: OnboardingNewsPreviewItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("지금 이런 시그널이 분석되고 있어요")
                .font(.pretendard(13, weight: .semibold))
                .foregroundStyle(OnboardingV3Theme.muted)

            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(OnboardingV3Theme.selectedBackground)
                    .frame(width: 38, height: 38)
                    .overlay {
                        Image(systemName: "newspaper")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(OnboardingV3Theme.primary)
                    }

                VStack(alignment: .leading, spacing: 5) {
                    Text(item?.title ?? "관심 산업을 선택하면 관련 뉴스가 표시돼요")
                        .font(.pretendard(15, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(item?.summary ?? "선택한 섹터에 맞춰 정책 뉴스와 시장 신호를 먼저 보여드릴게요.")
                        .font(.pretendard(13, weight: .regular))
                        .foregroundStyle(OnboardingV3Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OnboardingV3Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(OnboardingV3Theme.border, lineWidth: 1)
        }
        .animation(.easeInOut(duration: 0.2), value: item?.id)
    }
}

private struct ScalingSelectionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    OnboardingPage1View(viewModel: OnboardingFlowViewModel(), onNext: {})
        .preferredColorScheme(.light)
}
