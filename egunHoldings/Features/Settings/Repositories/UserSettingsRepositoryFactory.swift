enum UserSettingsRepositoryFactory {
    static func makeDefault() -> UserSettingsRepositoryProtocol {
        LiveUserSettingsRepository()
    }
}
