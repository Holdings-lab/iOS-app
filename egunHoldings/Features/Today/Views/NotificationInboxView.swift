import SwiftUI

struct NotificationInboxView: View {
    @ObservedObject var notificationCenter: AppNotificationCenter

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 18) {
                summaryCard

                if notificationCenter.groupedNotifications.isEmpty {
                    emptyState
                } else {
                    ForEach(notificationCenter.groupedNotifications) { group in
                        dayGroup(group)
                    }
                }
            }
            .padding(.horizontal, KDXSpacing.screenHorizontal)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Color.canvas.ignoresSafeArea())
        .navigationTitle("알림")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("모두 읽음") {
                    notificationCenter.markAllAsRead()
                }
                .font(.pretendard(13, weight: .semibold))
                .disabled(notificationCenter.unreadCount == 0)
            }
        }
    }

    private var summaryCard: some View {
        KDXCard {
            HStack(spacing: 12) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.brand)
                    .frame(width: 38, height: 38)
                    .background(Color.brandTintBg, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("확인할 알림")
                        .font(.pretendard(15, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    Text("읽지 않은 알림 \(notificationCenter.unreadCount)개")
                        .font(.pretendard(12, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                }

                Spacer()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Color.success)

            Text("확인할 알림이 없습니다")
                .font(.pretendard(15, weight: .bold))
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .glassCard()
    }

    private func dayGroup(_ group: AppNotificationDayGroup) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(dayText(group.date))
                .font(.pretendard(13, weight: .bold))
                .foregroundStyle(Color.textSecondary)

            VStack(spacing: 10) {
                ForEach(group.items) { item in
                    NotificationInboxRow(item: item) {
                        notificationCenter.markAsRead(item)
                    }
                }
            }
        }
    }

    private func dayText(_ date: Date) -> String {
        Self.dayFormatter.string(from: date)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter
    }()
}

private struct NotificationInboxRow: View {
    let item: AppNotificationItem
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: item.kind.iconName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(item.kind.tintColor)
                    .frame(width: 34, height: 34)
                    .background(item.kind.tintColor.opacity(0.10), in: Circle())

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(item.kind.title)
                            .font(.pretendard(11, weight: .semibold))
                            .foregroundStyle(item.kind.tintColor)

                        Text(fullDateText(item.occurredAt))
                            .font(.pretendard(11, weight: .medium))
                            .foregroundStyle(Color.textQuaternary)

                        Spacer(minLength: 4)

                        if !item.isRead {
                            Circle()
                                .fill(Color.up)
                                .frame(width: 7, height: 7)
                        }
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(item.title)
                            .font(.pretendard(15, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(item.message)
                            .font(.pretendard(13, weight: .regular))
                            .foregroundStyle(Color.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2)
                    }

                    if let relatedTitle = item.relatedTitle {
                        Text(relatedTitle)
                            .font(.pretendard(11, weight: .semibold))
                            .foregroundStyle(Color.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.subtle, in: Capsule())
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.elevated, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                    .stroke(item.isRead ? Color.hairline : Color.brand.opacity(0.25), lineWidth: 1)
            }
        }
        .buttonStyle(PSPressStyle())
    }

    private func fullDateText(_ date: Date) -> String {
        Self.fullDateFormatter.string(from: date)
    }

    private static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 a h:mm"
        return formatter
    }()
}
