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
                    onLogout: router.logout,
                    onComplete: router.completeOnboarding
                )
            case .main:
                RootTabView(
                    userId: router.session?.userId,
                    userAssetProfile: router.userAssetProfile,
                    portfolioSnapshot: router.portfolioSnapshot
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
            LinearGradient(
                colors: [Color.deepNavy, Color(hex: "0D1C5A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .tint(Color.electricBlue)
                    .scaleEffect(1.3)

                Text("불러오는 중...")
                    .font(.pretendard(14, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)
            }
        }
    }
}

#Preview {
    AppRootView(startFromLogin: true)
}
