import SwiftUI

// MARK: - TodayView

struct TodayView: View {
    @StateObject private var viewModel: TodayViewModel

    init(
        userId: Int64? = nil,
        userAssetProfile: UserAssetProfile = AppMockData.userAssetProfile,
        portfolioSnapshot: PortfolioSnapshot = AppMockData.portfolioSnapshot,
        viewModel: TodayViewModel? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: viewModel ?? TodayViewModel(
                userId: userId,
                userAssetProfile: userAssetProfile,
                portfolioSnapshot: portfolioSnapshot
            )
        )
    }

    var body: some View {
        ZStack {
            todayBackground

            PFContentScrollView(
                spacing: PSSpacing.sectionGap,
                horizontalPadding: PSSpacing.pagePad,
                topPadding: 8,
                bottomPadding: 110,
                scrollsToTopOnAppear: true
            ) {
                TodayHeaderSection(
                    onDataStatus: { viewModel.present(.dataStatus) },
                    onSettings:   { viewModel.present(.settings) }
                )

                TodayJudgmentSection(
                    judgment: viewModel.judgment,
                    onWhy:             { viewModel.present(.quickReason) },
                    onSaveCheckpoint:  { viewModel.present(.saveCheckpoint) },
                    onSnooze:          { viewModel.present(.snooze) }
                )

                TodayPortfolioSection(
                    portfolio: viewModel.portfolio,
                    onExposureTap: { item in
                        viewModel.present(.exposureTheme(item))
                    }
                )

                if let topPolicy = viewModel.topPolicy {
                    TodayTopPolicySection(policy: topPolicy)
                }

                TodayNoActionSection(
                    reasons: viewModel.noActionReasons,
                    watchCondition: viewModel.noActionWatchCondition
                )
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await viewModel.load()
        }
        .sheet(item: $viewModel.activeSheet) { sheet in
            sheetContent(for: sheet)
                .presentationBackground(.clear)
                .presentationCornerRadius(28)
        }
    }

    @ViewBuilder
    private func sheetContent(for sheet: TodaySheet) -> some View {
        switch sheet {
        case .settings:
            SettingsSheet(connectedBrokerText: viewModel.connectedBrokerStatusText)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        case .dataStatus:
            DataStatusSheet(
                rows: viewModel.dataStatusRows,
                connectionStatusText: viewModel.connectionStatusText,
                footnote: viewModel.dataStatusFootnote
            )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        case .quickReason:
            QuickReasonSheet(judgment: viewModel.judgment)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        case .saveCheckpoint:
            SaveCheckpointSheet(conditionText: viewModel.primaryCheckpointText)
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
        case .snooze:
            SnoozeSheet()
                .presentationDetents([.height(260)])
                .presentationDragIndicator(.visible)
        case .exposureTheme(let item):
            ExposureThemeSheet(
                item: item,
                holdings: viewModel.holdings,
                relatedPolicies: viewModel.relatedPolicies(for: item)
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var todayBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "060B24"),
                    Color(hex: "0D163B"),
                    Color(hex: "060B24")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(PSColor.electricBlue.opacity(0.16))
                .frame(width: 320, height: 320)
                .blur(radius: 120)
                .offset(x: -120, y: -330)

            Circle()
                .fill(PSColor.purple.opacity(0.12))
                .frame(width: 250, height: 250)
                .blur(radius: 110)
                .offset(x: 160, y: -230)

            Circle()
                .fill(Color.white.opacity(0.04))
                .frame(width: 220, height: 220)
                .blur(radius: 90)
                .offset(x: 120, y: 250)
        }
        .ignoresSafeArea()
    }
}

// MARK: - ① Header

