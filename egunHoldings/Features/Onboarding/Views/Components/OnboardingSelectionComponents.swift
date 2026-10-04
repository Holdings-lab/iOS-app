import SwiftUI

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
                .lineLimit(1)
                .minimumScaleFactor(0.78)
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

struct OnboardingV3OptionCard: View {
    let symbol: String
    let title: String
    var subtitle: String?
    var trailingText: String?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                Circle()
                    .fill(isSelected ? OnboardingV3Theme.selectedBackground : Color(hex: "F1F5F9"))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: symbol)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isSelected ? OnboardingV3Theme.primary : OnboardingV3Theme.muted)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.pretendard(16, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.pretendard(13, weight: .regular))
                            .foregroundStyle(OnboardingV3Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 8)

                if let trailingText {
                    Text(trailingText)
                        .font(.pretendard(13, weight: .semibold))
                        .foregroundStyle(isSelected ? OnboardingV3Theme.primary : OnboardingV3Theme.muted)
                }

                OnboardingV3Radio(isSelected: isSelected)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? OnboardingV3Theme.selectedBackground : OnboardingV3Theme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? OnboardingV3Theme.primary : OnboardingV3Theme.border, lineWidth: isSelected ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
    }
}
