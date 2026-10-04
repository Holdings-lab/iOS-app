import Foundation

nonisolated protocol EmailVerificationRepositoryProtocol {
    func requestVerificationCode(for email: String) async throws
    func verifyCode(_ code: String, for email: String) async throws
}