private struct TodayHeaderSection: View {
    let onDataStatus: () -> Void
    let onSettings:   () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text("PolSignal")
                    .font(PSFont.semibold(15))
                    .foregroundStyle(PSColor.electricBlue.opacity(0.80))
                Spacer()
                iconButton(systemName: "bell", action: {})
                iconButton(systemName: "gearshape", action: onSettings)
            }

            Text("안녕하세요, 투자자님")
                .font(PSFont.title(22))
                .foregroundStyle(PSColor.textPrimary)

            Button(action: onDataStatus) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(PSColor.emerald)
                        .frame(width: 6, height: 6)
                        .overlay {
                            Circle()
                                .fill(PSColor.emerald.opacity(0.35))
                                .frame(width: 12, height: 12)
                        }
                    Text("오전 11:24 업데이트")
                        .font(PSFont.caption())
                        .foregroundStyle(PSColor.textMuted)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    private func iconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(PSColor.textMuted)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.05), in: Circle())
        }
        .buttonStyle(PSPressStyle())
    }
}

// MARK: - ② 오늘의 대표 판단

private struct TodayJudgmentSection: View {
    let judgment: TodayJudgment
    let onWhy:            () -> Void
    let onSaveCheckpoint: () -> Void
    let onSnooze:         () -> Void

    var body: some View {
        PSGlassCard(variant: .primary) {
            VStack(alignment: .leading, spacing: 14) {
                topRow
                briefingStatsRow
                titleText
                actionSummary
                actionButtons
            }
        }
    }

    private var topRow: some View {
        HStack(spacing: 8) {
            Text("오늘 가장 중요한 변화")
                .font(PSFont.caption())
                .foregroundStyle(PSColor.electricBlue.opacity(0.72))
                .tracking(0.3)
            Spacer()
            JudgmentTypeBadge(type: judgment.type)
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 10))
                Text(judgment.validUntil)
                    .font(PSFont.caption())
            }
            .foregroundStyle(PSColor.textFaint)
        }
    }

    private var briefingStatsRow: some View {
        HStack(spacing: 0) {
            TodayBriefingStatCell(
                value: "\(judgment.myExposure)%",
                label: "내 자산 노출",
                color: PSColor.electricBlue
            )

            TodayStatDivider()

            TodayBriefingStatCell(
                value: compactInvalidationCondition,
                label: "무효화 조건",
                color: PSColor.yellow
            )

            TodayStatDivider()

            TodayBriefingStatCell(
                value: judgment.type.rawValue,
                label: "권장 행동",
                color: judgment.type.color
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: PSRadius.inner, style: .continuous))
    }

    private var titleText: some View {
        Text(judgment.title)
            .font(PSFont.semibold(19))
            .foregroundStyle(PSColor.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .lineSpacing(4)
    }

    private var actionSummary: some View {
        HStack(spacing: 8) {
            Text("다시 볼 기준")
                .font(PSFont.caption())
                .foregroundStyle(PSColor.textMuted.opacity(0.78))

            Text(judgment.invalidationCondition)
                .font(PSFont.semibold(12))
                .foregroundStyle(PSColor.yellow.opacity(0.86))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
    }

    private var compactInvalidationCondition: String {
        let normalized = judgment.invalidationCondition
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard normalized.count > 8 else {
            return normalized
        }

        return "\(String(normalized.prefix(8)))..."
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            judgeButton(
                label: "왜?",
                icon: "questionmark.circle",
                bg: Color.white.opacity(0.05),
                fg: PSColor.textMuted.opacity(0.70),
                action: onWhy
            )
            judgeButton(
                label: "체크포인트 저장",
                icon: "bookmark.badge.plus",
                bg: PSColor.electricBlue.opacity(0.10),
                fg: PSColor.electricBlue,
                action: onSaveCheckpoint
            )
            judgeButton(
                label: "나중에 보기",
                icon: "clock",
                bg: Color.white.opacity(0.03),
                fg: PSColor.textMuted.opacity(0.40),
                action: onSnooze,
                compact: true
            )
        }
    }

    private func judgeButton(
        label: String,
        icon: String,
        bg: Color,
        fg: Color,
        action: @escaping () -> Void,
        compact: Bool = false
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(label)
                    .font(PSFont.semibold(12))
            }
            .foregroundStyle(fg)
            .padding(.horizontal, compact ? 12 : 14)
            .padding(.vertical, 9)
            .background(bg, in: RoundedRectangle(cornerRadius: PSRadius.small, style: .continuous))
        }
        .buttonStyle(PSPressStyle())
    }
}

