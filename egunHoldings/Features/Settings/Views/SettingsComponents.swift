import SwiftUI

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.pretendard(13, weight: .bold))
                .foregroundStyle(Color.textSecondary)

            VStack(spacing: 0) {
                content
            }
            .background(Color.elevated, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                    .stroke(Color.hairline, lineWidth: 1)
            }
        }
    }
}

struct SettingsNavigationLink<Destination: View>: View {
    let iconName: String
    let title: String
    let value: String
    let color: Color
    let destination: Destination

    init(
        iconName: String,
        title: String,
        value: String = "",
        color: Color = Color.brand,
        @ViewBuilder destination: () -> Destination
    ) {
        self.iconName = iconName
        self.title = title
        self.value = value
        self.color = color
        self.destination = destination()
    }

    var body: some View {
        NavigationLink {
            destination
        } label: {
            SettingsRowContent(
                iconName: iconName,
                title: title,
                value: value,
                color: color,
                showsChevron: true
            )
        }
        .buttonStyle(.plain)
    }
}

struct SettingsRowContent: View {
    let iconName: String
    let title: String
    let value: String
    let color: Color
    let showsChevron: Bool

    var body: some View {
        HStack(spacing: 12) {
            SettingsIcon(iconName: iconName, color: color)

            Text(title)
                .font(.pretendard(14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            Spacer()

            if !value.isEmpty {
                Text(value)
                    .font(.pretendard(12, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textDisabled)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct SettingsToggleRow: View {
    let iconName: String
    let title: String
    @Binding var value: Bool
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            SettingsIcon(iconName: iconName, color: color)

            Text(title)
                .font(.pretendard(14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Toggle(title, isOn: $value)
                .labelsHidden()
                .tint(Color.brand)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct SettingsIcon: View {
    let iconName: String
    let color: Color

    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 30, height: 30)
            .background(color.opacity(0.10), in: Circle())
    }
}

struct SettingsDivider: View {
    var body: some View {
        Divider()
            .background(Color.divider)
            .padding(.leading, 58)
    }
}

struct SettingsDetailContainer<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                content
            }
            .padding(.horizontal, KDXSpacing.screenHorizontal)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Color.canvas.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

struct SettingsInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.textTertiary)
            Spacer(minLength: 12)
            Text(value)
                .font(.pretendard(14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

struct SettingsOptionButton: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let action: () -> Void

    init(title: String, subtitle: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.brand : Color.hairline, lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle()
                            .fill(Color.brand)
                            .frame(width: 10, height: 10)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.pretendard(14, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.pretendard(12, weight: .medium))
                            .foregroundStyle(Color.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(isSelected ? Color.brandTintBg : Color.clear)
        }
        .buttonStyle(PSPressStyle())
    }
}

struct SettingsStepperRow: View {
    let title: String
    let valueText: String
    let decrement: () -> Void
    let increment: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.pretendard(14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            Spacer()

            HStack(spacing: 10) {
                Button(action: decrement) {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.brand)
                        .frame(width: 30, height: 30)
                        .background(Color.brandTintBg, in: Circle())
                }
                .buttonStyle(.plain)

                Text(valueText)
                    .font(.pretendard(14, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .monospacedDigit()
                    .frame(minWidth: 64)

                Button(action: increment) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.brand)
                        .frame(width: 30, height: 30)
                        .background(Color.brandTintBg, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
