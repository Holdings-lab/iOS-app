import Combine
import Foundation

@MainActor
final class UserSettingsViewModel: ObservableObject {
    @Published private(set) var settings: UserSettings
    @Published private(set) var loadState: UserSettingsLoadState = .idle
    @Published private(set) var isSaving = false
    @Published private(set) var saveErrorMessage: String?

    private let userId: Int64?
    private let connectedBrokerText: String
    private let repository: UserSettingsRepositoryProtocol
    private var didLoad = false

    init(
        userId: Int64?,
        connectedBrokerText: String,
        repository: UserSettingsRepositoryProtocol? = nil
    ) {
        self.userId = userId
        self.connectedBrokerText = connectedBrokerText
        self.repository = repository ?? UserSettingsRepositoryFactory.makeDefault()
        settings = UserSettings.makeDefault(connectedBrokerText: connectedBrokerText)
    }

    var policyPushStatusText: String {
        settings.notifications.policyPushEnabled ? "켜짐" : "꺼짐"
    }

    var newsPushStatusText: String {
        settings.notifications.newsPushEnabled ? "켜짐" : "꺼짐"
    }

    var volatilityPushStatusText: String {
        settings.notifications.volatilityPushEnabled ? "켜짐" : "꺼짐"
    }

    var quietHoursStatusText: String {
        settings.notifications.quietHoursEnabled
            ? "\(settings.notifications.quietHoursStart)-\(settings.notifications.quietHoursEnd)"
            : "꺼짐"
    }

    var targetCashWeightText: String {
        "\(settings.rebalancing.targetCashWeight)%"
    }

    var policyImpactThresholdText: String {
        "\(settings.portfolio.policyImpactThreshold)% 이상"
    }

    func loadIfNeeded() async {
        guard !didLoad else { return }
        didLoad = true
        await refresh()
    }

    func refresh() async {
        loadState = .loading

        do {
            settings = try await repository.fetchSettings(
                userId: userId,
                connectedBrokerText: connectedBrokerText
            )
            loadState = .loaded
        } catch {
            loadState = .usingFallback(message: Self.errorMessage(for: error))
        }
    }

    func updatePolicyPushEnabled(_ value: Bool) async {
        await update { $0.notifications.policyPushEnabled = value }
    }

    func updateNewsPushEnabled(_ value: Bool) async {
        await update { $0.notifications.newsPushEnabled = value }
    }

    func updateVolatilityPushEnabled(_ value: Bool) async {
        await update { $0.notifications.volatilityPushEnabled = value }
    }

    func updateQuietHoursEnabled(_ value: Bool) async {
        await update { $0.notifications.quietHoursEnabled = value }
    }

    func updateInvestmentProfile(_ profile: InvestmentProfile) async {
        await update { $0.rebalancing.investmentProfile = profile }
    }

    func updateTargetCashWeight(_ value: Int) async {
        await update {
            $0.rebalancing.targetCashWeight = clamped(value, 0, 40)
        }
    }

    func updateRebalanceThreshold(_ value: Int) async {
        await update {
            $0.rebalancing.rebalanceThreshold = clamped(value, 1, 20)
        }
    }

    func updateMaxSingleAssetWeight(_ value: Int) async {
        await update {
            $0.rebalancing.maxSingleAssetWeight = clamped(value, 10, 60)
        }
    }

    func updateNotificationPolicyImpactThreshold(_ value: Int) async {
        await update {
            $0.notifications.policyImpactThreshold = clamped(value, 5, 80)
        }
    }

    func updatePortfolioPolicyImpactThreshold(_ value: Int) async {
        await update {
            $0.portfolio.policyImpactThreshold = clamped(value, 5, 80)
        }
    }

    func updateNewsDigestMode(_ mode: SettingsNewsDigestMode) async {
        await update { $0.notifications.newsDigestMode = mode }
    }

    func updateHighRelevanceNewsOnly(_ value: Bool) async {
        await update { $0.notifications.highRelevanceNewsOnly = value }
    }

    func updateNotificationVolatilityLevel(_ level: SettingsVolatilityLevel) async {
        await update { $0.notifications.volatilityLevel = level }
    }

    func updatePortfolioVolatilityLevel(_ level: SettingsVolatilityLevel) async {
        await update { $0.portfolio.volatilityLevel = level }
    }

    func updateDataSyncMode(_ mode: SettingsDataSyncMode) async {
        await update { $0.data.syncMode = mode }
    }

    private func update(_ mutate: (inout UserSettings) -> Void) async {
        var next = settings
        mutate(&next)
        settings = next
        await persist()
    }

    private func persist() async {
        isSaving = true
        saveErrorMessage = nil
        defer { isSaving = false }

        do {
            settings = try await repository.updateSettings(userId: userId, settings: settings)
            if case .usingFallback = loadState {
                return
            }
            loadState = .loaded
        } catch {
            saveErrorMessage = Self.errorMessage(for: error)
        }
    }

    private static func errorMessage(for error: Error) -> String {
        if let networkError = error as? NetworkError {
            return networkError.localizedDescription
        }

        return error.localizedDescription
    }
}

private func clamped(_ value: Int, _ lowerBound: Int, _ upperBound: Int) -> Int {
    min(upperBound, max(lowerBound, value))
}
