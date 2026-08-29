import SwiftUI

@MainActor
struct AppRootView: View {
    @StateObject private var router: AppRouter
    private let startFromLogin: Bool

    init(startFromLogin: Bool = false) {
        _router = StateObject(wrappedValue: AppRouter())
        self.startFromLogin = startFromLogin
    }

    var body: some View {
        Group {
            switch router.route {
            case .loading:
                loadingView
            case .auth:
                AuthContainerView(onLoginSuccess: router.handleLoginSuccess)
            case .onboarding:
                OnboardingFlowView(
                    userId: router.session?.userId,
                    userName: router.userName,
                    onLogout: router.logout,
                    onComplete: router.completeOnboarding
                )
            case .main:
                RootTabView(
                    userId: router.session?.userId,
                    userAssetProfile: router.userAssetProfile,
                    portfolioSnapshot: router.portfolioSnapshot,
                    brokerBalanceSnapshot: router.session?.brokerBalanceSnapshot,
                    onBrokerBalanceUpdated: router.updateBrokerBalance
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: router.route)
        .task {
            guard startFromLogin else { return }
            router.logout()
        }
    }

    private var loadingView: some View {
        ZStack {
            Color.canvas
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .tint(Color.brand)
                    .scaleEffect(1.3)

                Text("불러오는 중...")
                    .font(.pretendard(14, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }
        }
    }
}

#Preview {
    AppRootView(startFromLogin: true)
}
