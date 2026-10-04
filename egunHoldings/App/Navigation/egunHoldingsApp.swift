import SwiftUI

private enum AppLaunchMode {
    static var opensSettingsForUITests: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui-testing-settings")
    }
    /// UI 테스트에서만 인증/네트워크 상태와 독립적으로 실제 메인 탭 레이아웃을 검사한다.
    static var opensMainTabsForUITests: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui-testing-main-tabs")
    }

    static var initialMainTab: RootTab {
        let arguments = ProcessInfo.processInfo.arguments
        guard let tabArgumentIndex = arguments.firstIndex(of: "-ui-testing-main-tab"),
              arguments.indices.contains(tabArgumentIndex + 1)
        else {
            return .today
        }

        switch arguments[tabArgumentIndex + 1] {
        case "newsroom": return .newsroom
        case "asset": return .asset
        default: return .today
        }
    }
}

@main
struct egunHoldingsApp: App {
    @UIApplicationDelegateAdaptor(AppPushNotificationDelegate.self) private var pushNotificationDelegate

    var body: some Scene {
        WindowGroup {
            if ProcessInfo.processInfo.arguments.contains("-ui-testing-signup-email") {
                #if DEBUG
                SignUpView(onBackToLogin: {}, onCompleted: { _ in })
                #else
                StartView()
                #endif
            } else if ProcessInfo.processInfo.arguments.contains("-ui-testing-dashboard-refresh") {
                #if DEBUG
                DashboardUITestRootView()
                #else
                StartView()
                #endif
            } else if AppLaunchMode.opensSettingsForUITests {
                SettingsRootView(notificationCenter: AppNotificationCenter.shared)
            } else if AppLaunchMode.opensMainTabsForUITests {
                RootTabView(
                    initialTab: AppLaunchMode.initialMainTab,
                    brokerBalanceSnapshot: AppMockData.brokerBalanceSnapshot
                )
            } else {
                StartView()
                    .task {
                        await SimulatorWebDemoSnapshotExporter.exportIfRequested()
                    }
            }
        }
    }
}
