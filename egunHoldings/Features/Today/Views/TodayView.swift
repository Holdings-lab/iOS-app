import SwiftUI

// MARK: - TodayView

struct TodayView: View {
    @StateObject private var viewModel: TodayViewModel
    @ObservedObject private var exchangeRateViewModel: ExchangeRateViewModel
    private let onAssetTabRequested: () -> Void

    init(
        userId: Int64? = nil,
        userAssetProfile: UserAssetProfile = AppMockData.userAssetProfile,
        portfolioSnapshot: PortfolioSnapshot = AppMockData.portfolioSnapshot,
        viewModel: TodayViewModel? = nil,
        exchangeRateViewModel: ExchangeRateViewModel? = nil,
        onAssetTabRequested: @escaping () -> Void = {}
    ) {
        self.onAssetTabRequested = onAssetTabRequested
        _viewModel = StateObject(
            wrappedValue: viewModel ?? TodayViewModel(
                userId: userId,
                userAssetProfile: userAssetProfile,
                portfolioSnapshot: portfolioSnapshot
            )
        )
        self.exchangeRateViewModel = exchangeRateViewModel ?? ExchangeRateViewModel()
    }

    var body: some View {
        ZStack {
            Color.canvas.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 24) {
                    TodayHeaderSection(
                        name: "투자자",
                        hasUnreadNotifications: true,
                        onNotifications: { viewModel.present(.dataStatus) }
                    )

                    ExchangeRateSnapshotCard(
                        viewModel: exchangeRateViewModel,
                        displayMode: .compact
                    )

                    TodayJudgmentHeroCard(
                        judgment: viewModel.judgment,
                        state: judgmentState,
                        onDetail: { viewModel.present(.quickReason) }
                    )

                    TodayAssetSummaryCard(
                        portfolio: viewModel.portfolio,
                        holdings: viewModel.userAssetProfile.holdings,
                        onAssetTabRequested: onAssetTabRequested
                    )

                    TodayPolicyImpactCard(
                        policies: Array(viewModel.policyEvents.prefix(3)),
                        totalPolicyCount: viewModel.policyEvents.count,
                        onPolicyTap: { viewModel.present(.policyDetail($0)) },
                        onShowAll: { viewModel.present(.policyList) }
                    )

                    TodayDecisionSupportCard(
                        state: judgmentState,
                        noActionReasons: viewModel.noActionReasons,
                        actionEvidence: viewModel.judgment.forEvidence,
                        watchCondition: viewModel.noActionWatchCondition,
                        invalidationCondition: viewModel.judgment.invalidationCondition
                    )
                }
                .padding(.horizontal, KDXSpacing.screenHorizontal)
                .padding(.top, 12)
                .padding(.bottom, 112)
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
        .preferredColorScheme(.light)
        .task {
            await viewModel.load()
        }
        .sheet(item: $viewModel.activeSheet) { sheet in
            sheetContent(for: sheet)
                .presentationBackground(.clear)
                .presentationCornerRadius(KDXRadius.bottomSheet)
        }
    }