private struct TodayBriefingStatCell: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(PSFont.semibold(16))
                .foregroundStyle(color)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.68)

            Text(label)
                .font(PSFont.caption(10))
                .foregroundStyle(PSColor.textMuted.opacity(0.76))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct TodayStatDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 1, height: 28)
    }
}

// MARK: - ③ 내 총자산

private struct TodayPortfolioSection: View {
    let portfolio: TodayPortfolioSummary
    let onExposureTap: (TodayExposureItem) -> Void

    var body: some View {
        PSGlassCard(variant: .secondary) {
            VStack(alignment: .leading, spacing: 16) {
                topRow
                amountRow
                exposureBars
                miniIndicators
            }
        }
    }

    private var topRow: some View {
        HStack {
            Text("총 자산")
                .font(PSFont.caption())
                .foregroundStyle(PSColor.textMuted)
            Spacer()
            PSStatusChip(label: portfolio.riskLevel, color: PSColor.yellow, bgOpacity: 0.08)
        }
    }

    private var amountRow: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("₩\(portfolio.totalAsset.formattedKRW)")
                .font(PSFont.semibold(26))
                .foregroundStyle(PSColor.textPrimary)
                .monospacedDigit()
                .minimumScaleFactor(0.8)
                .lineLimit(1)

            Spacer()

            let isPositive = portfolio.todayChange >= 0
            HStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 11, weight: .bold))
                Text(portfolio.todayChangeFormatted)
                    .font(PSFont.semibold(13))
                    .monospacedDigit()
            }
            .foregroundStyle(isPositive ? PSColor.emerald : PSColor.red)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                (isPositive ? PSColor.emerald : PSColor.red).opacity(0.08),
                in: Capsule()
            )
        }
    }

    private var exposureBars: some View {
        VStack(spacing: 10) {
            ForEach(portfolio.topExposures, id: \.theme) { item in
                Button {
                    onExposureTap(item)
                } label: {
                    PSExposureBar(theme: item.theme, pct: item.pct, color: item.color)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var miniIndicators: some View {
        HStack(spacing: 8) {
            MiniIndicator(label: "현금 방어력", value: "\(portfolio.cashDefense)%", valueColor: PSColor.electricBlue)
            MiniIndicator(label: "달러 비중", value: "\(portfolio.dollarDefense)%", valueColor: PSColor.yellow)
            MiniIndicator(label: "과매수 위험", value: portfolio.overtradeRisk, valueColor: PSColor.emerald)
        }
    }
}

private struct MiniIndicator: View {
    let label: String
    let value: String
    let valueColor: Color

    var body: some View {
        VStack(spacing: 5) {
            Text(label)
                .font(PSFont.caption(10))
                .foregroundStyle(PSColor.textMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(PSFont.semibold(13))
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: PSRadius.small, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PSRadius.small, style: .continuous)
                .stroke(PSColor.border, lineWidth: 0.5)
        }
    }
}

// MARK: - ④ 오늘 가장 영향 큰 정책

private struct TodayTopPolicySection: View {
    let policy: TodayPolicyEvent
    @State private var showsDetail = false

    var body: some View {
        PSGlassCard(variant: .primary) {
            VStack(alignment: .leading, spacing: 14) {
                topRow
                policyTitle
                metricsRow
                summaryBox
                assetTags
                detailButton
            }
        }
    }

    private var topRow: some View {
        HStack(spacing: 8) {
            Text("오늘 가장 영향 큰 정책")
                .font(PSFont.caption())
                .foregroundStyle(PSColor.electricBlue.opacity(0.60))
                .tracking(0.3)
            Spacer()
            PSStatusChip(label: policy.dDay, color: PSColor.electricBlue)
            PSStatusChip(label: policy.status.rawValue, color: policy.status.color)
        }
    }

    private var policyTitle: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(policy.title)
                .font(PSFont.semibold(18))
                .foregroundStyle(PSColor.textPrimary)
            Text(policy.institution)
                .font(PSFont.body(12))
                .foregroundStyle(PSColor.textMuted.opacity(0.50))
        }
    }

    private var metricsRow: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                Text("내 자산 노출")
                    .font(PSFont.caption())
                    .foregroundStyle(PSColor.textMuted)
                Text("\(policy.myExposure)%")
                    .font(PSFont.semibold(20))
                    .foregroundStyle(PSColor.electricBlue)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 5) {
                Text("신뢰도")
                    .font(PSFont.caption())
                    .foregroundStyle(PSColor.textMuted)
                Text("\(policy.confidence)%")
                    .font(PSFont.semibold(20))
                    .foregroundStyle(PSColor.textPrimary)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var summaryBox: some View {
        Text(policy.summary)
            .font(PSFont.body(12))
            .foregroundStyle(PSColor.textPrimary.opacity(0.70))
            .fixedSize(horizontal: false, vertical: true)
            .lineSpacing(4)
            .padding(14)
            .background(
                PSColor.electricBlue.opacity(0.06),
                in: RoundedRectangle(cornerRadius: PSRadius.inner, style: .continuous)
            )
    }

    private var assetTags: some View {
        HStack(spacing: 8) {
            ForEach(policy.relatedAssets, id: \.self) { asset in
                Text(asset)
                    .font(PSFont.caption(11))
                    .foregroundStyle(PSColor.blueSubtle)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(PSColor.electricBlue.opacity(0.08), in: Capsule())
            }
        }
    }

    private var detailButton: some View {
        Button(action: {}) {
            HStack {
                Text("정책 상세 보기")
                    .font(PSFont.semibold(14))
                    .foregroundStyle(PSColor.textMuted.opacity(0.80))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(PSColor.textFaint)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: PSRadius.inner, style: .continuous))
        }
        .buttonStyle(PSPressStyle())
    }
}

