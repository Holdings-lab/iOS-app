import SwiftUI

struct TodayHeaderSection: View {
    let hasUnreadNotification: Bool
    let onNotifications: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(Self.dateText)
                    .font(.pretendard(12, weight: .medium))
                    .foregroundStyle(Color.textQuaternary)
                Text("오늘")
                    .font(.pretendard(24, weight: .bold))
                    .foregroundStyle(PSColor.textPrimary)
            }

            Spacer()

            HStack(spacing: 10) {
                HeaderIconButton(
                    iconName: "bell",
                    accessibilityLabel: "알림",
                    showsUnreadBadge: hasUnreadNotification,
                    action: onNotifications
                )

                HeaderIconButton(
                    iconName: "gearshape",
                    accessibilityLabel: "설정",
                    showsUnreadBadge: false,
                    action: onSettings
                )
            }
        }
    }

    private static var dateText: String {
        let date = Date()
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.month, .day, .weekday], from: date)
        let weekdays = ["", "일요일", "월요일", "화요일", "수요일", "목요일", "금요일", "토요일"]
        let month = components.month ?? 1
        let day = components.day ?? 1
        let weekday = weekdays[safe: components.weekday ?? 0] ?? ""
        return "\(month)월 \(day)일 \(weekday)"
    }
}

private struct HeaderIconButton: View {
    let iconName: String
    let accessibilityLabel: String
    let showsUnreadBadge: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: showsUnreadBadge && iconName == "bell" ? "bell.badge.fill" : iconName)
                .symbolRenderingMode(showsUnreadBadge && iconName == "bell" ? .palette : .monochrome)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(PSColor.textPrimary, PSColor.danger)
                .frame(width: 44, height: 44)
            .background(PSColor.surface, in: Circle())
            .overlay { Circle().stroke(PSColor.border, lineWidth: 1) }
        }
        .buttonStyle(PSPressStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}

struct TodayUnreadNotificationCard: View {
    let item: AppNotificationItem
    let onOpen: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        PolSignalCard {
            HStack(alignment: .top, spacing: 12) {
                Button(action: onOpen) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: item.kind.iconName)
                            .symbolRenderingMode(.palette)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(item.kind.tintColor, PSColor.danger)
                            .frame(width: 36, height: 36)
                            .background(item.kind.tintColor.opacity(0.12), in: Circle())

                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.kind.title)
                                .font(.pretendard(12, weight: .semibold, relativeTo: .caption))
                                .foregroundStyle(item.kind.tintColor)

                            Text(item.title)
                                .font(.pretendard(15, weight: .bold, relativeTo: .body))
                                .foregroundStyle(PSColor.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(item.message)
                                .font(.pretendard(13, weight: .regular, relativeTo: .footnote))
                                .foregroundStyle(PSColor.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("알림 상세 보기")

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(PSColor.textSecondary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("알림 카드 닫기")
            }
        }
    }
}
// MARK: - Helpers

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
