import Foundation

nonisolated protocol SettingsRepositoryProtocol: Sendable {
    func fetchSettings() async throws -> SettingsHomeResponseDTO
    func updateNotifications(policyChangeAlert: Bool?, briefingTime: String?) async throws -> NotificationSettingsResponseDTO
    func sendTestNotification() async throws -> TestNotificationResponseDTO
}

nonisolated struct LiveSettingsRepository: SettingsRepositoryProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClientFactory.makeDefault()) {
        self.apiClient = apiClient
    }

    func fetchSettings() async throws -> SettingsHomeResponseDTO {
        try await apiClient.requestResult(BackendEndpoint.meSettings(), as: SettingsHomeResponseDTO.self)
    }

    func updateNotifications(
        policyChangeAlert: Bool? = nil,
        briefingTime: String? = nil
    ) async throws -> NotificationSettingsResponseDTO {
        let body = try NetworkJSONCoding.encodeJSON(
            UpdateNotificationSettingsRequestDTO(
                policyChangeAlert: policyChangeAlert,
                briefingTime: briefingTime
            )
        )
        return try await apiClient.requestResult(
            BackendEndpoint.updateNotificationSettings(body: body),
            as: NotificationSettingsResponseDTO.self
        )
    }

    func sendTestNotification() async throws -> TestNotificationResponseDTO {
        try await apiClient.requestResult(
            BackendEndpoint.sendTestNotification(),
            as: TestNotificationResponseDTO.self
        )
    }
}
