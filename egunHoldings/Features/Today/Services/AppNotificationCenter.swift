import Combine
import Foundation
import UIKit
import UserNotifications

@MainActor
final class AppNotificationCenter: ObservableObject {
    static let shared = AppNotificationCenter()

    @Published private(set) var notifications: [AppNotificationItem]
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var deviceToken: String?
    @Published private(set) var remoteRegistrationError: String?
    @Published private(set) var pendingPushRoute: PolSignalRoute?

    private let center: UNUserNotificationCenter

    var hasUnreadNotifications: Bool {
        notifications.contains { !$0.isRead }
    }

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    var latestUnreadAnalysisPayload: PolSignalAnalysisPayload? {
        notifications
            .first { !$0.isRead && $0.analysisPayload != nil }?
            .analysisPayload
    }

    var todayPreviewNotification: AppNotificationItem? {
        notifications.first { !$0.isRead && $0.kind == .news && $0.hasDetailContent }
            ?? notifications.first { !$0.isRead && $0.hasDetailContent }
            ?? notifications.first { !$0.isRead }
    }

    var authorizationStatusText: String {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "허용됨"
        case .denied:
            return "거부됨"
        case .notDetermined:
            return "요청 전"
        @unknown default:
            return "확인 필요"
        }
    }

    var remoteRegistrationStatusText: String {
        if deviceToken != nil {
            return "등록됨"
        }

        if remoteRegistrationError != nil {
            return "등록 실패"
        }

        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "등록 대기"
        case .denied:
            return "권한 거부"
        case .notDetermined:
            return "요청 전"
        @unknown default:
            return "확인 필요"
        }
    }

    var groupedNotifications: [AppNotificationDayGroup] {
        let calendar = Calendar(identifier: .gregorian)
        let grouped = Dictionary(grouping: notifications) { item in
            calendar.startOfDay(for: item.occurredAt)
        }

        return grouped.keys
            .sorted(by: >)
            .map { date in
                AppNotificationDayGroup(date: date, items: grouped[date] ?? [])
            }
    }

    private init(center: UNUserNotificationCenter = .current()) {
        self.center = center
        notifications = []

        Task {
            await refreshAuthorizationStatus()
        }
    }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func requestAuthorization() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await refreshAuthorizationStatus()
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            await refreshAuthorizationStatus()
        }
    }

    func updateDeviceToken(_ tokenData: Data) {
        deviceToken = tokenData.map { String(format: "%02x", $0) }.joined()
        remoteRegistrationError = nil
    }

    func updateRemoteRegistrationError(_ error: Error) {
        remoteRegistrationError = AppVocabulary.ErrorMessage.userFacing(for: error)
    }

    func markAsRead(_ item: AppNotificationItem) {
        markAsRead(notificationId: item.id)
    }

    func markAsRead(notificationId: String) {
        guard let index = notifications.firstIndex(where: { $0.id == notificationId }) else { return }
        notifications[index].isRead = true
    }

    func markAnalysisPayloadAsRead(_ payload: PolSignalAnalysisPayload) {
        notifications = notifications.map { item in
            guard item.analysisPayload == payload else { return item }
            var copy = item
            copy.isRead = true
            return copy
        }
    }

    func markAllAsRead() {
        notifications = notifications.map { item in
            var copy = item
            copy.isRead = true
            return copy
        }
    }

    func addInAppNotification(_ item: AppNotificationItem) {
        let insertionIndex = notifications.firstIndex { $0.occurredAt < item.occurredAt }
            ?? notifications.endIndex
        notifications.insert(item, at: insertionIndex)
    }

    func handlePushNotificationOpen(userInfo: [AnyHashable: Any]) {
        if let notificationId = Self.stringValue(userInfo["notificationId"]) {
            markAsRead(notificationId: notificationId)
        }

        pendingPushRoute = Self.pushRoute(from: userInfo)
    }

    func consumePendingPushRoute() -> PolSignalRoute? {
        defer { pendingPushRoute = nil }
        return pendingPushRoute
    }

    func signalRoute(for payload: PolSignalAnalysisPayload) -> PolSignalRoute {
        Self.route(forEventId: payload.eventId)
    }

    func addCompletedAnalysisNotification(payload: PolSignalAnalysisPayload, event: PolSignalEvent) {
        let ticker = event.exposures.first?.ticker ?? event.category
        let item = AppNotificationItem(
            kind: .signalAnalysis,
            title: "\(ticker) 변동 가능성 확인",
            message: "보유한 \(ticker)의 변동 가능성이 커졌어요. 이유를 확인해보세요.",
            occurredAt: Date(),
            relatedTitle: event.title,
            analysisPayload: payload,
            isRead: false
        )
        addInAppNotification(item)
    }

    func scheduleTestNotification() async {
        if authorizationStatus == .notDetermined {
            await requestAuthorization()
        }

        guard authorizationStatus == .authorized
            || authorizationStatus == .provisional
            || authorizationStatus == .ephemeral else {
            return
        }

        let item = AppNotificationItem(
            kind: .signalAnalysis,
            title: "SOXX 변동 가능성 확인",
            message: "보유한 SOXX의 변동 가능성이 커졌어요. 이유를 확인해보세요.",
            occurredAt: Date(),
            relatedTitle: "반도체",
            analysisPayload: PolSignalAnalysisPayload(
                eventId: 102,
                analysisVersion: "test-notification"
            ),
            isRead: false
        )
        addInAppNotification(item)
        await scheduleLocalNotification(for: item, delay: 3)
    }

    private func scheduleLocalNotification(for item: AppNotificationItem, delay: TimeInterval) async {
        let content = UNMutableNotificationContent()
        content.title = item.title
        content.body = item.message
        content.sound = .default
        var userInfo: [String: Any] = ["notificationId": item.id, "kind": item.kind.rawValue]
        if let payload = item.analysisPayload {
            userInfo["eventId"] = payload.eventId
            userInfo["analysisVersion"] = payload.analysisVersion
            if let theme = Self.theme(forEventId: payload.eventId) {
                userInfo["route"] = "signalThemeDetail"
                userInfo["theme"] = theme.tickerId
            }
        }
        content.userInfo = userInfo

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, delay), repeats: false)
        let request = UNNotificationRequest(identifier: item.id, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            return
        }
    }

    private static func pushRoute(from userInfo: [AnyHashable: Any]) -> PolSignalRoute? {
        if let theme = theme(from: userInfo) {
            return .themeDetail(theme)
        }

        guard let eventId = intValue(userInfo["eventId"]) else {
            return nil
        }

        if let theme = theme(forEventId: eventId) {
            return route(for: theme)
        }

        return .detail(eventId)
    }

    private static func route(forEventId eventId: Int) -> PolSignalRoute {
        if let theme = theme(forEventId: eventId) {
            return route(for: theme)
        }

        return .detail(eventId)
    }

    private static func route(for theme: PortfolioThemeSignal.Theme) -> PolSignalRoute {
        .themeDetail(theme)
    }

    private static func theme(from userInfo: [AnyHashable: Any]) -> PortfolioThemeSignal.Theme? {
        let keys = ["theme", "ticker", "symbol", "assetTicker", "routeTheme"]
        for key in keys {
            if let theme = theme(from: userInfo[key]) {
                return theme
            }
        }
        return nil
    }

    private static func theme(forEventId eventId: Int) -> PortfolioThemeSignal.Theme? {
        PolSignalFlowMockData.todayThemeSignals
            .first { $0.relatedEventId == eventId }?
            .theme
    }

    private static func theme(from value: Any?) -> PortfolioThemeSignal.Theme? {
        guard let raw = stringValue(value) else { return nil }
        let normalized = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")
            .uppercased()

        switch normalized {
        case "QQQ", "BIGTECH", "BIGTECHAI", "빅테크", "빅테크AI":
            return .bigTech
        case "SOXX", "SMH", "SEMICONDUCTOR", "SEMICONDUCTORS", "CHIP", "CHIPS", "반도체":
            return .semiconductor
        case "XLF", "FINANCIALS", "FINANCE", "금융":
            return .financials
        case "ICLN", "GREENENERGY", "CLEANENERGY", "ENERGY", "친환경":
            return .greenEnergy
        default:
            return nil
        }
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let value = value as? Int {
            return value
        }
        if let value = value as? Int64 {
            return Int(value)
        }
        if let value = value as? Double {
            return Int(value)
        }
        if let value = value as? String {
            return Int(value)
        }
        return nil
    }

    private static func stringValue(_ value: Any?) -> String? {
        if let value = value as? String {
            return value
        }
        if let value = value as? CustomStringConvertible {
            return value.description
        }
        return nil
    }
}
