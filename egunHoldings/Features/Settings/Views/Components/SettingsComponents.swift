import SwiftUI

// MARK: - Large header (설정 루트 전용)

/// 피그마 `설정 / 기본`(7:2012) 헤더. 루트는 fullScreenCover로 뜨므로 뒤로가기가 아니라 닫기(X)를 쓴다.
/// 하위 상세 화면은 push라서 계속 `SettingsNavHeader`(뒤로가기)를 쓴다.
struct SettingsLargeHeader: View {
    let eyebrow: String
    let title: String
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(eyebrow)
                    .font(.pretendard(12, weight: .bold))
                    .foregroundStyle(Color.textTertiary)

                Text(title)
                    .font(.pretendard(27, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .tracking(-0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 38, height: 38)
                    .background(Color.elevated, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.hairline, lineWidth: 1)
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("설정 닫기")
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 14)
    }
}

// MARK: - Row leading icon

/// 행 앞에 붙는 28pt 아이콘 칩. 피그마 시안은 텍스트 글리프(♢ ☼ ↗ ◎ ◫ ▤ ⌘ ↪)를 임시로 얹어놨는데,
/// 앱 전반이 SF Symbols로 통일돼 있어(chevron.right·bell·checkmark·sparkles…) 같은 계열로 다시 골랐다.
/// 칩 자체의 기하(28×28, radius 9, 13pt 글리프)는 시안 그대로 유지한다.
enum SettingsIconTone {
    case brand
    case danger

    var background: Color {
        switch self {
        case .brand: return .brandChipBg
        case .danger: return .downBg
        }
    }

    var foreground: Color {
        switch self {
        case .brand: return .brand
        case .danger: return .trendDown
        }
    }
}

struct SettingsRowIcon: View {
    let systemName: String
    var tone: SettingsIconTone = .brand

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(tone.foreground)
            .frame(width: 28, height: 28)
            .background(tone.background, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .accessibilityHidden(true)
    }
}

// MARK: - Nav header

struct SettingsNavHeader: View {
    let title: String
    let onBack: () -> Void
    var action: AnyView?

    var body: some View {
        HStack(spacing: 10) {
            LiquidGlassBackButton(accessibilityLabel: "뒤로 가기", action: onBack)

            Spacer()

            Text(title)
                .font(.pretendard(16, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            Spacer()

            if let action {
                action
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.canvas)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.hairline).frame(height: 1)
        }
    }
}

// MARK: - Generic list row

struct SettingsRow<Right: View>: View {
    let title: String
    /// 행 앞 아이콘(SF Symbol). 피그마 시안의 28pt 칩 — 생략하면 칩 없이 텍스트만 왼쪽 정렬된다.
    var icon: String?
    var sub: String?
    var danger = false
    var onTap: (() -> Void)?
    @ViewBuilder var right: () -> Right

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 11) {
                if let icon {
                    SettingsRowIcon(systemName: icon, tone: danger ? .danger : .brand)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.pretendard(14, weight: .semibold))
                        .foregroundStyle(danger ? Color.trendDown : Color.textPrimary)

                    if let sub {
                        Text(sub)
                            .font(.pretendard(12, weight: .regular))
                            .foregroundStyle(Color.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                right()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }
}

extension SettingsRow where Right == AnyView {
    /// `right`를 생략하면 `onTap`이 있을 때만 자동으로 화살표를 붙인다(스펙의 `StgRow` 기본 동작과 동일).
    init(title: String, icon: String? = nil, sub: String? = nil, danger: Bool = false, onTap: (() -> Void)? = nil) {
        self.init(title: title, icon: icon, sub: sub, danger: danger, onTap: onTap) {
            onTap != nil
                ? AnyView(
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.textQuaternary)
                )
                : AnyView(EmptyView())
        }
    }
}

/// 행 오른쪽에 값 + 화살표를 함께 보여주는 형태(피그마 "내 집 마련 ›", "2개 ›").
struct SettingsRowValue: View {
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Text(text)
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.textQuaternary)
                .lineLimit(1)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.textQuaternary)
        }
    }
}

struct SettingsDivider: View {
    var body: some View {
        Rectangle().fill(Color.hairline).frame(height: 1)
    }
}

// MARK: - Toggle switch

struct SettingsToggle: View {
    @Binding var isOn: Bool
    var disabled = false

    var body: some View {
        Button {
            guard !disabled else { return }
            withAnimation(.easeInOut(duration: 0.18)) { isOn.toggle() }
        } label: {
            Capsule()
                .fill(isOn ? Color.brand : Color.muted)
                .frame(width: 44, height: 26)
                .overlay(alignment: isOn ? .trailing : .leading) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                        .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 1)
                        .padding(3)
                }
        }
        .buttonStyle(.plain)
        .opacity(disabled ? 0.45 : 1)
        .accessibilityLabel(Text(""))
        .accessibilityValue(isOn ? "켜짐" : "꺼짐")
    }
}

// MARK: - Segmented control

