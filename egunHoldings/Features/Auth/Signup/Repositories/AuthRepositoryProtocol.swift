import Foundation

nonisolated struct AuthAccountProfile: Equatable, Sendable {
    let userId: Int64
    let email: String
    let nickname: String
}

nonisolated struct AuthLoginSession: Equatable, Sendable {
    let userId: Int64
    let email: String
    let nickname: String
    let accessToken: String
    let refreshToken: String?
    let onboardingCompleted: Bool
}

nonisolated struct OAuthLoginSession: Equatable, Sendable {
    let userId: Int64
    let email: String
    let nickname: String
    let accessToken: String
    let refreshToken: String?
    let onboardingCompleted: Bool
    let newUser: Bool
}

nonisolated protocol AuthRepositoryProtocol: Sendable {
    func requestVerificationCode(for email: String) async throws
    func verifyCode(_ code: String, for email: String) async throws
    func register(email: String, nickname: String, password: String) async throws -> AuthAccountProfile
    func login(email: String, password: String) async throws -> AuthLoginSession
    func oauthLogin(provider: String, authorizationCode: String, redirectUri: String) async throws -> OAuthLoginSession
    func fetchAccounts() async throws -> [AuthAccountProfile]
    func deleteAccount(userId: Int64) async throws -> AuthAccountProfile
    func registerFCMToken(userId: Int64, fcmToken: String) async throws -> AuthAccountProfile
    func updateNickname(userId: Int64, nickname: String) async throws -> AuthAccountProfile
    func changePassword(userId: Int64, currentPassword: String, newPassword: String) async throws -> AuthAccountProfile
}
