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

// MARK: - Briefing (Section 1)

struct TodayBriefingCard: View {
    let briefing: TodayBriefing
    let isAccountLinked: Bool

    var body: some View {
        if isAccountLinked {
            linkedContent
                .background(Color.elevated, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                        .stroke(Color.hairline, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 1)
        } else {
            // 온보딩 7/8 건너뛰기 확인과 같은 문구를 유지한다 — 한쪽만 바꾸면 안내가 어긋난다.
            Text("계좌 없이 시작할 수 있어요\n일부 기능은 연결 후 사용 가능해요")
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .accessibilityElement(children: .combine)
        }
    }

    private var linkedContent: some View {
        let accent = briefing.severity.accentColor

        return HStack(alignment: .center, spacing: 0) {
            if let accent {
                Rectangle().fill(accent).frame(width: 4)
            }

            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("고점 대비")
                        .font(.pretendard(10.5, weight: .bold))
                        .tracking(0.2)
                        .foregroundStyle(Color.textQuaternary)

                    Text(drawdownText)
                        .font(.pretendard(24, weight: .bold))
                        .foregroundStyle(numberColor)
                        .monospacedDigit()

                    Text("전일 대비 \(dailyChangeText)")
                        .font(.pretendard(10.5, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.muted, in: Capsule())
                }
                .frame(width: 92, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    "고점 대비 \(directionWord) \(abs(Int(briefing.drawdownFromPeakPercent.rounded())))퍼센트, 전일 대비 \(dailyChangeText)"
                )

                Text(briefing.message)
                    .font(.pretendard(14, weight: .regular))
                    .foregroundStyle(Color.textPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 16)
            .padding(.leading, accent == nil ? 16 : 12)
            .padding(.trailing, 16)
        }
    }

    private var numberColor: Color {
        briefing.severity.drawdownColor(for: briefing.drawdownFromPeakPercent)
    }

    private var drawdownText: String {
        let value = briefing.drawdownFromPeakPercent
        let sign = value > 0 ? "+" : ""
        return "\(sign)\(Int(value.rounded()))%"
    }

    private var dailyChangeText: String {
        let value = briefing.todayChangePercent
        let sign = value > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", value))%"
    }

    private var directionWord: String {
        if briefing.drawdownFromPeakPercent > 0 { return "상승" }
        if briefing.drawdownFromPeakPercent < 0 { return "하락" }
        return "보합"
    }
}

// MARK: - Holdings Top3 (Section 2)

struct TodayHoldingsTop3Card: View {
    let holdings: [TodayHolding]
    let isAccountLinked: Bool
    let onConnectAccount: () -> Void

    // 종목이 아니라 섹터(category)에 색을 배정 — 같은 섹터는 같은 색을 공유하며,
    // 처음 등장한 순서대로 5색 팔레트를 순환 배정한다.
    private static let sectorPalette: [Color] = [
        Color(hex: "3461FD"), Color(hex: "E8963C"), Color(hex: "2EA8A0"),
        Color(hex: "8B5CF6"), Color(hex: "D95C8F"),
    ]
    private static let otherColor = Color(hex: "C7CCDA")

