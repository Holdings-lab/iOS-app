import Foundation

nonisolated protocol EmailVerificationRepositoryProtocol {
    func requestVerificationCode(for email: String) async throws
    func verifyCode(_ code: String, for email: String) async throws
}

nonisolated enum EmailVerificationRepositoryError: LocalizedError {
    case invalidEmail
    case invalidCode

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "올바른 이메일 주소를 입력해 주세요."
        case .invalidCode:
            return "인증번호가 올바르지 않아요."
        }
    }
}