    private var judgmentState: TodayJudgmentDisplayState {
        TodayJudgmentDisplayState(type: viewModel.judgment.type)
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
                .presentationDetents([.medium])
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
        case .policyDetail(let policy):
            PolicyDetailSheet(policy: policy)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        case .policyList:
            PolicyListSheet(
                policies: viewModel.policyEvents,
                onSelect: { viewModel.present(.policyDetail($0)) }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Header

private struct TodayHeaderSection: View {
    let name: String
    let hasUnreadNotifications: Bool
    let onNotifications: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text(Self.dateText)
                    .font(.pretendard(12, weight: .medium))
                    .foregroundStyle(Color.textQuaternary)
                Text("안녕하세요, \(name)님")
                    .font(.pretendard(22, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
            }

            Spacer()

            Button(action: onNotifications) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                        .frame(width: 40, height: 40)

                    if hasUnreadNotifications {
                        Circle()
                            .fill(Color.up)
                            .frame(width: 7, height: 7)
                            .offset(x: -7, y: 8)
                    }
                }
                .background(Color.elevated, in: Circle())
                .overlay { Circle().stroke(Color.hairline, lineWidth: 1) }
            }
            .buttonStyle(PSPressStyle())
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

// MARK: - Judgment Hero

private struct TodayJudgmentHeroCard: View {
    let judgment: TodayJudgment
    let state: TodayJudgmentDisplayState
    let onDetail: () -> Void

    var body: some View {
        Button(action: onDetail) {
            KDXCard(
                padding: EdgeInsets(top: 24, leading: 16, bottom: 24, trailing: 16)
            ) {
                VStack(alignment: .leading, spacing: 18) {
                    Text(state.label)
                        .font(.pretendard(11, weight: .semibold))
                        .foregroundStyle(state.foreground)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(state.background, in: RoundedRectangle(cornerRadius: KDXRadius.chip, style: .continuous))

                    VStack(alignment: .leading, spacing: 8) {
                        Text(state.heroTitle(for: judgment))
                            .font(.pretendard(22, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(3)

                        Text(state.heroSubtitle(for: judgment))
                            .font(.pretendard(14, weight: .regular))
                            .foregroundStyle(Color.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(3)
                    }

                    HStack {
                        Spacer()
                        Text("자세히 보기")
                            .font(.pretendard(13, weight: .semibold))
                            .foregroundStyle(Color.brand)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.brand)
                    }
                }
            }
        }
        .buttonStyle(PSPressStyle())
    }
}

// MARK: - Asset Summary

private struct TodayAssetSummaryCard: View {
    let portfolio: TodayPortfolioSummary
    let holdings: [UserHoldingItem]
    let onAssetTabRequested: () -> Void

    var body: some View {
        KDXCard {
            VStack(alignment: .leading, spacing: 16) {
                Button(action: onAssetTabRequested) {
                    HStack(spacing: 8) {
                        Text("내 총자산")
                            .font(.pretendard(16, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.textDisabled)
                    }
                }
                .buttonStyle(.plain)

                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("₩ \(portfolio.totalAsset.formattedKRW)")
                        .font(.pretendard(34, weight: .heavy))
                        .foregroundStyle(Color.textPrimary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Spacer(minLength: 4)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(portfolio.todayChangePercentText)
                            .font(.pretendard(13, weight: .bold))
                        Text(portfolio.todayChangeAmountText)
                            .font(.pretendard(11, weight: .semibold))
                    }
                    .foregroundStyle(portfolio.todayChangeColor)
                    .monospacedDigit()
                }

                AssetDistributionBar(segments: AssetDistributionSegment.make(from: holdings))
            }
        }
    }
}

private struct AssetDistributionBar: View {
    let segments: [AssetDistributionSegment]

    var body: some View {
        GeometryReader { proxy in
            let total = max(segments.map(\.weight).reduce(0, +), 1)
            HStack(spacing: 2) {
                ForEach(segments) { segment in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(segment.color)
                        .frame(width: max(6, proxy.size.width * CGFloat(segment.weight) / CGFloat(total)))
                }
            }
        }
        .frame(height: 6)
        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        .accessibilityHidden(true)
    }
}

private struct AssetDistributionSegment: Identifiable {
    let id: AssetCategory
    let weight: Int
    let color: Color

    static func make(from holdings: [UserHoldingItem]) -> [AssetDistributionSegment] {
        let grouped = Dictionary(grouping: holdings, by: \.category)
            .mapValues { $0.map(\.weightPercent).reduce(0, +) }

        let ordered: [(AssetCategory, Color)] = [
            (.etf, Color.brand),
            (.stock, Color(hex: "8D96A3")),
            (.depositSavings, Color(hex: "C5CAD3")),
            (.loan, Color(hex: "E1E4EA"))
        ]

        let result = ordered.compactMap { category, color -> AssetDistributionSegment? in
            guard let weight = grouped[category], weight > 0 else { return nil }
            return AssetDistributionSegment(id: category, weight: weight, color: color)
        }

        return result.isEmpty
            ? [AssetDistributionSegment(id: .etf, weight: 100, color: Color.divider)]
            : result
    }
}

// MARK: - Policy Impact

private struct TodayPolicyImpactCard: View {
    let policies: [TodayPolicyEvent]
    let totalPolicyCount: Int
    let onPolicyTap: (TodayPolicyEvent) -> Void
    let onShowAll: () -> Void

    var body: some View {
        KDXCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Text("오늘 가장 영향 큰 정책")
                        .font(.pretendard(16, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Text("오늘 정책 \(min(totalPolicyCount, 3))건")
                        .font(.pretendard(11, weight: .semibold))
                        .foregroundStyle(Color.textQuaternary)
                }

                VStack(spacing: 0) {
                    ForEach(Array(policies.enumerated()), id: \.element.id) { index, policy in
                        Button { onPolicyTap(policy) } label: {
                            PolicyImpactRow(policy: policy)
                                .padding(.vertical, 13)
                        }
                        .buttonStyle(.plain)

                        if index < policies.count - 1 {
                            Divider().background(Color.divider)
                        }
                    }
                }

                Button(action: onShowAll) {
                    HStack {
                        Text("정책 전체 보기")
                            .font(.pretendard(13, weight: .semibold))
                            .foregroundStyle(Color.brand)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.brand)
                    }
                    .padding(.top, 2)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct PolicyImpactRow: View {
    let policy: TodayPolicyEvent

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(policy.categoryLabel)
                .font(.pretendard(11, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color(hex: "F2F4F7"), in: RoundedRectangle(cornerRadius: KDXRadius.chip, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(policy.title)
                    .font(.pretendard(15, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text("내 자산 중 \(policy.myExposure)% 관련")
                    .font(.pretendard(12, weight: .regular))
                    .foregroundStyle(Color.textTertiary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 5) {
                Text("영향")
                    .font(.pretendard(10, weight: .semibold))
                    .foregroundStyle(Color.textQuaternary)
                ImpactDots(score: policy.impactScore)
            }
        }
    }
}

private struct ImpactDots: View {
    let score: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { index in
                Circle()
                    .fill(index <= score ? Color.brand : Color.divider)
                    .frame(width: 5, height: 5)
            }
        }
        .accessibilityLabel("영향 \(score)점")
    }
}

// MARK: - Decision Support

private struct TodayDecisionSupportCard: View {
    let state: TodayJudgmentDisplayState
    let noActionReasons: [String]
    let actionEvidence: [String]
    let watchCondition: String
    let invalidationCondition: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(state.supportTitle)
                .font(.pretendard(16, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(items.prefix(3), id: \.self) { item in
                    HStack(alignment: .top, spacing: 9) {
                        Image(systemName: state.supportIcon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(state.supportIconColor)
                            .padding(.top, 1)
                        Text(item)
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
        .background(state.supportBackground, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
    }

    private var items: [String] {
        if state == .noAction {
            return noActionReasons
        }

        let evidence = actionEvidence.prefix(2)
        return Array(evidence) + ["확인 기준: \(invalidationCondition.isEmpty ? watchCondition : invalidationCondition)"]
    }
}

// MARK: - Display State

private enum TodayJudgmentDisplayState: Equatable {
    case noAction
    case review
    case immediate

    init(type: JudgmentType) {
        switch type {
        case .simulate:
            self = .noAction
        case .wait, .confirm:
            self = .review
        case .defend:
            self = .immediate
        }
    }

    var label: String {
        switch self {
        case .noAction:  return "행동 불필요"
        case .review:    return "검토 권장"
        case .immediate: return "즉시 확인"
        }
    }

    var background: Color {
        switch self {
        case .noAction:  return Color(hex: "EEF3FE")
        case .review:    return Color(hex: "FFF4E5")
        case .immediate: return Color(hex: "FDECEC")
        }
    }

    var foreground: Color {
        switch self {
        case .noAction:  return Color.brand
        case .review:    return Color(hex: "B86E00")
        case .immediate: return Color.up
        }
    }

    var supportTitle: String {
        switch self {
        case .noAction:
            return "아무것도 안 해도 되는 이유"
        case .review:
            return "지금 확인이 필요한 항목"
        case .immediate:
            return "즉시 확인이 필요한 항목"
        }
    }

    var supportIcon: String {
        switch self {
        case .noAction:
            return "checkmark.circle.fill"
        case .review:
            return "exclamationmark.circle.fill"
        case .immediate:
            return "exclamationmark.triangle.fill"
        }
    }

    var supportIconColor: Color {
        switch self {
        case .noAction:  return Color.brand
        case .review:    return Color.warning
        case .immediate: return Color.up
        }
    }

    var supportBackground: Color {
        switch self {
        case .noAction:  return Color.subtle
        case .review:    return Color.warningBg
        case .immediate: return Color.upBg
        }
    }

    func heroTitle(for judgment: TodayJudgment) -> String {
        switch self {
        case .noAction:
            return "오늘은 특별히 행동할 필요가 없습니다"
        case .review, .immediate:
            return judgment.title
        }
    }

    func heroSubtitle(for judgment: TodayJudgment) -> String {
        switch self {
        case .noAction:
            return judgment.forEvidence.first ?? "보유 자산과 오늘 정책 영향이 관리 가능한 범위에 있습니다."
        case .review:
            return "정책 영향은 제한적이지만 \(judgment.invalidationCondition)을 확인해야 합니다."
        case .immediate:
            return judgment.invalidationCondition
        }
    }
}

// MARK: - Helpers

private extension TodayPortfolioSummary {
    var todayChangePercentText: String {
        let sign = todayChange >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", todayChange))%"
    }

    var todayChangeAmountText: String {
        let sign = todayChangeAmt >= 0 ? "+" : ""
        return "\(sign)₩\(abs(todayChangeAmt).formattedKRW)"
    }

    var todayChangeColor: Color {
        todayChange >= 0 ? Color.up : Color.down
    }
}

private extension TodayPolicyEvent {
    var categoryLabel: String {
        if title.contains("금리") || title.localizedCaseInsensitiveContains("FOMC") {
            return "금리"
        }
        if title.contains("세제") || title.contains("세금") {
            return "세제"
        }
        if title.contains("부동산") {
            return "부동산"
        }
        if title.contains("반도체") {
            return "산업"
        }
        return "정책"
    }

    var impactScore: Int {
        min(5, max(1, (myExposure + 19) / 20))
    }
}

private extension Int {
    var formattedKRW: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview {
    TodayView()
}