struct SettingsSegmentedControl<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [(value: Value, label: String)]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.value) { option in
                Button {
                    selection = option.value
                } label: {
                    Text(option.label)
                        .font(.pretendard(13, weight: .semibold))
                        .foregroundStyle(selection == option.value ? Color.textPrimary : Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background {
                            if selection == option.value {
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(Color.elevated)
                                    .shadow(color: Color.black.opacity(0.10), radius: 4, x: 0, y: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.subtle, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Section wrapper

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.pretendard(12, weight: .bold))
                .foregroundStyle(Color.textTertiary)
                .padding(.horizontal, 4)

            // 피그마 카드는 그림자 없이 hairline 테두리로만 떠 있다(7:2041 등).
            VStack(spacing: 0) {
                content()
            }
            .background(Color.elevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.hairline, lineWidth: 1)
            }
        }
        .padding(.top, 18)
    }
}

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

// MARK: - Modal shell

struct SettingsModalContainer<Content: View>: View {
    let isPresented: Bool
    let onDismiss: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.42)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture(perform: onDismiss)

                VStack(alignment: .leading, spacing: 0) {
                    content()
                }
                .padding(20)
                .frame(maxWidth: 300)
                .background(Color.elevated, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.black.opacity(0.28), radius: 40, x: 0, y: 16)
                .transition(.scale(scale: 0.94).combined(with: .opacity))
                .accessibilityAddTraits(.isModal)
            }
            .transition(.opacity)
        }
    }
}

struct SettingsConfirmModal: View {
    let isPresented: Bool
    let title: String
    var desc: String?
    var confirmLabel = "확인"
    var cancelLabel: String? = "취소"
    var danger = false
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        SettingsModalContainer(isPresented: isPresented, onDismiss: onCancel) {
            Text(title)
                .font(.pretendard(16, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            if let desc {
                Text(desc)
                    .font(.pretendard(13, weight: .regular))
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
            }

            HStack(spacing: 8) {
                if let cancelLabel {
                    Button(action: onCancel) {
                        Text(cancelLabel)
                            .font(.pretendard(13.5, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.subtle, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.hairline, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onConfirm) {
                    Text(confirmLabel)
                        .font(.pretendard(13.5, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(danger ? Color.trendDown : Color.brand, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 18)
        }
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

// MARK: - Big single-select choice card

struct ChoiceCard: View {
    let isOn: Bool
    let icon: String
    let title: String
    var subtitle: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                Text(icon)
                    .font(.system(size: 20))
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.pretendard(14.5, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.pretendard(12.5, weight: .regular))
                            .foregroundStyle(Color.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Circle()
                    .fill(isOn ? Color.brand : Color.clear)
                    .frame(width: 20, height: 20)
                    .overlay {
                        Circle().stroke(isOn ? Color.brand : Color.hairline, lineWidth: 1.5)
                        if isOn {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.white)
                        }
                    }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isOn ? Color.brandTintBg : Color.elevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isOn ? Color.brand : Color.hairline, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compact period row

struct PeriodRow: View {
    let isOn: Bool
    let title: String
    var subtitle: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.pretendard(14, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.pretendard(12, weight: .regular))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Circle()
                    .stroke(isOn ? Color.brand : Color.hairline, lineWidth: isOn ? 5 : 1.5)
                    .frame(width: 18, height: 18)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(isOn ? Color.brandTintBg : Color.elevated, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isOn ? Color.brand : Color.hairline, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Multi-select chip grid

struct MultiSelectGridItem: Identifiable {
    let id: String
    let icon: String
    let title: String
    let subtitle: String
}

struct MultiSelectGrid: View {
    let items: [MultiSelectGridItem]
    let selected: Set<String>
    let max: Int?
    let onToggle: (String) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(items) { item in
                let isOn = selected.contains(item.id)
                let isDisabled = !isOn && max.map { selected.count >= $0 } == true

                Button {
                    guard !isDisabled else { return }
                    onToggle(item.id)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        if !item.icon.isEmpty {
                            Text(item.icon)
                                .font(.system(size: 18))
                        }

                        Text(item.title)
                            .font(.pretendard(13.5, weight: .bold))
                            .foregroundStyle(Color.textPrimary)

                        Text(item.subtitle)
                            .font(.pretendard(11.5, weight: .regular))
                            .foregroundStyle(Color.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(isOn ? Color.brandTintBg : Color.elevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isOn ? Color.brand : Color.hairline, lineWidth: 1.5)
                    }
                    .overlay(alignment: .topTrailing) {
                        if isOn {
                            Circle()
                                .fill(Color.brand)
                                .frame(width: 18, height: 18)
                                .overlay {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Color.white)
                                }
                                .padding(10)
                        }
                    }
                    .opacity(isDisabled ? 0.4 : 1)
                }
                .buttonStyle(.plain)
                .disabled(isDisabled)
            }
        }
        .padding(.top, 12)
    }
}

struct SettingsCounterPill: View {
    let count: Int
    let max: Int

    var body: some View {
        Text("\(count)/\(max)")
            .font(.pretendard(12, weight: .bold))
            .foregroundStyle(Color.brand)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(Color.brandTintBg, in: Capsule())
    }
}
