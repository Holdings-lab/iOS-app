import SwiftUI

#if DEBUG

@MainActor
enum UITestLaunchMode {
    private static let arguments = ProcessInfo.processInfo.arguments
    static let isDashboardRefresh = arguments.contains("-ui-testing-dashboard-refresh")
    static let isSignupEmail = arguments.contains("-ui-testing-signup-email")
    static let isSettings = arguments.contains("-ui-testing-settings")
    static let isMainTabs = arguments.contains("-ui-testing-main-tabs")
    static var isEnabled: Bool { isSignupEmail || isDashboardRefresh || isSettings || isMainTabs }

    static var initialMainTab: RootTab {
        guard let index = arguments.firstIndex(of: "-ui-testing-main-tab"),
              arguments.indices.contains(index + 1) else { return .today }
        switch arguments[index + 1] {
        case "newsroom": return .newsroom
        case "asset": return .asset
        default: return .today
        }
    }
}

struct UITestLaunchRootView: View {
    var body: some View {
        if UITestLaunchMode.isSignupEmail {
            SignUpView(onBackToLogin: {}, onCompleted: { _ in }, viewModel: signupModel)
        } else if UITestLaunchMode.isDashboardRefresh {
            DashboardUITestRootView()
        } else if UITestLaunchMode.isSettings {
            SettingsRootView(notificationCenter: AppNotificationCenter.shared)
        } else {
            RootTabView(initialTab: UITestLaunchMode.initialMainTab,
                        brokerBalanceSnapshot: AppMockData.brokerBalanceSnapshot)
        }
    }

    private var signupModel: SignUpFlowViewModel {
        let model = SignUpFlowViewModel()
        model.moveToEmailVerification()
        return model
    }
}
#endif

extension View {
    @ViewBuilder
    func dashboardUITestLoadingIndicator(isLoading: Bool, identifier: String) -> some View {
        #if DEBUG
        overlay(alignment: .topLeading) {
            if UITestLaunchMode.isDashboardRefresh {
                Text("로딩: \(isLoading ? 1 : 0)")
                    .accessibilityIdentifier(identifier)
                    .font(.system(size: 9))
                    .allowsHitTesting(false)
            }
        }
        #else
        self
        #endif
    }
}
