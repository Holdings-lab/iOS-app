import SwiftUI

// MARK: - Navigation

// NavigationPath에 서로 다른 타입을 섞으면 SwiftUI 내부 경로 비교에서
// AnyNavigationPath.Error.comparisonTypeMismatch 크래시가 나므로 단일 타입으로 통합한다.
// 같은 이유로, 자체 NavigationStack을 가진 화면(SettingsRootView 등)은 이 경로에 push하지 않고
// fullScreenCover로 띄운다 — NavigationStack 중첩도 동일한 크래시를 유발한다.
enum TodayNavDestination: Hashable {
    case today(TodayRoute)
    case signal(PolSignalRoute)
    case policyNews(PolicyNewsItem)
}

private enum TodaySettingsDestination: String, Identifiable {
    case root, goal
    var id: String { rawValue }
    var initialRoute: SettingsRoute? { self == .goal ? .goal : nil }
}

// MARK: - TodayView

struct TodayView: View {
    @StateObject private var viewModel: TodayViewModel
    @StateObject private var policyNewsViewModel: PolicyNewsViewModel
    @StateObject private var notificationCenter = AppNotificationCenter.shared
    @State private var navigationPath: [TodayNavDestination] = []
    @State private var isPushSlotDismissed = false
    @State private var presentedSettings: TodaySettingsDestination?
    @State private var presentedNotificationDetail: AppNotificationItem?
    @Binding private var externalSignalRoute: PolSignalRoute?
    private let userId: Int64?
    private let onboardingResult: OnboardingResult?
    private let userAssetProfile: UserAssetProfile
    private let portfolioSnapshot: PortfolioSnapshot
    private let brokerBalanceSnapshot: BrokerBalanceSnapshot?
    private let onAssetTabRequested: () -> Void
    private let onGoalSaved: (FinancialGoal, Int64) -> Void
    private let settingsRepository: any SettingsRepositoryProtocol
    private let refreshSessionID: Int
    private let onPullRefreshStarted: () -> Void
    private let onNewsroomTabRequested: () -> Void
    private let onSignalRouteRequested: (PolSignalRoute) -> Void
    private let onAnalysisNotificationRequested: (PolSignalAnalysisPayload) -> Void

