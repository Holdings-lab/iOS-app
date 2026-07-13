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
    @State private var selectedTab: RootTab = .today
    @State private var todaySignalRoute: PolSignalRoute?
    @State private var presentedSignalRoute: PolSignalRoute?
    @StateObject private var exchangeRateViewModel = ExchangeRateViewModel()
    @ObservedObject private var notificationCenter = AppNotificationCenter.shared

    init(
        userId: Int64? = nil,
        userAssetProfile: UserAssetProfile = AppMockData.userAssetProfile,
        portfolioSnapshot: PortfolioSnapshot = AppMockData.portfolioSnapshot,
        brokerBalanceSnapshot: BrokerBalanceSnapshot? = nil
    ) {
        self.userId = userId
        self.userAssetProfile = userAssetProfile
        self.portfolioSnapshot = portfolioSnapshot
        self.brokerBalanceSnapshot = brokerBalanceSnapshot
        setupTabBarAppearance()
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(
                userId: userId,
                userAssetProfile: userAssetProfile,
                portfolioSnapshot: portfolioSnapshot,
                exchangeRateViewModel: exchangeRateViewModel,
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
            .id(portfolioSnapshot)
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
                    userId: userId,
                    brokerBalanceSnapshot: brokerBalanceSnapshot,
                    exchangeRateViewModel: exchangeRateViewModel,
                    onAdjustmentRequested: {
                        openSignal(.adjustment)
                    }
                )
            }
            .id(brokerBalanceSnapshot?.fetchedAt)
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

    private func setupTabBarAppearance() {
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
