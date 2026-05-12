import SwiftUI

enum RootTab: Hashable {
    case today
    case asset
    case news
}

struct RootTabView: View {
    let userId: Int64?
    let userAssetProfile: UserAssetProfile
    let portfolioSnapshot: PortfolioSnapshot
    let brokerBalanceSnapshot: BrokerBalanceSnapshot?
    @State private var selectedTab: RootTab = .today
    @StateObject private var exchangeRateViewModel = ExchangeRateViewModel()

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
                }
            )
            .id(portfolioSnapshot)
            .tag(RootTab.today)
            .tabItem {
                Label("오늘", systemImage: "sun.max.fill")
            }

            NavigationStack {
                AssetView(
                    userId: userId,
                    brokerBalanceSnapshot: brokerBalanceSnapshot,
                    exchangeRateViewModel: exchangeRateViewModel
                )
            }
            .id(brokerBalanceSnapshot?.fetchedAt)
            .tag(RootTab.asset)
            .tabItem {
                Label("내자산", systemImage: "chart.pie.fill")
            }

            NavigationStack {
                NewsroomView(
                    userId: userId,
                    userAssetProfile: userAssetProfile
                )
            }
            .tag(RootTab.news)
            .tabItem {
                Label("뉴스", systemImage: "newspaper.fill")
            }
        }
        .tint(Color.brand)
        .preferredColorScheme(.light)
    }

    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white
        appearance.shadowColor = UIColor(Color.hairline)

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor(Color.textDisabled)
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.textDisabled),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        itemAppearance.selected.iconColor = UIColor(Color.brand)
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.brand),
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
