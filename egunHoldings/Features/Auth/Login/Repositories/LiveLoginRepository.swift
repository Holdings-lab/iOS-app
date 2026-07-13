import Foundation

nonisolated final class LiveLoginRepository: LoginRepositoryProtocol, @unchecked Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClientFactory.makeDefault()) {
        self.apiClient = apiClient
    }

    func login(email: String, password: String) async throws -> LoginSession {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let body = try NetworkJSONCoding.encodeJSON(LoginRequestDTO(email: normalizedEmail, password: password))
        let response = try await apiClient.requestResult(
            BackendEndpoint.login(body: body),
            as: LoginResponseDTO.self
        )
        return response.toDomain(fallbackEmail: normalizedEmail)
    }

    func oauthLogin(provider: String, authorizationCode: String, redirectURI: String) async throws -> LoginOAuthSession {
        let body = try NetworkJSONCoding.encodeJSON(
            LoginOAuthRequestDTO(
                provider: provider,
                authorizationCode: authorizationCode,
                redirectUri: redirectURI
            )
        )
        let response = try await apiClient.requestResult(
            BackendEndpoint.oauthLogin(body: body),
            as: LoginOAuthResponseDTO.self
        )
        return response.toDomain()
    }
}