// MARK: - ⑤ 아무것도 안 해도 되는 이유

private struct TodayNoActionSection: View {
    let reasons: [String]
    let watchCondition: String

    var body: some View {
        PSGlassCard(variant: .tinted(PSColor.emerald)) {
            VStack(alignment: .leading, spacing: 14) {
                header
                reasonsList
                watchText
                actionButtons
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "shield.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(PSColor.emerald)
            Text("지금은 아무것도 안 해도 되는 구간")
                .font(PSFont.semibold(13))
                .foregroundStyle(PSColor.emerald)
        }
    }

    private var reasonsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(reasons, id: \.self) { reason in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(PSColor.emerald.opacity(0.60))
                        .padding(.top, 1)
                    Text(reason)
                        .font(PSFont.body(13))
                        .foregroundStyle(PSColor.textPrimary.opacity(0.60))
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2)
                }
            }
        }
    }

    private var watchText: some View {
        Text("조건이 바뀌면 다시 볼 기준: \(watchCondition)")
            .font(PSFont.caption())
            .foregroundStyle(PSColor.textFaint)
            .fixedSize(horizontal: false, vertical: true)
            .lineSpacing(2)
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            noActionButton(
                label: "판단 저장",
                icon: "bookmark.badge.plus",
                bg: PSColor.emerald.opacity(0.08),
                fg: PSColor.emerald.opacity(0.80),
                action: {}
            )
            noActionButton(
                label: "조건 바뀌면 알림",
                icon: "bell",
                bg: Color.white.opacity(0.03),
                fg: PSColor.textMuted.opacity(0.50),
                action: {}
            )
        }
    }

    private func noActionButton(
        label: String,
        icon: String,
        bg: Color,
        fg: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(label)
                    .font(PSFont.semibold(13))
            }
            .foregroundStyle(fg)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(bg, in: RoundedRectangle(cornerRadius: PSRadius.small, style: .continuous))
        }
        .buttonStyle(PSPressStyle())
    }
}

// MARK: - Helpers

private extension Int {
    var formattedKRW: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

private extension TodayPortfolioSummary {
    var todayChangeFormatted: String {
        let sign = todayChange >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", todayChange))%"
    }
}

// MARK: - Preview

#Preview {
    TodayView()
}
