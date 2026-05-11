import SwiftUI

struct OnboardingFlowView: View {
    private enum OnboardingRoute: Hashable {
        case investmentStyle
        case brokerageConnection
        case brokerageSync
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
            OnboardingPage1View(
                viewModel: onboardingViewModel,
                onNext: { path.append(.investmentStyle) },
                onBack: onLogout
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
                        onNext: {
                            if onboardingViewModel.connectedInstitutionID == nil {
                                path.append(.completion)
                            } else {
                                path.append(.brokerageSync)
                            }
                        }
                    )
                case .brokerageSync:
                    OnboardingBrokerageLoadingView(
                        viewModel: onboardingViewModel,
                        onNext: { path.append(.completion) }
                    )
                case .completion:
                    OnboardingPage4View(
                        userId: userId,
                        viewModel: onboardingViewModel,
                        onStart: {
                            onComplete(onboardingViewModel.makeOnboardingResult())
                        }
                    )
                }
            }
        }
        .task(id: userId) {
            await onboardingViewModel.loadInvestmentProfileIfAvailable(userId: userId)
        }
        .preferredColorScheme(.light)
    }

    private func navigateBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

#Preview {
    OnboardingFlowView(onLogout: {}, onComplete: { _ in })
}
