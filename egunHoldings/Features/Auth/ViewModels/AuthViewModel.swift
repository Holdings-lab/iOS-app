import Combine
import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var authErrorMessage: String?

    private let authRepository: AuthRepositoryProtocol
    private let accountStore: AuthAccountStoring

    init(
        authRepository: AuthRepositoryProtocol? = nil,
        accountStore: AuthAccountStoring? = nil
    ) {
        self.authRepository = authRepository ?? LiveAuthRepository()
        self.accountStore = accountStore ?? AuthAccountStore()
    }

    func login(email: String, password: String) async -> AppUserSession? {
        resetAuthError()

        let normalizedEmail = normalizedEmail(from: email)

        guard isValidEmail(normalizedEmail) else {
            authErrorMessage = "올바른 이메일 주소를 입력해주세요."
            return nil
        }
        guard password.count >= 4 else {
            authErrorMessage = "비밀번호는 4자 이상 입력해주세요."
            return nil
        }

        let existingAccount = registeredAccount(for: normalizedEmail)

        do {
            let loginSession = try await authRepository.login(email: normalizedEmail, password: password)

            return AppUserSession(
                userId: loginSession.userId,
                token: loginSession.accessToken,
                refreshToken: loginSession.refreshToken,
                expiresAt: Date().addingTimeInterval(60 * 60 * 24 * 14),
                userName: loginSession.nickname,
                email: loginSession.email,
                onboardingCompleted: loginSession.onboardingCompleted,
                onboardingResult: existingAccount?.onboardingResult,
                brokerBalanceSnapshot: existingAccount?.brokerBalanceSnapshot
            )
        } catch {
            authErrorMessage = authMessage(for: error, fallback: "로그인에 실패했습니다. 이메일과 비밀번호를 확인해주세요.")
            return nil
        }
    }

    @discardableResult
    func signUp(name: String, email: String, password: String, confirmPassword: String, agreedToTerms: Bool) async -> Bool {
        resetAuthError()

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = normalizedEmail(from: email)

        guard !trimmedName.isEmpty else {
            authErrorMessage = "닉네임을 입력해주세요."
            return false
        }
        guard isValidEmail(normalizedEmail) else {
            authErrorMessage = "올바른 이메일 주소를 입력해주세요."
            return false
        }
        guard isValidSignUpPassword(password) else {
            authErrorMessage = "비밀번호는 8~16자의 영문, 숫자, 특수문자를 포함해야 합니다."
            return false
        }
        guard password == confirmPassword else {
            authErrorMessage = "비밀번호와 비밀번호 확인이 일치하지 않습니다."
            return false
        }
        guard agreedToTerms else {
            authErrorMessage = "이용약관 및 개인정보처리방침 동의가 필요합니다."
            return false
        }

        do {
            let registeredAccount = try await authRepository.register(
                email: normalizedEmail,
                nickname: trimmedName,
                password: password
            )

            let newAccount = RegisteredAuthAccount(
                userId: registeredAccount.userId,
                userName: registeredAccount.nickname,
                email: registeredAccount.email,
                password: password,
                onboardingCompleted: false,
                onboardingResult: nil,
                brokerBalanceSnapshot: nil
            )

            upsertAccount(newAccount)
            return true
        } catch {
            authErrorMessage = authMessage(for: error, fallback: "회원가입에 실패했습니다. 입력 정보를 확인해주세요.")
            return false
        }
    }

    func login(with provider: SocialLoginProvider) {
        resetAuthError()

        // OAuth 연동 전까지는 탭 이벤트와 분기 지점만 유지한다.
        Self.debugLog("소셜 로그인 탭: provider=\(provider.rawValue)")
    }

    func resetAuthError() {
        authErrorMessage = nil
    }

    private func isValidEmail(_ email: String) -> Bool {
        email.contains("@") && email.contains(".")
    }

    private func isValidSignUpPassword(_ password: String) -> Bool {
        guard password.count >= 8, password.count <= 16 else {
            return false
        }

        let hasLetter = password.range(of: "[A-Za-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecial = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        return hasLetter && hasNumber && hasSpecial
    }

    private func normalizedEmail(from email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func registeredAccount(for email: String) -> RegisteredAuthAccount? {
        accountStore.loadAll().first { $0.normalizedEmail == normalizedEmail(from: email) }
    }

    private func upsertAccount(_ account: RegisteredAuthAccount) {
        var accounts = accountStore.loadAll()

        if let index = accounts.firstIndex(where: { $0.normalizedEmail == account.normalizedEmail }) {
            accounts[index] = account
        } else {
            accounts.append(account)
        }

        accountStore.saveAll(accounts)
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
                case "AUTH_EMAIL_DUPLICATED":
                    return "이미 가입된 이메일입니다. 로그인하거나 다른 이메일을 사용해주세요."
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
        print("[Auth] \(message)")
#endif
    }
}
