nonisolated struct MockUserSettingsRepository: UserSettingsRepositoryProtocol {
    func fetchSettings(userId _: Int64?, connectedBrokerText: String) async throws -> UserSettings {
        UserSettings.makeDefault(connectedBrokerText: connectedBrokerText)
    }

    func updateSettings(userId _: Int64?, settings: UserSettings) async throws -> UserSettings {
        settings
    }
}
