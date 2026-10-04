import SwiftUI

struct OnboardingV3StepHeader: View {
    let step: Int
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                LiquidGlassBackButton(accessibilityLabel: "뒤로", action: onBack)

                Spacer()
            }
        }
    }
}

struct ProgressBar: View {
    let step: Int
    let totalSteps: Int
    let isCollapsed: Bool

    @State private var showsLabel = true
    @State private var usesCollapsedLayout = false

    private var progress: CGFloat {
        CGFloat(step) / CGFloat(max(totalSteps, 1))
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: usesCollapsedLayout ? 0 : 6) {
            if !usesCollapsedLayout {
                Text("맞춤 설정 · \(step)/\(totalSteps)")
                    .font(.pretendard(11, weight: .medium))
                    .foregroundStyle(OnboardingV3Theme.muted)
                    .opacity(showsLabel ? 1 : 0)
                    .frame(height: showsLabel ? nil : 0)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(OnboardingV3Theme.border)

                    Capsule()
                        .fill(OnboardingV3Theme.primary)
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: usesCollapsedLayout ? 2 : 3)
        }
        .padding(.horizontal, OnboardingV3Layout.progressHorizontalPadding)
        .padding(.top, usesCollapsedLayout ? 8 : 10)
        .padding(.bottom, usesCollapsedLayout ? 8 : 10)
        .frame(maxWidth: .infinity)
        .frame(height: usesCollapsedLayout ? OnboardingV3Layout.progressCollapsedHeight : OnboardingV3Layout.progressExpandedHeight)
        .background(OnboardingV3Theme.background.ignoresSafeArea(edges: .top))
        .zIndex(100)
        .onAppear {
            usesCollapsedLayout = isCollapsed
            showsLabel = !isCollapsed
        }
        .onChange(of: isCollapsed) { _, newValue in
            transition(toCollapsed: newValue)
        }
    }

    private func transition(toCollapsed isCollapsed: Bool) {
        if isCollapsed {
            withAnimation(.easeInOut(duration: 0.15)) {
                showsLabel = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    usesCollapsedLayout = true
                }
            }
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                usesCollapsedLayout = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showsLabel = true
                }
            }
        }
    }
}

struct OnboardingProgressScrollAnchor: View {
    var body: some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: OnboardingProgressScrollOffsetKey.self,
                value: proxy.frame(in: .named(OnboardingProgressCoordinateSpace.name)).minY
            )
        }
        .frame(height: 0)
    }
}

enum OnboardingProgressCoordinateSpace {
    static let name = "OnboardingProgressScrollSpace"
}

struct OnboardingProgressScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
