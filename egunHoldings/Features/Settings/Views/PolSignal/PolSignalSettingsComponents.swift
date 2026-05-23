import SwiftUI

struct PolSignalSettingSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.pretendard(13, weight: .semibold))
                .foregroundStyle(PSColor.textSecondary)

            VStack(spacing: 0) {
                content
            }
            .background(PSColor.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(PSColor.border, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

struct PolSignalSettingsListRow: View {
    enum Tone {
        case normal
        case danger
    }

    let title: String
    var subtitle: String?
    var tone: Tone = .normal

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(tone == .danger ? PSColor.danger : PSColor.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.pretendard(12, weight: .regular))
                        .foregroundStyle(PSColor.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 12)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(PSColor.textFaint)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }
}

struct PolSignalToggleRow: View {
    let title: String
    var subtitle: String?
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(PSColor.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.pretendard(12, weight: .regular))
                        .foregroundStyle(PSColor.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            PolSignalToggle(isOn: $isOn)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(minHeight: 52)
    }
}

struct PolSignalToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                isOn.toggle()
            }
        } label: {
            Capsule(style: .continuous)
                .fill(isOn ? PSColor.primary : PSColor.border)
                .frame(width: 44, height: 26)
                .overlay(alignment: isOn ? .trailing : .leading) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 22, height: 22)
                        .padding(2)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOn ? "켬" : "끔")
    }
}

struct PolSignalSegmentRow: View {
    let title: String
    let options: [String]
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.pretendard(14, weight: .semibold))
                .foregroundStyle(PSColor.textPrimary)

            Spacer()

            HStack(spacing: 3) {
                ForEach(options, id: \.self) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selection = option
                        }
                    } label: {
                        Text(option)
                            .font(.pretendard(12, weight: .semibold))
                            .foregroundStyle(selection == option ? PSColor.textPrimary : PSColor.textSecondary)
                            .padding(.horizontal, 9)
                            .frame(height: 28)
                            .background(selection == option ? PSColor.surface : Color.clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .shadow(color: selection == option ? PSColor.cardShadow : Color.clear, radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(Color(hex: "F1F5F9"), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(minHeight: 52)
    }
}

struct PolSignalCheckChip: View {
    let title: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.pretendard(13, weight: .semibold))
                .foregroundStyle(isOn ? PSColor.primary : PSColor.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(isOn ? PSColor.primarySoft : PSColor.surfaceAlt, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isOn ? PSColor.primary : PSColor.rule, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

struct PolSignalSettingsDivider: View {
    var body: some View {
        Divider()
            .background(PSColor.rule)
            .padding(.leading, 20)
    }
}
