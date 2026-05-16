import SwiftUI

enum OnboardingV3Theme {
    static let primary = Color(hex: "2563EB")
    static let background = Color(hex: "F0F4FF")
    static let cardBackground = Color.white
    static let selectedBackground = Color(hex: "EFF6FF")
    static let panelBackground = Color(hex: "F8FAFF")
    static let border = Color(hex: "E2E8F0")
    static let muted = Color.textTertiary
}

enum OnboardingV3Layout {
    static let maxWidth: CGFloat = 390
    static let horizontalPadding: CGFloat = 24
    static let bottomButtonHeight: CGFloat = 52
}

struct OnboardingV3StepHeader: View {
    let step: Int
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 12) {
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

                Text("맞춤 설정 · \(step)/4")
                    .font(.pretendard(13, weight: .medium))
                    .foregroundStyle(OnboardingV3Theme.muted)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(OnboardingV3Theme.border)

                    Rectangle()
                        .fill(OnboardingV3Theme.primary)
                        .frame(width: proxy.size.width * CGFloat(step) / 4)
                }
            }
            .frame(height: 2)
        }
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
}
