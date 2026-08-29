import SwiftUI

enum RootTab: Hashable {
    case today
    case newsroom
    case asset
}

struct RootTabView: View {
    let userId: Int64?
    let userAssetProfile: UserAssetProfile
    let portfolioSnapshot: PortfolioSnapshot
    let brokerBalanceSnapshot: BrokerBalanceSnapshot?
    let onBrokerBalanceUpdated: (BrokerBalanceSnapshot) -> Void
    @State private var selectedTab: RootTab = .today
    @State private var todaySignalRoute: PolSignalRoute?
    @State private var presentedSignalRoute: PolSignalRoute?
    @ObservedObject private var notificationCenter = AppNotificationCenter.shared

    init(
        userId: Int64? = nil,
        userAssetProfile: UserAssetProfile = AppMockData.userAssetProfile,
        portfolioSnapshot: PortfolioSnapshot = AppMockData.portfolioSnapshot,
        brokerBalanceSnapshot: BrokerBalanceSnapshot? = nil,
        onBrokerBalanceUpdated: @escaping (BrokerBalanceSnapshot) -> Void = { _ in }
    ) {
        self.userId = userId
        self.userAssetProfile = userAssetProfile
        self.portfolioSnapshot = portfolioSnapshot
        self.brokerBalanceSnapshot = brokerBalanceSnapshot
        self.onBrokerBalanceUpdated = onBrokerBalanceUpdated
        setupTabBarAppearance()
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(
                userId: userId,
                userAssetProfile: userAssetProfile,
                portfolioSnapshot: portfolioSnapshot,
                brokerBalanceSnapshot: brokerBalanceSnapshot,
                externalSignalRoute: $todaySignalRoute,
                onAssetTabRequested: {
                    selectedTab = .asset
                },
                onNewsroomTabRequested: {
                    selectedTab = .newsroom
                },
                onSignalRouteRequested: { route in
                    openSignal(route)
                },
                onAnalysisNotificationRequested: { payload in
                    openTodaySignal(notificationCenter.signalRoute(for: payload))
                }
            )
            .tag(RootTab.today)
            .tabItem {
                Label("오늘", systemImage: "sun.max.fill")
            }

            NavigationStack {
                NewsroomView(
                    userId: userId,
                    userAssetProfile: userAssetProfile,
                    onAssetTabRequested: {
                        selectedTab = .asset
                    }
                )
            }
            .tag(RootTab.newsroom)
            .tabItem {
                Label("뉴스룸", systemImage: "newspaper.fill")
            }

            NavigationStack {
                AssetView(
                    brokerBalanceSnapshot: brokerBalanceSnapshot,
                    onBrokerBalanceUpdated: onBrokerBalanceUpdated
                )
            }
            .tag(RootTab.asset)
            .tabItem {
                Label("내 자산", systemImage: "chart.pie.fill")
            }
        }
        .tint(AssetTabPalette.brand)
        .preferredColorScheme(.light)
        .onAppear {
            consumePendingPushRoute()
        }
        .onChange(of: notificationCenter.pendingPushRoute) { _, _ in
            consumePendingPushRoute()
        }
        .fullScreenCover(isPresented: Binding(
            get: { presentedSignalRoute != nil },
            set: { isPresented in
                if !isPresented { presentedSignalRoute = nil }
            }
        )) {
            if let route = presentedSignalRoute {
                SignalView(userId: userId, initialRoute: route)
            }
        }
    }

    private func openSignal(_ route: PolSignalRoute) {
        presentedSignalRoute = route
    }

    private func openTodaySignal(_ route: PolSignalRoute) {
        selectedTab = .today
        todaySignalRoute = route
    }

    private func consumePendingPushRoute() {
        guard let route = notificationCenter.consumePendingPushRoute() else { return }
        openTodaySignal(route)
    }

    /// `RootTabView`는 `AppRouter`가 발행하는 `userAssetProfile`/`portfolioSnapshot`이 바뀔 때마다
    /// (예: 잔고 조회 응답 도착) 구조체 자체가 다시 생성된다. UITabBar의 외형은 전역 상태라 매번
    /// 다시 써도 화면에는 차이가 없으므로, 프로세스당 한 번만 적용해 불필요한 UIColor 변환/전역 쓰기를 막는다.
    private static let didSetupTabBarAppearance: Bool = {
        RootTabView.applyTabBarAppearance()
        return true
    }()

    private func setupTabBarAppearance() {
        _ = Self.didSetupTabBarAppearance
    }

    private static func applyTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AssetTabPalette.card)
        appearance.shadowColor = UIColor(AssetTabPalette.divider)

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor(AssetTabPalette.textSecondary)
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(AssetTabPalette.textSecondary),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        itemAppearance.selected.iconColor = UIColor(AssetTabPalette.brand)
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(AssetTabPalette.brand),
            .font: UIFont.systemFont(ofSize: 10, weight: .bold)
        ]

        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    RootTabView()
}
