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

    var todayPreviewNotification: AppNotificationItem? {
        sortedNotifications.first { !$0.isRead && $0.kind == .news && $0.hasDetailContent }
            ?? sortedNotifications.first { !$0.isRead && $0.hasDetailContent }
            ?? sortedNotifications.first { !$0.isRead }
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

    /// 시연 기준 시각 — 2026-05-28 09:15 KST 고정.
    static let demoNow: Date = {
        var c = DateComponents()
        c.year = 2026; c.month = 5; c.day = 28; c.hour = 9; c.minute = 15
        return Calendar(identifier: .gregorian).date(from: c) ?? Date()
    }()

    private init(center: UNUserNotificationCenter = .current()) {
        self.center = center
        notifications = Self.makeSeedNotifications(now: Self.demoNow)

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
                isRead: false,
                detailBody: "한국은행 기준금리 결정 이후 채권형 ETF와 달러 예금의 금리 민감도를 다시 점검했습니다.\n\n금리 인하 발표는 단기 채권 가격과 예금 금리 재조정 속도에 영향을 줄 수 있어, 보유 중인 안전자산의 역할과 기대 수익률을 함께 확인해야 합니다.",
                sourceReferences: [
                    AppNotificationSource(
                        title: "한국은행 통화정책방향",
                        subtitle: "정책 원문 · 기준금리 결정 발표"
                    ),
                    AppNotificationSource(
                        title: "한국은행 기자간담회",
                        subtitle: "정책 배경 설명 · 채권시장 참고자료"
                    )
                ]
            ),
            // 미-이란 휴전 연장 협상 뉴스 — 5/27(수) 저녁 발생
            AppNotificationItem(
                id: "news-iran-ceasefire",
                kind: .news,
                title: "미-이란 휴전 연장 협상 타결 가능성 고조",
                message: "지정학 리스크 완화. 빅테크·반도체 섹터 5거래일 내 상승 여지.",
                occurredAt: date(minutesAgo: 90),
                relatedTitle: "빅테크 (QQQ), 반도체",
                isRead: false,
                detailBody: "미국과 이란 협상단이 현재의 휴전을 연장하는 방향으로 협의 중인 것으로 알려졌습니다.\n\n지난 2월 말 발발한 중동 분쟁이 약 90일 만에 완화 국면에 접어들면서, 글로벌 에너지 공급망 불안이 해소되고 위험자산 선호 심리가 빠르게 회복되고 있습니다.\n\nNVIDIA의 어닝 서프라이즈(5/20, 매출 $81.6B · YoY +85%)와 5/12 미중 90일 관세 휴전에 이어, 이번 지정학 리스크 완화까지 맞물리면서 빅테크·반도체 섹터에 복합 상승 요인이 형성되고 있습니다.",
                relatedSectors: ["빅테크 (QQQ)", "반도체"],
                impactBullets: [
                    "지정학 리스크 완화 → QQQ 등 빅테크 위험자산 매수 심리 개선",
                    "에너지 공급 안정 → AI 데이터센터 운영비용 압박 감소",
                    "NVIDIA 어닝 서프라이즈·미중 관세 완화와 맞물려 5거래일 내 급등 여지"
                ],
                sourceReferences: [
                    AppNotificationSource(
                        title: "미-이란 휴전 연장 협상 브리핑",
                        subtitle: "뉴스 원문 · 2026.05.28 07:45"
                    ),
                    AppNotificationSource(
                        title: "미중 90일 관세 휴전 발표",
                        subtitle: "정책 원문 · 2026.05.12"
                    ),
                    AppNotificationSource(
                        title: "NVIDIA FY2026 Q1 Results",
                        subtitle: "기업 실적 원문 · Investor Relations",
                        url: URL(string: "https://investor.nvidia.com/")
                    )
                ]
            ),
            AppNotificationItem(
                id: "volatility-soxx",
                kind: .volatility,
                title: "반도체 ETF 변동성 확대",
                message: "SOXX와 삼성전자 관련 변동성이 높아져 보유 비중 점검이 필요합니다.",
                occurredAt: date(minutesAgo: 124),
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
