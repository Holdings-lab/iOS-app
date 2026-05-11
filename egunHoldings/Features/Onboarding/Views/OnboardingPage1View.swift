import SwiftUI

struct OnboardingPage1View: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    let onNext: () -> Void
    var onBack: () -> Void = {}

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var previewKey: String {
        viewModel.previewItems.map(\.id).joined(separator: "-")
    }

    var body: some View {
        PFContentScrollView(
            alignment: .leading,
            spacing: 24,
            horizontalPadding: MidnightLayout.horizontal,
            topPadding: 16,
            bottomPadding: 32
        ) {
            FlowProgressHeader(currentStep: 1, totalSteps: 4, onBack: onBack)

            VStack(alignment: .leading, spacing: 10) {
                Text("어떤 산업을 주로 보시나요?")
                    .font(.pretendard(28, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text("선택한 산업 중심으로 뉴스와 시그널을 우선 정리해요")
                    .font(.pretendard(16, weight: .regular))
                    .foregroundStyle(Color.textTertiary)
            }

            FlowInfoHint(text: "선택하면 아래 뉴스 미리보기가 즉시 바뀌어요")

            ZStack(alignment: .bottom) {
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

                LinearGradient(
                    colors: [.clear, Color.canvas.opacity(0.96)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 54)
                .allowsHitTesting(false)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                ZStack {
                    CompactNewsPreviewStrip(items: viewModel.previewItems)
                        .id(previewKey)
                        .transition(.opacity)
                }
                .animation(.easeInOut(duration: 0.2), value: previewKey)

                FlowPrimaryButton(
                    title: "다음",
                    isEnabled: viewModel.canAdvanceFromSectorStep,
                    action: onNext
                )
            }
            .padding(.horizontal, MidnightLayout.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background(
                LinearGradient(
                    colors: [
                        Color.canvas.opacity(0),
                        Color.canvas.opacity(0.88),
                        Color.canvas
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
        .background(PFGradientBackground())
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct SectorSelectionCard: View {
    let sector: InterestSector
    let isSelected: Bool
    let onTap: () -> Void

    @GestureState private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Text(sector.emoji)
                        .font(.system(size: 24))

                    Spacer()

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isSelected ? Color.brand : Color.subtle)
                        .frame(width: 20, height: 20)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(isSelected ? Color.brand : Color.divider, lineWidth: 1)

                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(sector.title)
                        .font(.pretendard(16, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)

                    Text(sector.description)
                        .font(.pretendard(12, weight: .regular))
                        .foregroundStyle(Color.textTertiary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 148, alignment: .leading)
            .padding(16)
            .background(
                isSelected ? Color.brand.opacity(0.13) : Color.subtle,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.brand.opacity(0.45) : Color.hairline, lineWidth: 1)
            }
            .scaleEffect(isPressed ? 0.96 : 1)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($isPressed) { _, state, _ in
                    state = true
                }
        )
    }
}

private struct CompactNewsPreviewStrip: View {
    let items: [OnboardingNewsPreviewItem]

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.brandTintBg)
                    .frame(width: 34, height: 34)

                Image(systemName: "newspaper")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.brand)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("선택 기반 미리보기")
                    .font(.pretendard(11, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)

                Text(items.first?.title ?? "관심 산업을 선택해주세요")
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if items.count > 1 {
                Text("+\(items.count - 1)")
                    .font(.pretendard(12, weight: .semibold))
                    .foregroundStyle(Color.brand)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.brandTintBg, in: Capsule(style: .continuous))
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 58)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.elevated)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.hairline, lineWidth: 1)
                }
        )
    }
}

#Preview {
    OnboardingPage1View(viewModel: OnboardingFlowViewModel(), onNext: {})
        .preferredColorScheme(.light)
}
