import SwiftUI

enum RootTab: Hashable {
    case home
    case signal
    case asset
    case newsroom
}

struct RootTabView: View {
    let userAssetProfile: UserAssetProfile
    let portfolioSnapshot: PortfolioSnapshot
    @State private var selectedTab: RootTab = .home
    @StateObject private var signalViewModel = SignalViewModel()

    init(
        userAssetProfile: UserAssetProfile = HomeMockData.userAssetProfile,
        portfolioSnapshot: PortfolioSnapshot = HomeMockData.snapshot
    ) {
        self.userAssetProfile = userAssetProfile
        self.portfolioSnapshot = portfolioSnapshot
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(
                    viewModel: HomeViewModel(
                        userAssetProfile: userAssetProfile,
                        portfolioSnapshot: portfolioSnapshot
                    )
                )
            }
            .id(portfolioSnapshot)
            .tag(RootTab.home)
            .tabItem {
                Label("홈", systemImage: "house.fill")
            }

            NavigationStack {
                SignalView(viewModel: signalViewModel)
            }
            .tag(RootTab.signal)
            .tabItem {
                Label("시그널", systemImage: "antenna.radiowaves.left.and.right")
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
                Label("뉴스룸", systemImage: "newspaper.fill")
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
