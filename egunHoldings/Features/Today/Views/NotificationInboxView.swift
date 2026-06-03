import SwiftUI

struct NotificationInboxView: View {
    @ObservedObject var notificationCenter: AppNotificationCenter
    var onAnalysisNotification: (PolSignalAnalysisPayload) -> Void = { _ in }
    @State private var detailItem: AppNotificationItem?

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
        .sheet(item: $detailItem) { item in
            NewsDetailSheet(item: item)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
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
                        if item.hasDetailContent {
                            detailItem = item
                        } else if let payload = item.analysisPayload {
                            onAnalysisNotification(payload)
                        }
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
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .lineSpacing(2)
                    }

                    if let relatedTitle = item.relatedTitle, !item.hasDetailContent {
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

// MARK: - NewsDetailSheet

struct NewsDetailSheet: View {
    let item: AppNotificationItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader
            Divider().background(Color.hairline)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    metaRow
                    titleBlock
                    Divider().background(Color.hairline)

                    if let sectors = item.relatedSectors, !sectors.isEmpty {
                        sectorSection(sectors)
                    }

                    if let body = item.detailBody {
                        Text(body)
                            .font(.pretendard(15, weight: .regular))
                            .foregroundStyle(Color.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(4)
                    }

                    if let bullets = item.impactBullets, !bullets.isEmpty {
                        impactSection(bullets)
                    }

                    if !item.sourceReferences.isEmpty {
                        sourceSection(item.sourceReferences)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color.canvas.ignoresSafeArea())
    }

    // MARK: Sub-views

    private var sheetHeader: some View {
        HStack {
            Spacer(minLength: 0)
            Text(item.kind == .policy ? "정책 상세" : "뉴스 상세")
                .font(.pretendard(16, weight: .bold))
                .foregroundStyle(Color.textPrimary)
            Spacer(minLength: 0)
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(Color.subtle, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .frame(height: 52)
    }

    private var metaRow: some View {
        HStack(spacing: 8) {
            Image(systemName: item.kind.iconName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(item.kind.tintColor)
                .frame(width: 28, height: 28)
                .background(item.kind.tintColor.opacity(0.12), in: Circle())

            Text(item.kind.title)
                .font(.pretendard(12, weight: .semibold))
                .foregroundStyle(item.kind.tintColor)

            Text("·")
                .foregroundStyle(Color.textQuaternary)

            Text(Self.dateFormatter.string(from: item.occurredAt))
                .font(.pretendard(12, weight: .medium))
                .foregroundStyle(Color.textQuaternary)
        }
    }

    private var titleBlock: some View {
        Text(item.title)
            .font(.pretendard(22, weight: .bold))
            .foregroundStyle(Color.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .lineSpacing(3)
    }

    private func sectorSection(_ sectors: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("관련 섹터")
                .font(.pretendard(13, weight: .bold))
                .foregroundStyle(Color.textSecondary)

            HStack(spacing: 8) {
                ForEach(sectors, id: \.self) { sector in
                    Text(sector)
                        .font(.pretendard(13, weight: .semibold))
                        .foregroundStyle(Color.brand)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.brandTintBg, in: Capsule())
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }

    private func impactSection(_ bullets: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.success)
                Text("내 자산 영향")
                    .font(.pretendard(13, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(bullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Color.success)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)

                        Text(bullet)
                            .font(.pretendard(14, weight: .regular))
                            .foregroundStyle(Color.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(3)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.successBg, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                .stroke(Color.success.opacity(0.20), lineWidth: 1)
        }
    }

    private func sourceSection(_ sources: [AppNotificationSource]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "link")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.electricBlue)
                Text("원문 출처")
                    .font(.pretendard(13, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
            }

            VStack(spacing: 10) {
                ForEach(sources) { source in
                    Button {
                        if let url = source.url {
                            openURL(url)
                        }
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(source.title)
                                    .font(.pretendard(14, weight: .bold))
                                    .foregroundStyle(Color.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(source.subtitle)
                                    .font(.pretendard(12, weight: .medium))
                                    .foregroundStyle(Color.textTertiary)
                                    .fixedSize(horizontal: false, vertical: true)

                                if let host = source.url?.host {
                                    Text(host)
                                        .font(.pretendard(11, weight: .semibold))
                                        .foregroundStyle(Color.electricBlue)
                                        .lineLimit(1)
                                }
                            }

                            Spacer(minLength: 8)

                            Image(systemName: source.url == nil ? "doc.text" : "arrow.up.forward")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(source.url == nil ? Color.textDisabled : Color.electricBlue)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.subtle.opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(source.url == nil)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 (E) a h:mm"
        return f
    }()
}
