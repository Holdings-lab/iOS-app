import Combine
import Foundation

enum SignupRoute: Hashable {
    case terms
    case emailVerification
    case passwordSetup
    case complete
}

enum SignupEmailDomainOption: String, CaseIterable, Identifiable {
    case naver = "naver.com"
    case gmail = "gmail.com"
    case daum = "daum.net"
    case hanmail = "hanmail.net"
    case direct = "직접 입력"

    var id: String { rawValue }

    var title: String {
        rawValue
    }
}

@MainActor
final class SignUpFlowViewModel: ObservableObject {
    @Published var path: [SignupRoute] = []
    @Published private(set) var selectedConsentIDs: Set<String> = []
    @Published private(set) var emailLocalPart: String = ""
    @Published private(set) var selectedDomain: SignupEmailDomainOption = .naver
    @Published private(set) var customDomain: String = ""
    @Published private(set) var otpCode: String = ""
    @Published private(set) var hasSentCode = false
    @Published private(set) var isEmailVerified = false
    @Published private(set) var secondsRemaining = 180
    @Published private(set) var emailFeedbackMessage: String?
    @Published private(set) var emailFeedbackTone: InlineFeedbackTone?
    @Published private(set) var otpShakeTrigger = 0
    @Published private(set) var password: String = ""
    @Published private(set) var confirmPassword: String = ""

    let verificationTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let consentDefinitions: [SignupConsentDefinition]
    let availableDomains = SignupEmailDomainOption.allCases

    private let verificationRepository: EmailVerificationRepositoryProtocol

    init(verificationRepository: EmailVerificationRepositoryProtocol? = nil) {
        self.verificationRepository = verificationRepository ?? LiveAuthRepository()
        consentDefinitions = [
            SignupConsentDefinition(
                id: "service",
                title: "서비스 이용약관",
                summary: "서비스 이용 기준과 책임 범위를 확인해요.",
                isRequired: true,
                detailBody: "서비스 이용 조건, 계정 보안, 이용 제한과 해지 기준을 안내합니다."
            ),
            SignupConsentDefinition(
                id: "privacy",
                title: "개인정보 수집 및 이용",
                summary: "맞춤 해석 제공에 필요한 정보 활용 범위를 안내해요.",
                isRequired: true,
                detailBody: "로그인, 인증, 서비스 개선을 위해 필요한 최소 정보의 수집 목적과 이용 범위를 설명합니다."
            ),
            SignupConsentDefinition(
                id: "ai",
                title: "AI 분석 서비스 이용약관",
                summary: "AI 해석 결과의 참고 범위와 유의사항을 설명해요.",
                isRequired: true,
                detailBody: "AI 해석 정보는 투자 판단을 돕기 위한 참고 자료이며, 확정적 예측이나 수익 보장을 의미하지 않습니다."
            ),
            SignupConsentDefinition(
                id: "ai_data_transfer",
                title: "AI 응답 생성을 위한 데이터 처리 동의",
                summary: "포트폴리오 분석 시 익명화된 자산 정보가 외부 AI 서비스에 전송돼요.",
                isRequired: true,
                detailBody: """
                포트폴리오 동반자 기능 이용 시, 아래 정보가 외부 AI API 서버에
                익명화되어 전송됩니다.

                전송되는 정보
                • 보유 자산 종목 및 비중 (%)
                • 보유 기간 및 수익률
                • 투자 성향 및 목표 기간

                전송되지 않는 정보
                • 실명, 생년월일 등 개인 식별 정보
                • 정확한 자산 평가액
                • 계좌번호 및 금융기관 정보

                외부 AI 서비스는 해당 데이터를 모델 학습에 사용하지 않습니다.
                """
            ),
            SignupConsentDefinition(
                id: "age",
                title: "만 14세 이상 확인",
                summary: "서비스 이용 가능 연령 기준을 확인해요.",
                isRequired: true,
                detailBody: "본 서비스는 만 14세 이상 사용자를 대상으로 제공됩니다."
            ),
            SignupConsentDefinition(
                id: "marketing",
                title: "혜택 및 이벤트 알림 수신",
                summary: "새로운 기능과 혜택 소식을 받아볼 수 있어요.",
                isRequired: false,
                detailBody: "선택 항목이며, 업데이트와 이벤트 안내를 이메일로 받아볼 수 있습니다."
            )
        ]
    }

    var hasAgreedRequiredTerms: Bool {
        consentDefinitions.filter(\.isRequired).allSatisfy { selectedConsentIDs.contains($0.id) }
    }

    var emailAddress: String {
        let local = emailLocalPart.trimmingCharacters(in: .whitespacesAndNewlines)
        let domainValue = selectedDomain == .direct ? customDomain : selectedDomain.rawValue
        let domain = domainValue.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !local.isEmpty, !domain.isEmpty else {
            return ""
        }

        return "\(local)@\(domain)"
    }

