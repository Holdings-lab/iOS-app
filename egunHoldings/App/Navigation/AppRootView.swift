import SwiftUI

@MainActor
struct AppRootView: View {
    @StateObject private var flowViewModel: AppFlowViewModel
    private let startFromLogin: Bool

    init(startFromLogin: Bool = false) {
        _flowViewModel = StateObject(wrappedValue: AppFlowViewModel())
        self.startFromLogin = startFromLogin
    }

    var body: some View {
        Group {
            switch flowViewModel.route {
            case .loading:
                loadingView
            case .auth:
                AuthContainerView(viewModel: flowViewModel)
            case .onboarding:
                OnboardingFlowView(viewModel: flowViewModel)
            case .main:
                RootTabView(
                    userAssetProfile: flowViewModel.userAssetProfile,
                    portfolioSnapshot: flowViewModel.portfolioSnapshot
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: flowViewModel.route)
        .task {
            guard startFromLogin else { return }
            flowViewModel.logout()
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
