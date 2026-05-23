import UIKit
import UserNotifications

final class AppPushNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            AppNotificationCenter.shared.updateDeviceToken(deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Task { @MainActor in
            AppNotificationCenter.shared.updateRemoteRegistrationError(error)
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let payload = analysisPayload(from: response.notification.request.content.userInfo) else {
            return
        }

        await MainActor.run {
            NotificationCenter.default.post(
                name: .polSignalAnalysisPayloadReceived,
                object: payload
            )
        }
    }

    private func analysisPayload(from userInfo: [AnyHashable: Any]) -> PolSignalAnalysisPayload? {
        let eventId: Int?
        if let value = userInfo["eventId"] as? Int {
            eventId = value
        } else if let value = userInfo["eventId"] as? String {
            eventId = Int(value)
        } else {
            eventId = nil
        }

        guard let eventId,
              let analysisVersion = userInfo["analysisVersion"] as? String
        else {
            return nil
        }

        return PolSignalAnalysisPayload(
            eventId: eventId,
            analysisVersion: analysisVersion
        )
    }
}
