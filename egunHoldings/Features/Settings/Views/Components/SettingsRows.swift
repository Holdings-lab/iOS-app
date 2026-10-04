import SwiftUI

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
