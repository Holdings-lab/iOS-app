import SwiftUI

// MARK: - TodayView

struct TodayView: View {
    @StateObject private var viewModel: TodayViewModel
    @StateObject private var policyNewsViewModel: PolicyNewsViewModel
    @StateObject private var notificationCenter = AppNotificationCenter.shared
    @ObservedObject private var exchangeRateViewModel: ExchangeRateViewModel
    @State private var navigationPath = NavigationPath()
    @State private var isPushSlotDismissed = false
    @State private var presentedNotificationDetail: AppNotificationItem?
    private let userId: Int64?
    private let onAssetTabRequested: () -> Void
    private let onSignalRouteRequested: (PolSignalRoute) -> Void
    private let onAnalysisNotificationRequested: (PolSignalAnalysisPayload) -> Void

    init(
        userId: Int64? = nil,
        userAssetProfile: UserAssetProfile = AppMockData.userAssetProfile,
        portfolioSnapshot: PortfolioSnapshot = AppMockData.portfolioSnapshot,
        viewModel: TodayViewModel? = nil,
        exchangeRateViewModel: ExchangeRateViewModel? = nil,
        onAssetTabRequested: @escaping () -> Void = {},
        onSignalRouteRequested: @escaping (PolSignalRoute) -> Void = { _ in },
        onAnalysisNotificationRequested: @escaping (PolSignalAnalysisPayload) -> Void = { _ in }
    ) {
        self.userId = userId
        self.onAssetTabRequested = onAssetTabRequested
        self.onSignalRouteRequested = onSignalRouteRequested
        self.onAnalysisNotificationRequested = onAnalysisNotificationRequested
        _viewModel = StateObject(
            wrappedValue: viewModel ?? TodayViewModel(
                userId: userId,
                userAssetProfile: userAssetProfile,
                portfolioSnapshot: portfolioSnapshot
            )
        )
        _policyNewsViewModel = StateObject(wrappedValue: PolicyNewsViewModel(userId: userId))
        self.exchangeRateViewModel = exchangeRateViewModel ?? ExchangeRateViewModel()
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color.canvas.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        TodayHeaderSection(
                            name: "투자자",
                            hasUnreadNotification: notificationCenter.hasUnreadNotifications,
                            onNotifications: {
                                openNotifications()
                            },
                            onSettings: { navigationPath.append(TodayRoute.settings) }
                        )

                        if let item = notificationCenter.todayPreviewNotification, !isPushSlotDismissed {
                            TodayUnreadNotificationCard(
                                item: item,
                                onOpen: {
                                    openTodayNotification(item)
                                },
                                onDismiss: {
                                    isPushSlotDismissed = true
                                }
                            )
                        }

                        PolSignalTodayBriefingView(
                            themeSignals: viewModel.themeSignals,
                            policyReadings: viewModel.policyReadings,
                            proposal: viewModel.adjustmentProposal,
                            onThemeTap: { theme in
                                // Today 탭 자체 NavigationStack에 push.
                                // 탭 전환 없이 자연스럽게 뒤로가기로 Today에 복귀할 수 있도록 함.
                                navigationPath.append(PolSignalRoute.themeDetail(theme))
                            },
                            onProposalTap: {
                                onSignalRouteRequested(.adjustment)
                            }
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
            .navigationDestination(for: TodayRoute.self) { route in
                switch route {
                case .notifications:
                    NotificationInboxView(
                        notificationCenter: notificationCenter,
                        onAnalysisNotification: { payload in
                            openAnalysisNotification(payload)
                        }
                    )
                case .settings:
                    UserSettingsView(
                        userId: userId,
                        notificationCenter: notificationCenter,
                        connectedBrokerText: viewModel.connectedBrokerStatusText
                    )
                }
            }
            .navigationDestination(for: PolSignalRoute.self) { route in
                switch route {
                case .list:
                    EmptyView()
                case .detail(let id):
                    EmptyView()
                        .onAppear {
                            onSignalRouteRequested(.detail(id))
                        }
                case .adjustment:
                    EmptyView()
                        .onAppear {
                            onSignalRouteRequested(.adjustment)
                        }
                case .policyReader(let id):
                    PolSignalPolicyReaderView(event: PolSignalFlowMockData.policyReading(id: id))
                case .themeDetail(let theme):
                    // Today 탭 내부에서 직접 렌더링 — 탭 전환 없음.
                    SignalThemeDetailView(theme: theme)
                }
            }
            .navigationDestination(item: $policyNewsViewModel.presentedItem) { item in
                PolicyNewsInsightDetailView(
                    item: item,
                    userAssetProfile: viewModel.userAssetProfile,
                    viewModel: policyNewsViewModel
                )
            }
            .toolbar(.hidden, for: .navigationBar)
            .preferredColorScheme(.light)
            .task {
                await viewModel.load()
                await notificationCenter.refreshAuthorizationStatus()
            }
            .sheet(item: $viewModel.activeSheet) { sheet in
                sheetContent(for: sheet)
                    .presentationBackground(.clear)
                    .presentationCornerRadius(KDXRadius.bottomSheet)
            }
            .sheet(item: $presentedNotificationDetail) { item in
                NewsDetailSheet(item: item)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private func openPolicyAnalysis(_ policy: TodayPolicyEvent) {
        policyNewsViewModel.presentSummary(
            for: NewsroomPolicySummaryRequest(
                policyTitle: policy.title,
                relatedAssets: policy.relatedAssets
            ),
            userAssetProfile: viewModel.userAssetProfile,
            mode: .detail
        )
    }

    private func openNotifications() {
        navigationPath.append(TodayRoute.notifications)
    }

    private func openTodayNotification(_ item: AppNotificationItem? = nil) {
        guard let item = item ?? notificationCenter.todayPreviewNotification else {
            openNotifications()
            return
        }

        notificationCenter.markAsRead(item)

        if item.hasDetailContent {
            presentedNotificationDetail = item
        } else if let payload = item.analysisPayload {
            openAnalysisNotification(payload)
        } else {
            openNotifications()
        }
    }

    private func openAnalysisNotification(_ payload: PolSignalAnalysisPayload) {
        notificationCenter.markAnalysisPayloadAsRead(payload)
        onAnalysisNotificationRequested(payload)
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
                onSelect: { policy in
                    viewModel.activeSheet = nil
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 220_000_000)
                        openPolicyAnalysis(policy)
                    }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Header

private struct TodayHeaderSection: View {
    let name: String
    let hasUnreadNotification: Bool
    let onNotifications: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text(Self.dateText)
                    .font(.pretendard(13, weight: .regular))
                    .foregroundStyle(PSColor.textSecondary)
                Text("오늘의 브리핑")
                    .font(.pretendard(28, weight: .bold))
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
        .overlay(alignment: .bottomLeading) {
            Text("3초 안에 오늘 할 일을 파악하세요")
                .font(.pretendard(13, weight: .regular))
                .foregroundStyle(PSColor.textSecondary)
                .offset(y: 24)
        }
        .padding(.bottom, 24)
    }

    private static var dateText: String {
        "5월 28일 목요일"
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

private struct TodayUnreadNotificationCard: View {
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

// MARK: - Judgment Hero

private struct TodayJudgmentHeroCard: View {
    let judgment: TodayJudgment
    let state: TodayJudgmentDisplayState
    let onDetail: () -> Void

    var body: some View {
        Button(action: onDetail) {
            let shape = RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)

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
                        .foregroundStyle(state.foreground)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(state.foreground)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: 24, leading: 16, bottom: 24, trailing: 16))
            .overlay(alignment: .topTrailing) {
                Image(systemName: state.heroIcon)
                    .font(.system(size: 72, weight: .regular))
                    .foregroundStyle(state.foreground.opacity(0.08))
                    .padding(.top, 16)
                    .padding(.trailing, 16)
                    .allowsHitTesting(false)
            }
            .background(Color.elevated, in: shape)
            .overlay { shape.stroke(state.foreground.opacity(0.20), lineWidth: 1) }
            .shadow(color: state.foreground.opacity(0.10), radius: 20, x: 0, y: 6)
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

                Sparkline(
                    points: portfolio.sparklineDisplayPoints,
                    isUp: portfolio.todayChange >= 0,
                    width: nil,
                    height: 48
                )

                let distributionSegments = AssetDistributionSegment.make(from: holdings)
                VStack(alignment: .leading, spacing: 10) {
                    AssetDistributionBar(segments: distributionSegments)
                    AssetDistributionLegend(segments: distributionSegments)
                }
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

private struct AssetDistributionLegend: View {
    let segments: [AssetDistributionSegment]

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ],
            alignment: .leading,
            spacing: 8
        ) {
            ForEach(segments) { segment in
                HStack(spacing: 6) {
                    Circle()
                        .fill(segment.color)
                        .frame(width: 7, height: 7)

                    Text(segment.id.displayName)
                        .font(.pretendard(11, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)

                    Text("\(segment.weight)%")
                        .font(.pretendard(11, weight: .bold))
                        .foregroundStyle(Color.textSecondary)
                        .monospacedDigit()
                }
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            }
        }
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
                    Text("영향도 상위 \(min(totalPolicyCount, policies.count))건")
                        .font(.pretendard(11, weight: .semibold))
                        .foregroundStyle(Color.textQuaternary)
                }

                VStack(spacing: 0) {
                    ForEach(Array(policies.enumerated()), id: \.element.id) { index, policy in
                        Button { onPolicyTap(policy) } label: {
                            PolicyImpactRow(policy: policy)
                                .padding(.vertical, 13)
                        }
                        .buttonStyle(PressScaleButtonStyle())

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
                .buttonStyle(PressScaleButtonStyle())
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
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(state.supportBackground, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
        .shadow(color: Color.cardShadow, radius: 24, x: 0, y: 8)
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

    var heroIcon: String {
        switch self {
        case .noAction:  return "checkmark.circle.fill"
        case .review:    return "eye.circle.fill"
        case .immediate: return "exclamationmark.circle.fill"
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

    var sparklineDisplayPoints: [Double] {
        if !weeklySparklinePoints.isEmpty {
            return weeklySparklinePoints
        }

        let currentAsset = max(Double(totalAsset), 1)
        let previousAsset = currentAsset - Double(todayChangeAmt)
        let delta = currentAsset - previousAsset
        let direction = todayChange >= 0 ? 1.0 : -1.0
        let volatility = max(abs(delta) * 0.28, currentAsset * 0.002)
        let offsets = [-0.34, 0.16, -0.10, 0.30, -0.08, 0.18, 0]

        return offsets.enumerated().map { index, offset in
            guard index < offsets.count - 1 else { return currentAsset }

            let progress = Double(index) / Double(offsets.count - 1)
            let trendValue = previousAsset + delta * progress
            return max(0, trendValue + offset * volatility * direction)
        }
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
