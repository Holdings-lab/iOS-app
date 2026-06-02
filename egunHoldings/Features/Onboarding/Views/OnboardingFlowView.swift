import SwiftUI

struct OnboardingFlowView: View {
    private enum OnboardingRoute: Hashable {
        case brokerageConnection
        case brokerageLoading
    }

    let onLogout: () -> Void
    let onComplete: (OnboardingResult) -> Void

    @StateObject private var onboardingViewModel = OnboardingFlowViewModel()
    @State private var path: [OnboardingRoute] = []

    init(
        onLogout: @escaping () -> Void,
        onComplete: @escaping (OnboardingResult) -> Void
    ) {
        self.onLogout = onLogout
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack(path: $path) {
            OnboardingPage1View(
                viewModel: onboardingViewModel,
                onNext: { path.append(.brokerageConnection) },
                onBack: onLogout
            )
            .navigationDestination(for: OnboardingRoute.self) { route in
                switch route {
                case .brokerageConnection:
                    OnboardingPage3View(
                        viewModel: onboardingViewModel,
                        onBack: navigateBack,
                        onNext: { path.append(.brokerageLoading) },
                        onSkip: completeOnboarding
                    )
                case .brokerageLoading:
                    OnboardingBrokerageLoadingView(
                        viewModel: onboardingViewModel,
                        onComplete: completeOnboarding
                    )
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private func navigateBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    private func completeOnboarding() {
        onComplete(onboardingViewModel.makeOnboardingResult())
    }
}

#Preview {
    OnboardingFlowView(onLogout: {}, onComplete: { _ in })
}
