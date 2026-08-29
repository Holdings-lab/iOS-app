import SwiftUI

struct OnboardingStep6WatchAssetsView: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    let onNext: () -> Void
    let onBack: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isProgressCollapsed = false
    @State private var isRevealed = false

    private var selectionAnimation: Animation? {
        reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7)
    }

    private var bottomButtonTitle: String {
        if viewModel.canAdvanceFromWatchAssetsStep {
            return "다음"
        }

        return "1개 이상 선택해주세요"
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            OnboardingProgressScrollAnchor()

            VStack(alignment: .leading, spacing: 24) {
                OnboardingV3StepHeader(step: 6, onBack: onBack)

                OnboardingV3QuestionHeader(
                    title: "관심 있는 분야를 골라주세요",
                    subtitle: "1개 이상 5개 이하로 선택할 수 있어요"
                )

                OnboardingV3FlowLayout(horizontalSpacing: 8, verticalSpacing: 10) {
                    ForEach(WatchAssetSector.allCases) { sector in
                        WatchAssetChip(
                            sector: sector,
                            isSelected: viewModel.selectedWatchAssets.contains(sector),
                            animation: selectionAnimation
                        ) {
                            withAnimation(selectionAnimation) {
                                viewModel.toggleWatchAsset(sector)
                            }
                        }
                    }
                }
                .onboardingReveal(isRevealed: isRevealed)

                WatchAssetsFootnote()
                    .onboardingReveal(isRevealed: isRevealed, index: 1)
            }
            .padding(.horizontal, OnboardingV3Layout.horizontalPadding)
            .padding(.top, OnboardingV3Layout.progressContentTopPadding)
            .padding(.bottom, 140)
            .frame(maxWidth: OnboardingV3Layout.maxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .trackOnboardingProgressScroll(isCollapsed: $isProgressCollapsed)
        .onboardingProgressOverlay(step: 6, totalSteps: 8, isCollapsed: isProgressCollapsed)
        .safeAreaInset(edge: .bottom) {
            OnboardingV3BottomBar {
                OnboardingV3PrimaryButton(
                    title: bottomButtonTitle,
                    isEnabled: viewModel.canAdvanceFromWatchAssetsStep,
                    action: onNext
                )
            }
        }
        .onboardingV3Background()
        .onboardingRevealSequence(isRevealed: $isRevealed, reduceMotion: reduceMotion)
    }
}

private struct WatchAssetChip: View {
    let sector: WatchAssetSector
    let isSelected: Bool
    let animation: Animation?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(sector.emoji)
                    .font(.system(size: 14))

                Text(sector.title)
                    .font(.pretendard(14, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .foregroundStyle(isSelected ? Color.brand : Color.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                isSelected ? Color.brand.opacity(0.12) : Color(hex: "F3F4F6"),
                in: Capsule(style: .continuous)
            )
            .overlay {
                Capsule(style: .continuous)
                    .stroke(isSelected ? Color.brand : Color.clear, lineWidth: 1)
            }
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .animation(animation, value: isSelected)
    }
}

private struct WatchAssetsFootnote: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(OnboardingV3Theme.primary)
                .padding(.top, 1)

            Text("계좌를 연결하지 않아도 이 선택만으로 오늘 탭의 뉴스 섹션이 관심 분야 기준으로 채워져요")
                .font(.pretendard(13, weight: .regular))
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OnboardingV3Theme.selectedBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    OnboardingStep6WatchAssetsView(viewModel: OnboardingFlowViewModel(), onNext: {}, onBack: {})
        .preferredColorScheme(.light)
}
