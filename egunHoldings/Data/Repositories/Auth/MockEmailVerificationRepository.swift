import Foundation

struct MockEmailVerificationRepository: EmailVerificationRepositoryProtocol {
    func requestVerificationCode(for email: String) throws {
        guard email.contains("@"), email.contains(".") else {
            throw EmailVerificationRepositoryError.invalidEmail
        }
    }

    func verifyCode(_ code: String, for email: String) throws {
        guard email.contains("@"), email.contains(".") else {
            throw EmailVerificationRepositoryError.invalidEmail
        }

        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedCode.count == 6, trimmedCode != "000000" else {
            throw EmailVerificationRepositoryError.invalidCode
        }
    }
}
