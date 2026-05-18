import SwiftUI

enum OnboardingV3Theme {
    static let primary = Color(hex: "2563EB")
    static let success = Color(hex: "10B981")
    static let warning = Color(hex: "F59E0B")
    static let background = Color(hex: "F0F4FF")
    static let cardBackground = Color.white
    static let selectedBackground = Color(hex: "EFF6FF")
    static let panelBackground = Color(hex: "F8FAFF")
    static let border = Color(hex: "E2E8F0")
    static let muted = Color(hex: "94A3B8")
}

enum OnboardingV3Layout {
    static let maxWidth: CGFloat = 390
    static let horizontalPadding: CGFloat = 24
    static let bottomButtonHeight: CGFloat = 52
    static let progressTop: CGFloat = 0
    static let progressHorizontalPadding: CGFloat = 20
    static let progressExpandedHeight: CGFloat = 44
    static let progressCollapsedHeight: CGFloat = 20
    static let progressContentTopPadding: CGFloat = progressExpandedHeight
}

struct OnboardingV3StepHeader: View {
    let step: Int
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                OnboardingV3BackButton(action: onBack)

                Spacer()
            }
        }
    }
}

struct OnboardingV3BackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .frame(width: 34, height: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("뒤로")
    }
}

struct ProgressBar: View {
    let step: Int
    let isCollapsed: Bool

    @State private var showsLabel = true
    @State private var usesCollapsedLayout = false

    private var progress: CGFloat {
        CGFloat(step) / 4
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: usesCollapsedLayout ? 0 : 6) {
            if !usesCollapsedLayout {
                Text("맞춤 설정 · \(step)/4")
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

private enum OnboardingProgressCoordinateSpace {
    static let name = "OnboardingProgressScrollSpace"
}

private struct OnboardingProgressScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct OnboardingV3QuestionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.pretendard(28, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.pretendard(15, weight: .regular))
                .foregroundStyle(OnboardingV3Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 12)
    }
}

struct OnboardingV3BottomBar<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, OnboardingV3Layout.horizontalPadding)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .frame(maxWidth: OnboardingV3Layout.maxWidth)
            .background(
                LinearGradient(
                    colors: [
                        OnboardingV3Theme.background.opacity(0),
                        OnboardingV3Theme.background.opacity(0.92),
                        OnboardingV3Theme.background
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
    }
}

struct OnboardingV3PrimaryButton: View {
    let title: String
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.pretendard(16, weight: .semibold))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: OnboardingV3Layout.bottomButtonHeight)
                .background(OnboardingV3Theme.primary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .opacity(isEnabled ? 1 : 0.4)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

struct OnboardingV3SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.pretendard(16, weight: .semibold))
                .foregroundStyle(OnboardingV3Theme.primary)
                .frame(maxWidth: .infinity)
                .frame(height: OnboardingV3Layout.bottomButtonHeight)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(OnboardingV3Theme.border, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

struct OnboardingV3SelectionCheck: View {
    let isSelected: Bool

    var body: some View {
        Circle()
            .fill(isSelected ? OnboardingV3Theme.primary : Color.clear)
            .frame(width: 22, height: 22)
            .overlay {
                Circle()
                    .stroke(isSelected ? OnboardingV3Theme.primary : OnboardingV3Theme.border, lineWidth: 1)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.white)
                }
            }
            .accessibilityHidden(true)
    }
}

struct OnboardingV3Radio: View {
    let isSelected: Bool

    var body: some View {
        Circle()
            .stroke(isSelected ? OnboardingV3Theme.primary : OnboardingV3Theme.border, lineWidth: isSelected ? 5 : 1.4)
            .frame(width: 22, height: 22)
            .accessibilityHidden(true)
    }
}

struct OnboardingV3ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(OnboardingV3Theme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
    }
}

extension View {
    func onboardingV3Background() -> some View {
        modifier(OnboardingV3ScreenBackground())
    }

    func trackOnboardingProgressScroll(isCollapsed: Binding<Bool>) -> some View {
        coordinateSpace(name: OnboardingProgressCoordinateSpace.name)
            .onPreferenceChange(OnboardingProgressScrollOffsetKey.self) { offset in
                let nextValue = offset < -10
                guard isCollapsed.wrappedValue != nextValue else { return }
                isCollapsed.wrappedValue = nextValue
            }
    }

    func onboardingProgressOverlay(step: Int, isCollapsed: Bool) -> some View {
        overlay(alignment: .top) {
            ProgressBar(step: step, isCollapsed: isCollapsed)
                .padding(.top, OnboardingV3Layout.progressTop)
        }
    }
}
