import Combine
import Foundation
import UserNotifications

@MainActor
final class SettingsViewModel: ObservableObject {
    // 프로필 — 네트워크 조회 전에는 화면 골격을 유지할 수 있는 값만 둔다.
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
    @Published private(set) var interestCount = SettingsMockData.initialPolicyCategoryIDs.count

    // 연결된 계좌
    @Published private(set) var accounts: [ConnectedAccount] = SettingsMockData.initialAccounts
    @Published private(set) var busyAccountKey: String?

    // 알림
    @Published private(set) var policyChangeAlert = true
    @Published private(set) var briefingTime = "09:00"
    private let notificationCenter: AppNotificationCenter
    private let repository: any SettingsRepositoryProtocol
    @Published private(set) var isLoading = false
    @Published private(set) var isRequestingPushAuthorization = false
    @Published private(set) var isSendingTestNotification = false

    // 토스트
    @Published private(set) var toast: String?
    private var toastTask: Task<Void, Never>?

    init(
        notificationCenter: AppNotificationCenter,
        repository: any SettingsRepositoryProtocol = LiveSettingsRepository()
    ) {
        self.notificationCenter = notificationCenter
        self.repository = repository
    }

    // MARK: - 파생 텍스트 (루트 화면 row 서브텍스트)

    var connectedCount: Int { accounts.count }

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
        guard interestCount > 0 else { return "아직 선택하지 않았어요" }
        return "\(interestCount)개"
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

    var briefingTimeOptions: [String] { ["08:00", "09:00", "10:00"] }

    func loadSettings() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let settings = try await repository.fetchSettings()
            displayName = settings.user.nickname
            email = settings.user.email
            policyChangeAlert = settings.notifications.policyChangeAlert
            briefingTime = settings.notifications.briefingTime
            accounts = makeAccounts(
                count: settings.investment.connectedAccounts.count,
                expiredCount: settings.investment.connectedAccounts.expiredCount
            )
            interestCount = settings.investment.interests.count
            if let goal = settings.investment.goal {
                financialGoal = FinancialGoal(rawValue: goal.code) ?? financialGoal
            }
        } catch {
            APIFallbackLog.log("GET /api/me/settings", error: error)
        }
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
        interestCount = ids.count
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

    func setPolicyChangeAlert(_ isEnabled: Bool) {
        let previous = policyChangeAlert
        policyChangeAlert = isEnabled
        Task {
            do {
                let response = try await repository.updateNotifications(
                    policyChangeAlert: isEnabled,
                    briefingTime: nil
                )
                policyChangeAlert = response.policyChangeAlert
            } catch {
                policyChangeAlert = previous
                notify("알림 설정을 저장하지 못했어요")
            }
        }
    }

    func setBriefingTime(_ time: String) {
        let previous = briefingTime
        briefingTime = time
        Task {
            do {
                let response = try await repository.updateNotifications(
                    policyChangeAlert: nil,
                    briefingTime: time
                )
                briefingTime = response.briefingTime
            } catch {
                briefingTime = previous
                notify("브리핑 시간을 저장하지 못했어요")
            }
        }
    }

    func sendTestNotification() {
        guard !isSendingTestNotification else { return }
        isSendingTestNotification = true
        Task {
            defer { isSendingTestNotification = false }
            do {
                let response = try await repository.sendTestNotification()
                notify(response.message)
            } catch {
                notify("테스트 알림을 보내지 못했어요")
            }
        }
    }

    func notifyComingSoon() {
        notify("다음 업데이트에 추가될 예정이에요")
    }

    func notifyDocumentPending() {
        notify("문서 준비 중이에요")
    }

    private func makeAccounts(count: Int, expiredCount: Int) -> [ConnectedAccount] {
        (0..<max(0, count)).map { index in
            ConnectedAccount(
                brokerId: "account-\(index)",
                status: index < expiredCount ? .reauth : .ok,
                lastSync: index < expiredCount ? nil : "연결됨"
            )
        }
    }
}
