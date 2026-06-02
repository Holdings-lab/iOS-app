import SwiftUI

struct OnboardingPage1View: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    let onNext: () -> Void
    var onBack: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isProgressCollapsed = false

    private var selectionAnimation: Animation? {
        reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7)
    }

    private var bottomButtonTitle: String {
        if viewModel.canAdvanceFromKeywordStep {
            return "다음"
        }

        return "3개 이상 선택해주세요 (현재 \(viewModel.keywordSelectionCount)개)"
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            OnboardingProgressScrollAnchor()

            VStack(alignment: .leading, spacing: 24) {
                OnboardingV3StepHeader(step: 1, onBack: onBack)

                OnboardingV3QuestionHeader(
                    title: "어떤 주제에 관심 있으세요?",
                    subtitle: "3개 이상 선택하면 맞춤 시그널을 받을 수 있어요"
                )

                VStack(alignment: .leading, spacing: 20) {
                    ForEach(viewModel.allKeywordCategories) { category in
                        KeywordCategorySection(
                            category: category,
                            selectedKeywords: viewModel.selectedKeywords,
                            animation: selectionAnimation
                        ) { keyword in
                            withAnimation(selectionAnimation) {
                                viewModel.toggleKeyword(keyword)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, OnboardingV3Layout.horizontalPadding)
            .padding(.top, OnboardingV3Layout.progressContentTopPadding)
            .padding(.bottom, 220)
            .frame(maxWidth: OnboardingV3Layout.maxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .trackOnboardingProgressScroll(isCollapsed: $isProgressCollapsed)
        .onboardingProgressOverlay(step: 1, isCollapsed: isProgressCollapsed)
        .safeAreaInset(edge: .bottom) {
            OnboardingV3BottomBar {
                VStack(spacing: 12) {
                    KeywordNewsPreviewCard(
                        preview: viewModel.keywordNewsPreview,
                        animation: reduceMotion ? nil : .easeInOut(duration: 0.2)
                    )

                    OnboardingV3PrimaryButton(
                        title: bottomButtonTitle,
                        isEnabled: viewModel.canAdvanceFromKeywordStep,
                        action: onNext
                    )
                }
            }
        }
        .onboardingV3Background()
    }
}

private struct KeywordCategorySection: View {
    let category: InterestKeywordCategory
    let selectedKeywords: Set<InterestKeyword>
    let animation: Animation?
    let onToggle: (InterestKeyword) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(category.displayName.uppercased())
                .font(.pretendard(12, weight: .semibold))
                .foregroundStyle(Color.textTertiary)

            FlowLayout(horizontalSpacing: 8, verticalSpacing: 10) {
                ForEach(category.keywords) { keyword in
                    KeywordChip(
                        keyword: keyword,
                        isSelected: selectedKeywords.contains(keyword),
                        animation: animation
                    ) {
                        onToggle(keyword)
                    }
                }
            }
        }
    }
}

private struct KeywordChip: View {
    let keyword: InterestKeyword
    let isSelected: Bool
    let animation: Animation?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 5) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .transition(.scale.combined(with: .opacity))
                }

                Text(keyword.tag)
                    .font(.pretendard(14, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .foregroundStyle(isSelected ? Color.brand : Color.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
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

private struct KeywordNewsPreviewCard: View {
    let preview: String
    let animation: Animation?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "newspaper")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.textTertiary)
                .frame(width: 18, height: 18)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 5) {
                Text("선택 기반 미리보기")
                    .font(.pretendard(11, weight: .semibold))
                    .foregroundStyle(Color.brand)

                Text(preview)
                    .id(preview)
                    .font(.pretendard(14, weight: .regular))
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "F8F9FA"), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .animation(animation, value: preview)
    }
}

private struct FlowLayout: Layout {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    init(horizontalSpacing: CGFloat = 8, verticalSpacing: CGFloat = 10) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .greatestFiniteMagnitude
        let layout = makeLayout(maxWidth: maxWidth, subviews: subviews)

        return CGSize(
            width: proposal.width ?? layout.width,
            height: layout.height
        )
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if xOffset > 0, xOffset + size.width > bounds.width {
                xOffset = 0
                yOffset += rowHeight + verticalSpacing
                rowHeight = 0
            }

            subview.place(
                at: CGPoint(x: bounds.minX + xOffset, y: bounds.minY + yOffset),
                proposal: ProposedViewSize(size)
            )

            xOffset += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }
    }

    private func makeLayout(maxWidth: CGFloat, subviews: Subviews) -> (width: CGFloat, height: CGFloat) {
        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0
        var rowHeight: CGFloat = 0
        var measuredWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if xOffset > 0, xOffset + size.width > maxWidth {
                measuredWidth = max(measuredWidth, xOffset - horizontalSpacing)
                xOffset = 0
                yOffset += rowHeight + verticalSpacing
                rowHeight = 0
            }

            xOffset += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }

        measuredWidth = max(measuredWidth, xOffset > 0 ? xOffset - horizontalSpacing : 0)

        return (measuredWidth, yOffset + rowHeight)
    }
}

#Preview {
    OnboardingPage1View(viewModel: OnboardingFlowViewModel(), onNext: {})
        .preferredColorScheme(.light)
}
