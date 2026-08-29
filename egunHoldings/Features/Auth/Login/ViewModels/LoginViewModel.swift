import Combine
import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    let socialProviders = SocialLoginProvider.allCases

    private let loginRepository: LoginRepositoryProtocol

    init(loginRepository: LoginRepositoryProtocol? = nil) {
        self.loginRepository = loginRepository ?? LiveLoginRepository()
    }

    var canSubmit: Bool {
        !isLoading
            && !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !password.isEmpty
    }

    func submitLogin() async -> LoginSession? {
        guard canSubmit else { return nil }

        resetError()

        let normalizedEmail = normalizedEmail(from: email)

        guard isValidEmail(normalizedEmail) else {
            errorMessage = "올바른 이메일 주소를 입력해주세요."
            return nil
        }
        guard password.count >= 4 else {
            errorMessage = "비밀번호는 4자 이상 입력해주세요."
            return nil
        }

        isLoading = true
        defer { isLoading = false }

        do {
            return try await loginRepository.login(email: normalizedEmail, password: password)
        } catch {
            errorMessage = authMessage(for: error, fallback: "로그인에 실패했습니다. 이메일과 비밀번호를 확인해주세요.")
            return nil
        }
    }

    func login(with provider: SocialLoginProvider) {
        resetError()

        // OAuth 연동 전까지는 탭 이벤트와 분기 지점만 유지한다.
        Self.debugLog("소셜 로그인 탭: provider=\(provider.rawValue)")
    }

    func resetError() {
        errorMessage = nil
    }

    func resetForm() {
        email = ""
        password = ""
        resetError()
    }

    private func isValidEmail(_ email: String) -> Bool {
        email.contains("@") && email.contains(".")
    }

    private func normalizedEmail(from email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func authMessage(for error: Error, fallback: String) -> String {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .apiFailure(_, let code, _):
                switch code {
                case "AUTH_USER_NOT_FOUND":
                    return "존재하지 않는 사용자입니다."
                case "AUTH_INVALID_PASSWORD":
                    return "비밀번호가 올바르지 않습니다."
                case "AUTH_EMAIL_VERIFICATION_REQUIRED", "AUTH_EMAIL_NOT_VERIFIED":
                    return "이메일 인증을 완료한 뒤 다시 시도해주세요."
                default:
                    return AppVocabulary.ErrorMessage.userFacing(for: networkError, fallback: fallback)
                }
            case .httpStatus:
                return AppVocabulary.ErrorMessage.userFacing(for: networkError, fallback: fallback)
            case .invalidURL:
                return AppVocabulary.ErrorMessage.unknown
            default:
                return AppVocabulary.ErrorMessage.userFacing(for: networkError, fallback: fallback)
            }
        }

        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }

        return fallback
    }

    private static func debugLog(_ message: String) {
#if DEBUG
        print("[Login] \(message)")
#endif
    }
}
