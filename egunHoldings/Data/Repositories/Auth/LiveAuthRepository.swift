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

nonisolated private struct AuthLoginRequestDTO: Encodable {
    let email: String
    let password: String
}

nonisolated private struct OAuthLoginRequestDTO: Encodable {
    let provider: String
    let authorizationCode: String
    let redirectUri: String
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

nonisolated private struct AuthLoginResponseDTO: Decodable {
    let userId: Int64
    let email: String
    let nickname: String
    let accessToken: String
    let refreshToken: String?
    let onboardingCompleted: Bool

    func toDomain() -> AuthLoginSession {
        AuthLoginSession(
            userId: userId,
            email: email,
            nickname: nickname,
            accessToken: accessToken,
            refreshToken: refreshToken,
            onboardingCompleted: onboardingCompleted
        )
    }
}

nonisolated private struct OAuthLoginResponseDTO: Decodable {
    let userId: Int64
    let email: String
    let nickname: String
    let accessToken: String
    let refreshToken: String?
    let onboardingCompleted: Bool
    let newUser: Bool

    func toDomain() -> OAuthLoginSession {
        OAuthLoginSession(
            userId: userId,
            email: email,
            nickname: nickname,
            accessToken: accessToken,
            refreshToken: refreshToken,
            onboardingCompleted: onboardingCompleted,
            newUser: newUser
        )
    }
}

nonisolated struct LiveAuthRepository: AuthRepositoryProtocol, EmailVerificationRepositoryProtocol {
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

    func login(email: String, password: String) async throws -> AuthLoginSession {
        let body = try NetworkJSONCoding.encodeJSON(
            AuthLoginRequestDTO(email: email, password: password)
        )
        let response = try await apiClient.requestResult(
            BackendEndpoint.login(body: body),
            as: AuthLoginResponseDTO.self
        )
        return response.toDomain()
    }

    func oauthLogin(provider: String, authorizationCode: String, redirectUri: String) async throws -> OAuthLoginSession {
        let body = try NetworkJSONCoding.encodeJSON(
            OAuthLoginRequestDTO(
                provider: provider,
                authorizationCode: authorizationCode,
                redirectUri: redirectUri
            )
        )
        let response = try await apiClient.requestResult(
            BackendEndpoint.oauthLogin(body: body),
            as: OAuthLoginResponseDTO.self
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
            BackendEndpoint.deleteAccount(userId: userId),
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
            BackendEndpoint.updateNickname(userId: userId, body: body),
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
            BackendEndpoint.changePassword(userId: userId, body: body),
            as: AuthAccountResponseDTO.self
        )
        return response.toDomain()
    }
}
