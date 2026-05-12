import SwiftUI

@main
struct egunHoldingsApp: App {
    @UIApplicationDelegateAdaptor(AppPushNotificationDelegate.self) private var pushNotificationDelegate

    var body: some Scene {
        WindowGroup {
            StartView()
        }
    }
}
