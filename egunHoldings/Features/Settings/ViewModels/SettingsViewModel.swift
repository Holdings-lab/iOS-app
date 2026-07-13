import Combine
import Foundation
import UserNotifications

@MainActor
final class SettingsViewModel: ObservableObject {
    // 프로필
    @Published private(set) var displayName = "홍길동"
    @Published private(set) var email = "hong@example.com"

    // 투자 설정
    @Published var investmentHorizon: InvestmentHorizon = .threeToFiveYears
    @Published var maxDrawdownTolerance: MaxDrawdownTolerance = .withinTen
    @Published var investmentProfile: InvestmentProfile = .balanced
    @Published var financialGoal: FinancialGoal = .retirement
    @Published var targetAmount: Int64 = FinancialGoal.retirement.settingsPreset.amount
    @Published var selectedWatchSectors: Set<WatchAssetSector> = SettingsMockData.initialWatchSectors
    @Published var selectedPolicyCategoryIDs: Set<String> = SettingsMockData.initialPolicyCategoryIDs

    // 연결된 계좌
    @Published private(set) var accounts: [ConnectedAccount] = SettingsMockData.initialAccounts
    @Published private(set) var busyAccountKey: String?

    // 알림 (푸시 권한/테스트는 실제 로컬 알림 API를 사용 — 네트워크 아님)
    @Published var notificationPreferences = NotificationPreferences()
    private let notificationCenter: AppNotificationCenter
    @Published private(set) var isRequestingPushAuthorization = false
    @Published private(set) var isSendingTestNotification = false

    // 앱 설정
    @Published var appPreferences = AppPreferences()

    // 토스트
    @Published private(set) var toast: String?
    private var toastTask: Task<Void, Never>?

    init(notificationCenter: AppNotificationCenter) {
        self.notificationCenter = notificationCenter
    }

    // MARK: - 파생 텍스트 (루트 화면 row 서브텍스트)

    var connectedCount: Int {
        accounts.count
    }

    var issueCount: Int {
        accounts.filter { $0.status != .ok }.count
    }

    var connectedBrokerNames: String {
        accounts.map { SettingsMockData.brokerByID[$0.brokerId]?.name ?? $0.brokerId }.joined(separator: ", ")
    }

    var investProfileSummary: String {
        "\(investmentHorizon.title) · -\(maxDrawdownTolerance.percentValue)% 허용 · \(investmentProfile.title)"
    }

    var goalSummary: String {
        "\(financialGoal.title) · \(OnboardingCurrencyFormatter.wonText(targetAmount))"
    }

    var watchSectorSummary: String {
        guard !selectedWatchSectors.isEmpty else { return "아직 선택하지 않았어요" }
        return selectedWatchSectors.map(\.title).joined(separator: ", ")
    }

    var policyCategorySummary: String {
        guard !selectedPolicyCategoryIDs.isEmpty else { return "아직 선택하지 않았어요" }
        return "\(selectedPolicyCategoryIDs.count)개 선택됨"
    }

    var isPushAuthorized: Bool {
        switch notificationCenter.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    var pushPermissionText: String {
        isPushAuthorized ? "권한이 허용되어 있어요" : "권한이 꺼져 있어요"
    }

    // MARK: - 토스트

    func notify(_ message: String) {
        toastTask?.cancel()
        toast = message
        toastTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            guard !Task.isCancelled else { return }
            self?.toast = nil
        }
    }

    // MARK: - 투자 설정 저장

    func saveInvestProfile(horizon: InvestmentHorizon, tolerance: MaxDrawdownTolerance, profile: InvestmentProfile) {
        investmentHorizon = horizon
        maxDrawdownTolerance = tolerance
        investmentProfile = profile
        notify("투자 프로필을 저장했어요")
    }

    func saveGoal(goal: FinancialGoal, amount: Int64) {
        financialGoal = goal
        targetAmount = amount
        notify("목표를 저장했어요")
    }

    func saveWatchSectors(_ sectors: Set<WatchAssetSector>) {
        selectedWatchSectors = sectors
        notify("관심 분야를 저장했어요")
    }

    func savePolicyCategories(_ ids: Set<String>) {
        selectedPolicyCategoryIDs = ids
        notify("관심 정책 카테고리를 저장했어요")
    }

    // MARK: - 연결된 계좌

    var availableBrokers: [BrokerMeta] {
        let connectedIDs = Set(accounts.map(\.brokerId))
        return SettingsMockData.brokers.filter { !connectedIDs.contains($0.id) }
    }

    func reauthenticate(brokerId: String) async {
        busyAccountKey = brokerId
        try? await Task.sleep(nanoseconds: 1_100_000_000)
        if let index = accounts.firstIndex(where: { $0.brokerId == brokerId }) {
            accounts[index].status = .ok
            accounts[index].lastSync = "방금 전"
        }
        busyAccountKey = nil
        notify("다시 연결했어요")
    }

    func addBroker(id: String) async {
        busyAccountKey = "add-\(id)"
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        accounts.append(ConnectedAccount(brokerId: id, status: .ok, lastSync: "방금 전"))
        busyAccountKey = nil
        notify("증권사를 연결했어요")
    }

    func removeBroker(id: String) {
        accounts.removeAll { $0.brokerId == id }
        notify("연결을 해제했어요")
    }

    // MARK: - 알림 / 앱 설정

    func requestPushAuthorization() {
        guard !isRequestingPushAuthorization else { return }
        isRequestingPushAuthorization = true
        Task {
            await notificationCenter.requestAuthorization()
            isRequestingPushAuthorization = false
        }
    }

    func sendTestNotification() {
        guard !isSendingTestNotification else { return }
        isSendingTestNotification = true
        Task {
            await notificationCenter.scheduleTestNotification()
            isSendingTestNotification = false
            notify("테스트 알림을 보냈어요")
        }
    }

    func notifyComingSoon() {
        notify("다음 업데이트에 추가될 예정이에요")
    }

    func notifyDocumentPending() {
        notify("문서 준비 중이에요")
    }
}
