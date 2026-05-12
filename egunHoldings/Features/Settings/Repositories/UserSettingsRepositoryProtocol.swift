protocol UserSettingsRepositoryProtocol: Sendable {
    func fetchSettings(userId: Int64?, connectedBrokerText: String) async throws -> UserSettings
    func updateSettings(userId: Int64?, settings: UserSettings) async throws -> UserSettings
}