    var canSendVerificationCode: Bool {
        let local = emailLocalPart.trimmingCharacters(in: .whitespacesAndNewlines)
        let domainValue = selectedDomain == .direct ? customDomain : selectedDomain.rawValue
        let domain = domainValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return !local.isEmpty && domain.contains(".")
    }

    func startSignup() {
        path = [.terms]
    }

    func navigateBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func moveToEmailVerification() {
        path.append(.emailVerification)
    }

    func moveToPasswordSetup() {
        path.append(.passwordSetup)
    }

    func moveToComplete() {
        path.append(.complete)
    }

    func toggleConsent(id: String) {
        if selectedConsentIDs.contains(id) {
            selectedConsentIDs.remove(id)
        } else {
            selectedConsentIDs.insert(id)
        }
    }

    func toggleAllConsents() {
        if consentDefinitions.allSatisfy({ selectedConsentIDs.contains($0.id) }) {
            selectedConsentIDs.removeAll()
        } else {
            selectedConsentIDs = Set(consentDefinitions.map(\.id))
        }
    }

    func updateEmailLocalPart(_ newValue: String) {
        let sanitized = newValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")

        guard emailLocalPart != sanitized else { return }
        emailLocalPart = sanitized
        resetEmailVerificationStateIfNeeded()
    }

    func updateSelectedDomain(_ newValue: SignupEmailDomainOption) {
        guard selectedDomain != newValue else { return }
        selectedDomain = newValue
        resetEmailVerificationStateIfNeeded()
    }

    func updateCustomDomain(_ newValue: String) {
        let sanitized = newValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")

        guard customDomain != sanitized else { return }
        customDomain = sanitized
        resetEmailVerificationStateIfNeeded()
    }

    func updateOTP(_ newValue: String) {
        otpCode = String(newValue.filter(\.isNumber).prefix(6))
    }

    func updatePassword(_ newValue: String) {
        password = newValue
    }

    func updateConfirmPassword(_ newValue: String) {
        confirmPassword = newValue
    }

    func sendVerificationCode() {
        guard canSendVerificationCode else { return }

        let email = emailAddress

        Task {
            do {
                try await verificationRepository.requestVerificationCode(for: email)
                hasSentCode = true
                isEmailVerified = false
                otpCode = ""
                secondsRemaining = 180
                emailFeedbackMessage = nil
                emailFeedbackTone = nil
            } catch {
                emailFeedbackMessage = Self.makeErrorMessage(
                    for: error,
                    fallback: "인증번호를 보내지 못했어요. 잠시 후 다시 시도해주세요."
                )
                emailFeedbackTone = .error
            }
        }
    }

    func resendVerificationCode() {
        sendVerificationCode()

        if hasSentCode {
            emailFeedbackMessage = "인증번호를 다시 보냈어요."
            emailFeedbackTone = .neutral
        }
    }

    func attemptVerification(with enteredCode: String) {
        guard hasSentCode else { return }

        guard secondsRemaining > 0 else {
            otpShakeTrigger += 1
            otpCode = ""
            emailFeedbackMessage = "인증 시간이 만료됐어요. 다시 요청해 주세요."
            emailFeedbackTone = .error
            return
        }

        let email = emailAddress

        Task {
            do {
                try await verificationRepository.verifyCode(enteredCode, for: email)
                isEmailVerified = true
                emailFeedbackMessage = "인증이 완료됐어요."
                emailFeedbackTone = .success
            } catch {
                otpShakeTrigger += 1
                otpCode = ""
                emailFeedbackMessage = Self.makeErrorMessage(
                    for: error,
                    fallback: "인증번호가 올바르지 않아요."
                )
                emailFeedbackTone = .error
            }
        }
    }

    func tickVerificationTimer() {
        guard hasSentCode, !isEmailVerified, secondsRemaining > 0 else { return }
        secondsRemaining -= 1

        if secondsRemaining == 0 {
            emailFeedbackMessage = "인증 시간이 만료됐어요. 다시 요청해 주세요."
            emailFeedbackTone = .error
        }
    }

    func resetEmailVerification() {
        resetEmailVerificationState()
    }

    func finishSignup(
        using action: (_ name: String, _ email: String, _ password: String, _ confirmPassword: String, _ agreed: Bool) async -> Bool
    ) async -> Bool {
        let derivedName = emailLocalPart
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        let safeName = derivedName.isEmpty ? "투자자" : derivedName

        return await action(
            safeName,
            emailAddress,
            password,
            confirmPassword,
            hasAgreedRequiredTerms
        )
    }

    private func resetEmailVerificationStateIfNeeded() {
        if hasSentCode || isEmailVerified || !otpCode.isEmpty || emailFeedbackMessage != nil {
            resetEmailVerificationState()
        }
    }

    private func resetEmailVerificationState() {
        hasSentCode = false
        isEmailVerified = false
        otpCode = ""
        secondsRemaining = 180
        emailFeedbackMessage = nil
        emailFeedbackTone = nil
    }

    private static func makeErrorMessage(for error: Error, fallback: String) -> String {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .apiFailure, .httpStatus:
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
}
