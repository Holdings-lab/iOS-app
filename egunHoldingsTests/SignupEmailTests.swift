import Foundation
import Testing
@testable import egunHoldings

@MainActor
struct SignupEmailTests {
    @Test("직접 입력은 기존 아이디와 무관하게 전체 주소로 전송한다")
    func sendsFullAddressInsteadOfOriginalLocalPart() async throws {
        let repository = SignupEmailRecordingRepository()
        let model = SignUpFlowViewModel(repository: repository)
        model.updateEmailLocalPart("original")
        model.updateSelectedDomain(.direct)
        #expect(!model.canSendVerificationCode)
        model.updateCustomEmailAddress(" tester@example.com ")
        #expect(model.emailAddress == "tester@example.com")
        #expect(model.canSendVerificationCode)
        model.sendVerificationCode()

        let deadline = ContinuousClock.now.advanced(by: .seconds(2))
        while !model.hasSentCode && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(model.hasSentCode)
        #expect(await repository.requestedEmails == ["tester@example.com"])

        model.updateCustomEmailAddress("invalid")
        #expect(!model.hasSentCode)
        #expect(!model.canSendVerificationCode)
        model.updateSelectedDomain(.naver)
        #expect(model.emailAddress == "original@naver.com")
        #expect(model.canSendVerificationCode)
    }

    @Test("직접 입력에서는 이메일 형식이 갖춰져야 전송할 수 있다",
          arguments: ["", "tester", "tester@", "@example.com", "tester@example..com", "tester@@example.com", "test er@example.com"])
    func rejectsIncompleteAddress(_ email: String) {
        let model = SignUpFlowViewModel(repository: SignupEmailRecordingRepository())
        model.updateSelectedDomain(.direct)
        model.updateCustomEmailAddress(email)
        #expect(!model.canSendVerificationCode)
    }
}

private actor SignupEmailRecordingRepository: RegistrationRepositoryProtocol, EmailVerificationRepositoryProtocol {
    private(set) var requestedEmails: [String] = []
    func requestVerificationCode(for email: String) async throws { requestedEmails.append(email) }
    func verifyCode(_ code: String, for email: String) async throws { throw URLError(.unsupportedURL) }
    func register(email: String, nickname: String, password: String) async throws -> AuthAccountProfile {
        throw URLError(.unsupportedURL)
    }
}
