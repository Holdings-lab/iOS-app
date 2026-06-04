import SwiftUI

enum RootTab: Hashable {
    case today
    case signal
    case asset
}

struct RootTabView: View {
    let userId: Int64?
    let userAssetProfile: UserAssetProfile
    let portfolioSnapshot: PortfolioSnapshot
    let brokerBalanceSnapshot: BrokerBalanceSnapshot?
    @State private var selectedTab: RootTab = .today
    @State private var signalRoute: PolSignalRoute?
    @State private var signalViewIdentity = UUID()
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
                onAssetTabRequested: {
                    selectedTab = .asset
                },
                onSignalRouteRequested: { route in
                    openSignal(route)
                },
                onAnalysisNotificationRequested: { payload in
                    openSignal(notificationCenter.signalRoute(for: payload))
                }
            )
            .id(portfolioSnapshot)
            .tag(RootTab.today)
            .tabItem {
                Label("오늘", systemImage: "sun.max.fill")
            }

            SignalView(initialRoute: signalRoute, externalRoute: $signalRoute)
                .id(signalViewIdentity)
            .tag(RootTab.signal)
            .tabItem {
                Label("시그널", systemImage: "waveform.path.ecg")
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
    }

    private func openSignal(_ route: PolSignalRoute) {
        signalRoute = route
        signalViewIdentity = UUID()
        selectedTab = .signal
    }

    private func consumePendingPushRoute() {
        guard let route = notificationCenter.consumePendingPushRoute() else { return }
        openSignal(route)
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