    init(
        userId: Int64? = nil,
        onboardingResult: OnboardingResult? = nil,
        userAssetProfile: UserAssetProfile = AppMockData.userAssetProfile,
        portfolioSnapshot: PortfolioSnapshot = AppMockData.portfolioSnapshot,
        brokerBalanceSnapshot: BrokerBalanceSnapshot? = nil,
        repository: TodayRepositoryProtocol? = nil,
        viewModel: TodayViewModel? = nil,
        externalSignalRoute: Binding<PolSignalRoute?> = .constant(nil),
        onGoalSaved: @escaping (FinancialGoal, Int64) -> Void = { _, _ in },
        settingsRepository: any SettingsRepositoryProtocol = LiveSettingsRepository(),
        refreshSessionID: Int = 0,
        onPullRefreshStarted: @escaping () -> Void = {},
        onAssetTabRequested: @escaping () -> Void = {},
        onNewsroomTabRequested: @escaping () -> Void = {},
        onSignalRouteRequested: @escaping (PolSignalRoute) -> Void = { _ in },
        onAnalysisNotificationRequested: @escaping (PolSignalAnalysisPayload) -> Void = { _ in }
    ) {
        self.userId = userId
        self.onboardingResult = onboardingResult
        self.userAssetProfile = userAssetProfile
        self.portfolioSnapshot = portfolioSnapshot
        self.brokerBalanceSnapshot = brokerBalanceSnapshot
        self.onAssetTabRequested = onAssetTabRequested
        self.onGoalSaved = onGoalSaved
        self.settingsRepository = settingsRepository
        self.refreshSessionID = refreshSessionID
        self.onPullRefreshStarted = onPullRefreshStarted
        self.onNewsroomTabRequested = onNewsroomTabRequested
        self.onSignalRouteRequested = onSignalRouteRequested
        self.onAnalysisNotificationRequested = onAnalysisNotificationRequested
        _viewModel = StateObject(
            wrappedValue: viewModel ?? TodayViewModel(
                userId: userId,
                onboardingResult: onboardingResult,
                userAssetProfile: userAssetProfile,
                portfolioSnapshot: portfolioSnapshot,
                brokerBalanceSnapshot: brokerBalanceSnapshot,
                repository: repository
            )
        )
        _policyNewsViewModel = StateObject(wrappedValue: PolicyNewsViewModel(userId: userId))
        _externalSignalRoute = externalSignalRoute
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color.canvas.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        TodayHeaderSection(
                            hasUnreadNotification: notificationCenter.hasUnreadNotifications,
                            onNotifications: {
                                openNotifications()
                            },
                            onSettings: {
                                presentedSettings = .root
                            }
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

                        if let dataFallbackMessage {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(Color.trendDown)
                                Text(dataFallbackMessage)
                                    .font(.pretendard(12, weight: .medium))
                                    .foregroundStyle(Color.textSecondary)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.trendDown.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .accessibilityIdentifier("today.liveDataFallbackNotice")
                        }

                        if viewModel.loadingSections.contains(.briefing) {
                            TodayBriefingSkeleton()
                        } else {
                            TodayBriefingCard(
                                briefing: viewModel.briefing,
                                isAccountLinked: viewModel.isAccountLinked
                            )
                        }
                        if viewModel.loadingSections.contains(.holdings) {
                            TodayHoldingsSkeleton()
                        } else {
                            TodayHoldingsTop3Card(
                                holdings: viewModel.topHoldings,
                                isAccountLinked: viewModel.isAccountLinked,
                                onConnectAccount: onAssetTabRequested
                            )
                        }
                        if viewModel.loadingSections.contains(.goal) {
                            TodayGoalProgressSkeleton()
                        } else {
                            TodayGoalProgressCard(
                                goalProgress: viewModel.goalProgress,
                                onSetGoal: {
                                    presentedSettings = .goal
                                }
                            )
                            .accessibilityIdentifier("today.goalProgress")
                        }
                        if viewModel.loadingSections.contains(.news) {
                            TodayNewsSkeleton()
                        } else {
                            TodayNewsSection(
                                newsItems: viewModel.newsItems,
                                isAccountLinked: viewModel.isAccountLinked,
                                onNewsTap: openNewsItem,
                                onSeeMoreTapped: onNewsroomTabRequested
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 112)
                }
                .refreshable {
                    onPullRefreshStarted()
                    await viewModel.refresh()
                }
            }
            .navigationDestination(for: TodayNavDestination.self) { destination in
                switch destination {
                case .today(.notifications):
                    NotificationInboxView(
                        notificationCenter: notificationCenter,
                        onAnalysisNotification: { payload in
                            openAnalysisNotification(payload)
                        }
                    )
                case .signal(.list):
                    EmptyView()
                case .signal(.detail(let id)):
                    EmptyView()
                        .onAppear {
                            onSignalRouteRequested(.detail(id))
                        }
                case .signal(.adjustment):
                    EmptyView()
                        .onAppear {
                            onSignalRouteRequested(.adjustment)
                        }
                case .signal(.policyReader(let id)):
                    PolSignalPolicyReaderView(event: policyReading(id: id))
                case .signal(.themeDetail(let theme)):
                    // Today 탭 내부에서 직접 렌더링 — 탭 전환 없음.
                    SignalThemeDetailView(theme: theme)
                case .policyNews(let item):
                    PolicyNewsInsightDetailView(
                        item: item,
                        userAssetProfile: viewModel.userAssetProfile,
                        viewModel: policyNewsViewModel
                    )
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .preferredColorScheme(.light)
            .onAppear {
                consumeExternalSignalRoute()
            }
            .onChange(of: externalSignalRoute) { _, _ in
                consumeExternalSignalRoute()
            }
            // 잔고 조회가 늦게 도착해도 화면을 재생성하지 않고 데이터만 갈아끼운다.
            .onChange(of: portfolioSnapshot) { _, _ in
                syncSessionData()
            }
            .onChange(of: userAssetProfile) { _, _ in
                syncSessionData()
            }
            .onChange(of: brokerBalanceSnapshot) { _, _ in
                syncSessionData()
            }
            .onChange(of: onboardingResult?.targetAmount) { _, _ in
                syncSessionData()
            }
            .onChange(of: onboardingResult?.financialGoal) { _, _ in
                syncSessionData()
            }
            .onChange(of: policyNewsViewModel.presentedItem) { _, item in
                syncPolicyNewsDestination(with: item)
            }
            .onChange(of: navigationPath) { _, newPath in
                // 뒤로가기 제스처 등으로 상세 화면이 경로에서 빠지면 뷰모델 상태도 함께 정리한다.
                let hasPolicyNews = newPath.contains { destination in
                    if case .policyNews = destination { return true }
                    return false
                }
                if !hasPolicyNews, policyNewsViewModel.presentedItem != nil {
                    policyNewsViewModel.dismissPresentedInsight()
                }
            }
            .task {
                await viewModel.load()
                await notificationCenter.refreshAuthorizationStatus()
            }
            .task { await viewModel.observeNews() }
            .onDisappear { viewModel.cancelLoading() }
            #if DEBUG
            .overlay(alignment: .topLeading) {
                if ProcessInfo.processInfo.arguments.contains("-ui-testing-dashboard-refresh") {
                    Text("로딩: \(viewModel.loadState == .loading ? 1 : 0)")
                        .accessibilityIdentifier("ui.todayLoading")
                        .font(.system(size: 9))
                        .allowsHitTesting(false)
                }
            }
            #endif
            .sheet(item: $presentedNotificationDetail) { item in
                NewsDetailSheet(item: item)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .fullScreenCover(item: $presentedSettings) { destination in
                SettingsRootView(
                    notificationCenter: notificationCenter,
                    initialRoute: destination.initialRoute,
                    onboardingResult: onboardingResult,
                    onGoalSaved: onGoalSaved,
                    repository: settingsRepository
                )
            }
        }
        // 뷰모델과 경로는 TodayView에 남기고, 이전 refresh control만 재생성한다.
        .id(refreshSessionID)
    }

    private var dataFallbackMessage: String? {
        guard case let .usingFallback(message?) = viewModel.loadState else { return nil }
        return message
    }

    private func syncSessionData() {
        viewModel.updateSessionData(
            userAssetProfile: userAssetProfile,
            portfolioSnapshot: portfolioSnapshot,
            onboardingResult: onboardingResult,
            brokerBalanceSnapshot: brokerBalanceSnapshot
        )
    }

    private func openNewsItem(_ item: TodayNewsItem) {
        policyNewsViewModel.presentSummary(
            for: NewsroomPolicySummaryRequest(
                policyTitle: item.title,
                relatedAssets: [item.ticker].compactMap { $0 }
            ),
            userAssetProfile: viewModel.userAssetProfile,
            mode: .detail
        )
    }

    private func openNotifications() {
        navigationPath.append(.today(.notifications))
    }

    private func syncPolicyNewsDestination(with item: PolicyNewsItem?) {
        if case .policyNews = navigationPath.last {
            navigationPath.removeLast()
        }
        if let item {
            navigationPath.append(.policyNews(item))
        }
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

    private func consumeExternalSignalRoute() {
        guard let route = externalSignalRoute else { return }
        externalSignalRoute = nil
        navigationPath.append(.signal(route))
    }

    private func policyReading(id: Int) -> PolSignalPolicyReading {
        PolSignalFlowMockData.policyReading(id: id)
    }
}

// MARK: - Header


// MARK: - Preview

#Preview("1. 평온한 날") {
    TodayView(viewModel: .init(
        userId: nil,
        dashboard: TodayDashboard(
            userAssetProfile: AppMockData.userAssetProfile,
            portfolioSnapshot: AppMockData.portfolioSnapshot,
            isAccountLinked: true,
            briefing: TodayMockData.briefingCalm,
            holdings: TodayMockData.holdings,
            goalProgress: TodayMockData.goalProgressAhead,
            newsItems: TodayMockData.newsItems
        )
    ))
}

#Preview("2. 주의") {
    TodayView(viewModel: .init(
        userId: nil,
        dashboard: TodayDashboard(
            userAssetProfile: AppMockData.userAssetProfile,
            portfolioSnapshot: AppMockData.portfolioSnapshot,
            isAccountLinked: true,
            briefing: TodayMockData.briefingWatch,
            holdings: TodayMockData.holdings,
            goalProgress: TodayMockData.goalProgressOnTrack,
            newsItems: TodayMockData.newsItems
        )
    ))
}

#Preview("3. 경고") {
    TodayView(viewModel: .init(
        userId: nil,
        dashboard: TodayDashboard(
            userAssetProfile: AppMockData.userAssetProfile,
            portfolioSnapshot: AppMockData.portfolioSnapshot,
            isAccountLinked: true,
            briefing: TodayMockData.briefingAlert,
            holdings: TodayMockData.holdings,
            goalProgress: TodayMockData.goalProgressBehind,
            newsItems: TodayMockData.newsItems
        )
    ))
}

