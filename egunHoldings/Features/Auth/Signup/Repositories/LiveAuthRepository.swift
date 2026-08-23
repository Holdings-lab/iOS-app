import Foundation

nonisolated private struct EmailRequestDTO: Encodable {
    let email: String
}

nonisolated private struct EmailVerifyRequestDTO: Encodable {
    let email: String
    let verificationCode: String
}

nonisolated private struct AuthRegisterRequestDTO: Encodable {
    let email: String
    let nickname: String
    let password: String
}

nonisolated private struct FCMTokenRequestDTO: Encodable {
    let userId: Int64
    let fcmToken: String
}

nonisolated private struct NicknameRequestDTO: Encodable {
    let nickname: String
}

nonisolated private struct ChangePasswordRequestDTO: Encodable {
    let currentPassword: String
    let newPassword: String
}

nonisolated private struct AuthAccountResponseDTO: Decodable {
    let userId: Int64
    let email: String
    let nickname: String

    func toDomain() -> AuthAccountProfile {
        AuthAccountProfile(
            userId: userId,
            email: email,
            nickname: nickname
        )
    }
}

nonisolated struct LiveAuthRepository: RegistrationRepositoryProtocol, AccountManagementRepositoryProtocol, EmailVerificationRepositoryProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClientFactory.makeDefault()) {
        self.apiClient = apiClient
    }

    func requestVerificationCode(for email: String) async throws {
        let body = try NetworkJSONCoding.encodeJSON(EmailRequestDTO(email: email))
        _ = try await apiClient.requestResult(
            BackendEndpoint.emailSendCode(body: body),
            as: EmptyAPIResult.self
        )
    }

    func verifyCode(_ code: String, for email: String) async throws {
        let body = try NetworkJSONCoding.encodeJSON(
            EmailVerifyRequestDTO(email: email, verificationCode: code)
        )
        _ = try await apiClient.requestResult(
            BackendEndpoint.emailVerifyCode(body: body),
            as: EmptyAPIResult.self
        )
    }

    func register(email: String, nickname: String, password: String) async throws -> AuthAccountProfile {
        let body = try NetworkJSONCoding.encodeJSON(
            AuthRegisterRequestDTO(email: email, nickname: nickname, password: password)
        )
        let response = try await apiClient.requestResult(
            BackendEndpoint.register(body: body),
            as: AuthAccountResponseDTO.self
        )
        return response.toDomain()
    }

    func fetchAccounts() async throws -> [AuthAccountProfile] {
        let response = try await apiClient.requestResult(
            BackendEndpoint.accounts(),
            as: [AuthAccountResponseDTO].self
        )
        return response.map { $0.toDomain() }
    }

    func deleteAccount(userId: Int64) async throws -> AuthAccountProfile {
        let response = try await apiClient.requestResult(
            BackendEndpoint.deleteAccount(),
            as: AuthAccountResponseDTO.self
        )
        return response.toDomain()
    }

    func registerFCMToken(userId: Int64, fcmToken: String) async throws -> AuthAccountProfile {
        let body = try NetworkJSONCoding.encodeJSON(
            FCMTokenRequestDTO(userId: userId, fcmToken: fcmToken)
        )
        let response = try await apiClient.requestResult(
            BackendEndpoint.registerFCMToken(body: body),
            as: AuthAccountResponseDTO.self
        )
        return response.toDomain()
    }

    func updateNickname(userId: Int64, nickname: String) async throws -> AuthAccountProfile {
        let body = try NetworkJSONCoding.encodeJSON(NicknameRequestDTO(nickname: nickname))
        let response = try await apiClient.requestResult(
            BackendEndpoint.updateNickname(body: body),
            as: AuthAccountResponseDTO.self
        )
        return response.toDomain()
    }

    func changePassword(userId: Int64, currentPassword: String, newPassword: String) async throws -> AuthAccountProfile {
        let body = try NetworkJSONCoding.encodeJSON(
            ChangePasswordRequestDTO(
                currentPassword: currentPassword,
                newPassword: newPassword
            )
        )
        let response = try await apiClient.requestResult(
            BackendEndpoint.changePassword(body: body),
            as: AuthAccountResponseDTO.self
        )
        return response.toDomain()
    }
}
