import SwiftUI

struct OnboardingFlowView: View {
    private enum OnboardingRoute: Hashable {
        case targetAmount
        case horizon
        case drawdown
        case profile
        case watchAssets
        case brokerage
        case completion
    }

    let userId: Int64?
    let onLogout: () -> Void
    let onComplete: (OnboardingResult) -> Void

    @StateObject private var onboardingViewModel = OnboardingFlowViewModel()
    @State private var path: [OnboardingRoute] = []

    init(
        userId: Int64? = nil,
        onLogout: @escaping () -> Void,
        onComplete: @escaping (OnboardingResult) -> Void
    ) {
        self.userId = userId
        self.onLogout = onLogout
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack(path: $path) {
            OnboardingStep1GoalView(
                viewModel: onboardingViewModel,
                onNext: { path.append(.targetAmount) },
                onBack: onLogout
            )
            .navigationDestination(for: OnboardingRoute.self) { route in
                switch route {
                case .targetAmount:
                    OnboardingStep2TargetAmountView(
                        viewModel: onboardingViewModel,
                        onNext: { path.append(.horizon) },
                        onBack: navigateBack
                    )
                case .horizon:
                    OnboardingStep3HorizonView(
                        viewModel: onboardingViewModel,
                        onNext: { path.append(.drawdown) },
                        onBack: navigateBack
                    )
                case .drawdown:
                    OnboardingStep4DrawdownView(
                        viewModel: onboardingViewModel,
                        onNext: { path.append(.profile) },
                        onBack: navigateBack
                    )
                case .profile:
                    OnboardingStep5ProfileView(
                        viewModel: onboardingViewModel,
                        onNext: { path.append(.watchAssets) },
                        onBack: navigateBack
                    )
                case .watchAssets:
                    OnboardingStep6WatchAssetsView(
                        viewModel: onboardingViewModel,
                        onNext: { path.append(.brokerage) },
                        onBack: navigateBack
                    )
                case .brokerage:
                    OnboardingStep7BrokerageView(
                        viewModel: onboardingViewModel,
                        userId: userId,
                        onBack: navigateBack,
                        onNext: { path.append(.completion) },
                        onSkip: { path.append(.completion) }
                    )
                case .completion:
                    OnboardingStep8CompletionView(
                        viewModel: onboardingViewModel,
                        userId: userId,
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
