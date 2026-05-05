import SwiftUI

enum RootTab: Hashable {
    case home
    case asset
    case newsroom
}

struct RootTabView: View {
    let userId: Int64?
    let userAssetProfile: UserAssetProfile
    let portfolioSnapshot: PortfolioSnapshot
    @State private var selectedTab: RootTab = .home
    @StateObject private var signalViewModel = SignalViewModel()

    init(
        userId: Int64? = nil,
        userAssetProfile: UserAssetProfile = AppMockData.userAssetProfile,
        portfolioSnapshot: PortfolioSnapshot = AppMockData.portfolioSnapshot
    ) {
        self.userId = userId
        self.userAssetProfile = userAssetProfile
        self.portfolioSnapshot = portfolioSnapshot
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(
                userId: userId,
                userAssetProfile: userAssetProfile,
                portfolioSnapshot: portfolioSnapshot
            )
            .id(portfolioSnapshot)
            .tag(RootTab.home)
            .tabItem {
                Label("오늘", systemImage: "calendar")
            }

            NavigationStack {
                AssetView(signalViewModel: signalViewModel)
            }
            .tag(RootTab.asset)
            .tabItem {
                Label("내 자산", systemImage: "wallet.pass.fill")
            }

            NavigationStack {
                NewsroomView(userAssetProfile: userAssetProfile)
            }
            .tag(RootTab.newsroom)
            .tabItem {
                Label("뉴스", systemImage: "newspaper.fill")
            }
        }
        .tint(Color.electricBlue)
        .preferredColorScheme(.dark)
        .background(Color.deepNavy.ignoresSafeArea())
    }
}

#Preview {
    RootTabView()
}
