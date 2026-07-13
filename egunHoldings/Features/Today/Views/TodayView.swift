import SwiftUI

// MARK: - Navigation

// NavigationPath에 서로 다른 타입을 섞으면 SwiftUI 내부 경로 비교에서
// AnyNavigationPath.Error.comparisonTypeMismatch 크래시가 나므로 단일 타입으로 통합한다.
enum TodayNavDestination: Hashable {
    case today(TodayRoute)
    case signal(PolSignalRoute)
    case policyNews(PolicyNewsItem)
}

// MARK: - TodayView

struct TodayView: View {
    @StateObject private var viewModel: TodayViewModel
    @StateObject private var policyNewsViewModel: PolicyNewsViewModel
    @StateObject private var notificationCenter = AppNotificationCenter.shared
    @ObservedObject private var exchangeRateViewModel: ExchangeRateViewModel
    @State private var navigationPath: [TodayNavDestination] = []
    @State private var isPushSlotDismissed = false
    @State private var presentedNotificationDetail: AppNotificationItem?
    @Binding private var externalSignalRoute: PolSignalRoute?
    private let userId: Int64?
    private let onAssetTabRequested: () -> Void
    private let onNewsroomTabRequested: () -> Void
    private let onSignalRouteRequested: (PolSignalRoute) -> Void
    private let onAnalysisNotificationRequested: (PolSignalAnalysisPayload) -> Void

    init(
        userId: Int64? = nil,
        userAssetProfile: UserAssetProfile = AppMockData.userAssetProfile,
        portfolioSnapshot: PortfolioSnapshot = AppMockData.portfolioSnapshot,
        viewModel: TodayViewModel? = nil,
        exchangeRateViewModel: ExchangeRateViewModel? = nil,
        externalSignalRoute: Binding<PolSignalRoute?> = .constant(nil),
        onAssetTabRequested: @escaping () -> Void = {},
        onNewsroomTabRequested: @escaping () -> Void = {},
        onSignalRouteRequested: @escaping (PolSignalRoute) -> Void = { _ in },
        onAnalysisNotificationRequested: @escaping (PolSignalAnalysisPayload) -> Void = { _ in }
    ) {
        self.userId = userId
        self.onAssetTabRequested = onAssetTabRequested
        self.onNewsroomTabRequested = onNewsroomTabRequested
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
        _externalSignalRoute = externalSignalRoute
        self.exchangeRateViewModel = exchangeRateViewModel ?? ExchangeRateViewModel()
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
                            onSettings: { navigationPath.append(.today(.settings)) }
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

                        if viewModel.loadState == .loading {
                            TodayBriefingSkeleton()
                            TodayHoldingsSkeleton()
                            TodayGoalProgressSkeleton()
                            TodayNewsSkeleton()
                        } else {
                            TodayBriefingCard(
                                briefing: viewModel.briefing,
                                isAccountLinked: viewModel.isAccountLinked,
                                onConnectAccount: onAssetTabRequested
                            )

                            TodayHoldingsTop3Card(
                                holdings: viewModel.topHoldings,
                                isAccountLinked: viewModel.isAccountLinked,
                                onConnectAccount: onAssetTabRequested
                            )

                            TodayGoalProgressCard(
                                goalProgress: viewModel.goalProgress,
                                onSetGoal: onAssetTabRequested
                            )

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
                case .today(.settings):
                    SettingsRootView(notificationCenter: notificationCenter)
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
            .sheet(item: $presentedNotificationDetail) { item in
                NewsDetailSheet(item: item)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
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
