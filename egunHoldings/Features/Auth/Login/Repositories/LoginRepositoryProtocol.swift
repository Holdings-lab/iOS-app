import Foundation

nonisolated protocol LoginRepositoryProtocol: Sendable {
    func login(email: String, password: String) async throws -> LoginSession
    func oauthLogin(provider: String, authorizationCode: String, redirectURI: String) async throws -> LoginOAuthSession
}
