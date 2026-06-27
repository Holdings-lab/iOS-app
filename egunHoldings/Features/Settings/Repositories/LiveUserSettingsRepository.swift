import Foundation

nonisolated struct LiveUserSettingsRepository: UserSettingsRepositoryProtocol {
    private let apiClient: APIClient
    private let fallbackRepository: MockUserSettingsRepository

    init(
        apiClient: APIClient = APIClientFactory.makeDefault(),
        fallbackRepository: MockUserSettingsRepository = MockUserSettingsRepository()
    ) {
        self.apiClient = apiClient
        self.fallbackRepository = fallbackRepository
    }

    func fetchSettings(userId: Int64?, connectedBrokerText: String) async throws -> UserSettings {
        let fallback = try await fallbackRepository.fetchSettings(
            userId: userId,
            connectedBrokerText: connectedBrokerText
        )

        guard let userId else {
            return fallback
        }

        do {
            let response = try await apiClient.requestResult(
                BackendEndpoint.meSettings(userId: userId),
                as: UserSettingsResponseDTO.self
            )
            return response.toDomain(fallback: fallback)
        } catch {
            guard Self.shouldUseFallback(for: error) else {
                throw error
            }

            return fallback
        }
    }

    func updateSettings(userId: Int64?, settings: UserSettings) async throws -> UserSettings {
        guard let userId else {
            return settings
        }

        do {
            let body = try NetworkJSONCoding.encodeJSON(
                UserSettingsUpdateRequestDTO(settings: settings)
            )
            let response = try await apiClient.requestResult(
                BackendEndpoint.updateMeSettings(userId: userId, body: body),
                as: UserSettingsResponseDTO.self
            )
            return response.toDomain(fallback: settings)
        } catch {
            guard Self.shouldUseFallback(for: error) else {
                throw error
            }

            return settings
        }
    }

    private static func shouldUseFallback(for error: Error) -> Bool {
        if error is NetworkError {
            return true
        }

        return (error as NSError).domain == NSURLErrorDomain
    }
}
