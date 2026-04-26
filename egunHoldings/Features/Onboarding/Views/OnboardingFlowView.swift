import SwiftUI

struct OnboardingFlowView: View {
    private enum OnboardingRoute: Hashable {
        case investmentStyle
        case brokerageConnection
        case brokerageSync
        case completion
    }

    @ObservedObject var viewModel: AppFlowViewModel
    @StateObject private var onboardingViewModel = OnboardingFlowViewModel()
    @State private var path: [OnboardingRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            OnboardingPage1View(
                viewModel: onboardingViewModel,
                onNext: { path.append(.investmentStyle) },
                onBack: viewModel.logout
            )
            .navigationDestination(for: OnboardingRoute.self) { route in
                switch route {
                case .investmentStyle:
                    OnboardingPage2View(
                        viewModel: onboardingViewModel,
                        onBack: navigateBack,
                        onNext: { path.append(.brokerageConnection) }
                    )
                case .brokerageConnection:
                    OnboardingPage3View(
                        viewModel: onboardingViewModel,
                        onBack: navigateBack,
                        onNext: { path.append(.brokerageSync) }
                    )
                case .brokerageSync:
                    OnboardingBrokerageLoadingView(
                        viewModel: onboardingViewModel,
                        onNext: { path.append(.completion) }
                    )
                case .completion:
                    OnboardingPage4View(
                        viewModel: onboardingViewModel,
                        onStart: {
                            viewModel.completeOnboarding(with: onboardingViewModel.makeOnboardingResult())
                        }
                    )
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func navigateBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

#Preview {
    OnboardingFlowView(viewModel: AppFlowViewModel())
}
