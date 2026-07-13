import Foundation

nonisolated protocol RegistrationRepositoryProtocol: Sendable {
    func register(email: String, nickname: String, password: String) async throws -> AuthAccountProfile
}
