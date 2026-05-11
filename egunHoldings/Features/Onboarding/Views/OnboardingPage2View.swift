import SwiftUI

struct OnboardingPage2View: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    let onBack: () -> Void
    let onNext: () -> Void

    var body: some View {
        PFContentScrollView(
            alignment: .leading,
            spacing: 24,
            horizontalPadding: MidnightLayout.horizontal,
            topPadding: 16,
            bottomPadding: 120
        ) {
            FlowProgressHeader(currentStep: 2, totalSteps: 5, stepTitle: "맞춤 설정 · 투자 성향", onBack: onBack)

            VStack(alignment: .leading, spacing: 10) {
                Text("투자 성향을 알려주세요")
                    .font(.pretendard(28, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text("같은 뉴스도 성향에 따라 강조할 자산이 달라져요")
                    .font(.pretendard(16, weight: .regular))
                    .foregroundStyle(Color.textTertiary)
            }

            VStack(spacing: 12) {
                ForEach(InvestmentStyleOption.allCases) { style in
                    InvestmentStyleCard(
                        style: style,
                        isSelected: viewModel.selectedStyle == style
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectStyle(style)
                        }
                    }
                }
            }

            if let selectedStyle = viewModel.selectedStyle {
                AnimatedPortfolioBarsCard(style: selectedStyle)
                    .id(selectedStyle.id)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .safeAreaInset(edge: .bottom) {
            FlowPrimaryButton(
                title: "다음",
                isEnabled: viewModel.canAdvanceFromStyleStep,
                action: onNext
            )
            .padding(.horizontal, MidnightLayout.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 12)
        }
        .background(PFGradientBackground())
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct InvestmentStyleCard: View {
    let style: InvestmentStyleOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(hex: style.tintHex, alpha: style.iconBackgroundOpacity))
                        .frame(width: 42, height: 42)

                    Text(style.emoji)
                        .font(.system(size: 19))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(style.title)
                        .font(.pretendard(16, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)

                    Text(style.subtitle)
                        .font(.pretendard(13, weight: .regular))
                        .foregroundStyle(Color.textTertiary)
                }

                Spacer()

                Circle()
                    .fill(isSelected ? Color.brand : Color.subtle)
                    .frame(width: 22, height: 22)
                    .overlay {
                        Circle()
                            .stroke(isSelected ? Color.brand : Color.divider, lineWidth: 1)

                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
            }
            .padding(16)
            .background(
                isSelected ? Color.brand.opacity(0.13) : Color.subtle,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.brand.opacity(0.45) : Color.hairline, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct AnimatedPortfolioBarsCard: View {
    let style: InvestmentStyleOption

    @State private var animateBars = false

    var body: some View {
        FlowSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("선택한 성향 기준 예시 포트폴리오")
                    .font(.pretendard(13, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)

                VStack(spacing: 14) {
                    ForEach(Array(style.allocations.enumerated()), id: \.element.id) { index, allocation in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(allocation.label)
                                    .font(.pretendard(14, weight: .medium))
                                    .foregroundStyle(Color.textPrimary)

                                Spacer()

                                Text("\(allocation.percentage)%")
                                    .font(.pretendard(13, weight: .semibold))
                                    .foregroundStyle(Color(hex: allocation.colorHex))
                            }

                            GeometryReader { proxy in
                                ZStack(alignment: .leading) {
                                    Capsule(style: .continuous)
                                        .fill(Color.subtle)

                                    Capsule(style: .continuous)
                                        .fill(Color(hex: allocation.colorHex))
                                        .frame(width: animateBars ? proxy.size.width * CGFloat(allocation.percentage) / 100 : 0)
                                        .animation(
                                            .easeInOut(duration: 0.32).delay(Double(index) * 0.08),
                                            value: animateBars
                                        )
                                }
                            }
                            .frame(height: 10)
                        }
                    }
                }
            }
        }
        .onAppear {
            animateBars = false
            withAnimation(.easeInOut(duration: 0.3)) {
                animateBars = true
            }
        }
    }
}

#Preview {
    OnboardingPage2View(viewModel: OnboardingFlowViewModel(), onBack: {}, onNext: {})
        .preferredColorScheme(.light)
}
