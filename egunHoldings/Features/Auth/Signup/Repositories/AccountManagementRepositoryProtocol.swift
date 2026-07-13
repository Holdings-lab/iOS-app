import Foundation

nonisolated protocol AccountManagementRepositoryProtocol: Sendable {
    func fetchAccounts() async throws -> [AuthAccountProfile]
    func deleteAccount(userId: Int64) async throws -> AuthAccountProfile
    func registerFCMToken(userId: Int64, fcmToken: String) async throws -> AuthAccountProfile
    func updateNickname(userId: Int64, nickname: String) async throws -> AuthAccountProfile
    func changePassword(userId: Int64, currentPassword: String, newPassword: String) async throws -> AuthAccountProfile
}