    var body: some View {
        KDXCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("보유 비중 Top 3")
                    .font(.pretendard(15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                Rectangle()
                    .fill(Color.divider)
                    .frame(height: 1)
                    .padding(.top, 10)
                    .padding(.bottom, 4)

                if !isAccountLinked {
                    TodayQuietState(
                        iconName: "link",
                        message: Text("증권사 계정을 연결하면\n보유 종목 비중을 보여드려요"),
                        ctaTitle: "계정 연결하기",
                        onCTA: onConnectAccount
                    )
                } else {
                    VStack(spacing: 14) {
                        ForEach(rows) { row in
                            TodayHoldingRow(row: row)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    /// Top3 보유 종목 + "기타"(전체 포트폴리오 대비 나머지 비중) 합성 행.
    private var rows: [TodayHoldingRowData] {
        var sectorColors: [String: Color] = [:]
        let mapped: [TodayHoldingRowData] = holdings.map { holding in
            let color = sectorColors[holding.category] ?? {
                let assigned = Self.sectorPalette[sectorColors.count % Self.sectorPalette.count]
                sectorColors[holding.category] = assigned
                return assigned
            }()
            return TodayHoldingRowData(
                id: holding.id,
                ticker: holding.ticker,
                name: holding.name,
                weightPercent: holding.weight,
                color: color
            )
        }

        let remainder = 100 - holdings.reduce(0) { $0 + $1.weight }
        guard remainder > 0 else { return mapped }
        return mapped + [
            TodayHoldingRowData(
                id: "__rest",
                ticker: "기타",
                name: "그 외 보유종목",
                weightPercent: remainder,
                color: Self.otherColor
            )
        ]
    }
}

private struct TodayHoldingRowData: Identifiable {
    let id: String
    let ticker: String
    let name: String
    let weightPercent: Int
    let color: Color
}

private struct TodayHoldingRow: View {
    let row: TodayHoldingRowData

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                Circle()
                    .fill(row.color)
                    .frame(width: 7, height: 7)
                Text(row.ticker)
                    .font(.pretendard(13, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text(row.name)
                    .font(.pretendard(12, weight: .regular))
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 8)
                Text("\(row.weightPercent)%")
                    .font(.pretendard(13, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .monospacedDigit()
            }

            // 바 너비는 Top3 중 최댓값/합계가 아니라 holding 자신의 절대 비중(weight / 100)만 반영한다.
            GeometryReader { proxy in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.muted)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(row.color)
                            .frame(width: proxy.size.width * CGFloat(row.weightPercent) / 100.0)
                    }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Goal Progress (Section 3)

struct TodayGoalProgressCard: View {
    let goalProgress: TodayGoalProgress?
    let onSetGoal: () -> Void

    var body: some View {
        KDXCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text("목표 대비")
                        .font(.pretendard(15, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    if let goalProgress {
                        Text(goalProgress.status.label)
                            .font(.pretendard(12, weight: .semibold))
                            .foregroundStyle(goalProgress.status.color)
                    }
                }

                if let goalProgress {
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.muted)
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(goalProgress.status.color)
                                .frame(width: proxy.size.width * CGFloat(goalProgress.progressPercent) / 100.0)
                                .animation(.easeInOut(duration: 0.5), value: goalProgress.progressPercent)
                        }
                    }
                    .frame(height: 8)

                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(goalProgress.progressPercent)%")
                            .font(.pretendard(20, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                            .monospacedDigit()
                        Text("\(goalProgress.goalLabel) · \(goalProgress.scheduleDeltaText)")
                            .font(.pretendard(13, weight: .medium))
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding(.top, 2)
                } else {
                    TodayQuietState(
                        message: Text("아직 목표 자금을 설정하지 않았어요"),
                        ctaTitle: "목표 설정하기",
                        onCTA: onSetGoal
                    )
                }
            }
        }
    }
}

// MARK: - Empty ("quiet") state shared by Holdings / Goal cards

private struct TodayQuietState: View {
    var iconName: String? = nil
    let message: Text
    var ctaTitle: String? = nil
    var onCTA: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 10) {
            if let iconName {
                Image(systemName: iconName)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(Color.textQuaternary)
            }

            message
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)

            if let ctaTitle, let onCTA {
                Button(action: onCTA) {
                    Text(ctaTitle)
                        .font(.pretendard(13.5, weight: .bold))
                        .foregroundStyle(Color.textOnAccent)
                        .frame(minHeight: 44)
                        .padding(.horizontal, 18)
                        .background(Color.brand, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(PSPressStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
        .padding(.bottom, 6)
    }
}

// MARK: - Holdings-related News (Section 4)

struct TodayNewsSection: View {
    let newsItems: [TodayNewsItem]
    let isAccountLinked: Bool
    let onNewsTap: (TodayNewsItem) -> Void
    let onSeeMoreTapped: () -> Void

    private var headerTitle: String {
        isAccountLinked ? "보유종목 관련 뉴스" : "관심 분야 뉴스"
    }

    var body: some View {
        KDXCard {
            VStack(alignment: .leading, spacing: 0) {
                Text(headerTitle)
                    .font(.pretendard(15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                Rectangle()
                    .fill(Color.divider)
                    .frame(height: 1)
                    .padding(.top, 10)
                    .padding(.bottom, 4)

                if newsItems.isEmpty {
                    TodayEmptyStateCard(
                        iconName: "newspaper",
                        title: "오늘은 내 자산 관련 큰 소식 없어요",
                        subtitle: "조용한 것도 정보예요"
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(newsItems.prefix(4).enumerated()), id: \.element.id) { index, item in
                            if index > 0 {
                                Divider().background(Color.divider)
                            }

                            Button { onNewsTap(item) } label: {
                                TodayNewsRow(item: item)
                            }
                            .buttonStyle(PressScaleButtonStyle())
                        }
                    }

                    Divider().background(Color.divider).padding(.top, 12)

                    Button(action: onSeeMoreTapped) {
                        HStack {
                            Text("뉴스룸에서 더 보기 →")
                                .font(.pretendard(13, weight: .semibold))
                                .foregroundStyle(Color.brand)
                            Spacer()
                        }
                        .padding(.top, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressScaleButtonStyle())
                }
            }
        }
    }
}

private struct TodayNewsRow: View {
    let item: TodayNewsItem

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let ticker = item.ticker {
                Text(ticker)
                    .font(.pretendard(12, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.subtle, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(item.summary)
                    .font(.pretendard(12, weight: .regular))
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Helpers

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
