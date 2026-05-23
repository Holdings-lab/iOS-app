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

    private let center: UNUserNotificationCenter

    var hasUnreadNotifications: Bool {
        notifications.contains { !$0.isRead }
    }

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    var latestUnreadAnalysisPayload: PolSignalAnalysisPayload? {
        sortedNotifications
            .first { !$0.isRead && $0.analysisPayload != nil }?
            .analysisPayload
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
        let grouped = Dictionary(grouping: sortedNotifications) { item in
            calendar.startOfDay(for: item.occurredAt)
        }

        return grouped.keys
            .sorted(by: >)
            .map { date in
                AppNotificationDayGroup(date: date, items: grouped[date] ?? [])
            }
    }

    private var sortedNotifications: [AppNotificationItem] {
        notifications.sorted { $0.occurredAt > $1.occurredAt }
    }

    private init(center: UNUserNotificationCenter = .current()) {
        self.center = center
        notifications = Self.makeSeedNotifications()

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
        guard let index = notifications.firstIndex(where: { $0.id == item.id }) else { return }
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
        notifications.append(item)
        notifications.sort { $0.occurredAt > $1.occurredAt }
    }

    func addCompletedAnalysisNotification(payload: PolSignalAnalysisPayload, event: PolSignalEvent) {
        let item = AppNotificationItem(
            kind: .signalAnalysis,
            title: "\(event.title) 분석 완료",
            message: "\(event.exposureSummary) 보유 중인 당신, 확인해보세요.",
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
            kind: .volatility,
            title: "자산 변동성 위험 확인",
            message: "보유 자산 중 반도체 노출 종목 변동성이 평소보다 높아졌습니다.",
            occurredAt: Date(),
            relatedTitle: "SOXX, 삼성전자",
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

    private static func makeSeedNotifications(now: Date = Date()) -> [AppNotificationItem] {
        let calendar = Calendar(identifier: .gregorian)

        func date(minutesAgo: Int) -> Date {
            calendar.date(byAdding: .minute, value: -minutesAgo, to: now) ?? now
        }

        return [
            AppNotificationItem(
                id: "analysis-usd-103",
                kind: .signalAnalysis,
                title: "원/달러 1,490원 돌파 분석 완료",
                message: "달러 자산 15% 보유 중인 당신, 확인해보세요.",
                occurredAt: date(minutesAgo: 4),
                relatedTitle: "eventId 103 · analysisVersion \(PolSignalFlowMockData.latestAnalysisPayload.analysisVersion)",
                analysisPayload: PolSignalFlowMockData.latestAnalysisPayload,
                isRead: false
            ),
            AppNotificationItem(
                id: "policy-rate-cut",
                kind: .policy,
                title: "한은 기준금리 결정 업데이트",
                message: "기준금리 인하가 발표되어 채권 ETF 영향도를 다시 계산했습니다.",
                occurredAt: date(minutesAgo: 18),
                relatedTitle: "TIGER 국채3년, 달러 예금",
                isRead: false
            ),
            AppNotificationItem(
                id: "volatility-soxx",
                kind: .volatility,
                title: "반도체 ETF 변동성 확대",
                message: "SOXX와 삼성전자 관련 변동성이 높아져 보유 비중 점검이 필요합니다.",
                occurredAt: date(minutesAgo: 74),
                relatedTitle: "SOXX, 삼성전자",
                isRead: false
            ),
            AppNotificationItem(
                id: "news-chips",
                kind: .news,
                title: "미국 반도체 보조금 기사 업데이트",
                message: "보조금 2차 발표 전망 기사가 추가되어 관련 정책 브리핑이 갱신됐습니다.",
                occurredAt: date(minutesAgo: 210),
                relatedTitle: "미국 반도체 보조금 2차 발표",
                isRead: true
            ),
            AppNotificationItem(
                id: "asset-cash",
                kind: .asset,
                title: "현금 비중 변화 확인",
                message: "오늘 자산 변동으로 현금 방어 비중이 목표 범위 안에 있는지 확인했습니다.",
                occurredAt: date(minutesAgo: 1_430),
                relatedTitle: "내 총자산",
                isRead: true
            )
        ]
        .sorted { $0.occurredAt > $1.occurredAt }
    }
}
