import SwiftUI

@main
struct egunHoldingsApp: App {
    @UIApplicationDelegateAdaptor(AppPushNotificationDelegate.self) private var pushNotificationDelegate

    var body: some Scene {
        WindowGroup {
            AppLaunchRootView()
        }
    }
}

private struct AppLaunchRootView: View {
    var body: some View {
        #if DEBUG
        if UITestLaunchMode.isEnabled {
            UITestLaunchRootView()
        } else {
            standardRoot
        }
        #else
        standardRoot
        #endif
    }

    private var standardRoot: some View {
        StartView()
            .task { await SimulatorWebDemoSnapshotExporter.exportIfRequested() }
    }
}