#Preview("4. 계좌 미연동") {
    TodayView(viewModel: .init(
        userId: nil,
        dashboard: TodayDashboard(
            userAssetProfile: UserAssetProfile(holdings: []),
            portfolioSnapshot: AppMockData.portfolioSnapshot,
            isAccountLinked: false,
            briefing: TodayMockData.briefingCalm,
            holdings: TodayMockData.emptyHoldings,
            goalProgress: nil,
            newsItems: TodayMockData.newsItems
        )
    ))
}

#Preview("5. 뉴스 없음") {
    TodayView(viewModel: .init(
        userId: nil,
        dashboard: TodayDashboard(
            userAssetProfile: AppMockData.userAssetProfile,
            portfolioSnapshot: AppMockData.portfolioSnapshot,
            isAccountLinked: true,
            briefing: TodayMockData.briefingCalm,
            holdings: TodayMockData.holdings,
            goalProgress: TodayMockData.goalProgressAhead,
            newsItems: TodayMockData.emptyNews
        )
    ))
}

#Preview("6. 로딩") {
    TodayView(viewModel: .init(
        userId: nil,
        dashboard: TodayDashboard(
            userAssetProfile: AppMockData.userAssetProfile,
            portfolioSnapshot: AppMockData.portfolioSnapshot,
            isAccountLinked: true,
            briefing: TodayMockData.briefingCalm,
            holdings: TodayMockData.holdings,
            goalProgress: TodayMockData.goalProgressAhead,
            newsItems: TodayMockData.newsItems
        ),
        loadState: .loading
    ))
}

#Preview("7. 목표 방금 시작") {
    TodayView(viewModel: .init(
        userId: nil,
        dashboard: TodayDashboard(
            userAssetProfile: AppMockData.userAssetProfile,
            portfolioSnapshot: AppMockData.portfolioSnapshot,
            isAccountLinked: true,
            briefing: TodayMockData.briefingCalm,
            holdings: TodayMockData.holdings,
            goalProgress: TodayMockData.goalProgressJustStarted,
            newsItems: TodayMockData.newsItems
        )
    ))
}
