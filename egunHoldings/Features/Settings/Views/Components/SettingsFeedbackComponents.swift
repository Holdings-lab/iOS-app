import SwiftUI

// MARK: - Status badge

enum BadgeTone {
    case ok, warn, error, soon

    var background: Color {
        switch self {
        case .ok: return Color.successBg
        case .warn: return Color.warningBg
        case .error: return Color.downBg
        case .soon: return Color.muted
        }
    }

    var foreground: Color {
        switch self {
        case .ok: return Color.success
        case .warn: return Color.warning
        case .error: return Color.trendDown
        case .soon: return Color.textTertiary
        }
    }
}

struct StatusBadge: View {
    let tone: BadgeTone
    let text: String

    var body: some View {
        Text(text)
            .font(.pretendard(11, weight: .bold))
            .foregroundStyle(tone.foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(tone.background, in: Capsule())
    }
}

// MARK: - Callout

enum CalloutTone {
    case info, warn

    var background: Color {
        switch self {
        case .info: return Color.brandTintBg
        case .warn: return Color.warningBg
        }
    }

    var foreground: Color {
        switch self {
        case .info: return Color.brand
        case .warn: return Color.warning
        }
    }
}

struct CalloutView<Content: View>: View {
    let tone: CalloutTone
    var icon = "info.circle.fill"
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tone.foreground)
                .padding(.top, 1)

            content()
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.textPrimary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tone.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
// MARK: - Toast

struct SettingsToast: View {
    let message: String?

    var body: some View {
        Group {
            if let message {
                Text(message)
                    .font(.pretendard(13.5, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(hex: "0A0E27", alpha: 0.92), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: message)
    }
}
