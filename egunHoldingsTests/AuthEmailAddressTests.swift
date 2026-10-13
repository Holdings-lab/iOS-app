import Foundation
import Testing
@testable import egunHoldings

@MainActor
struct AuthEmailAddressTests {
    @Test("잘못된 이메일은 로그인 서버에 전송하지 않는다", arguments: [
        "a@@example.com", "a@.com", "a@example.", "a b@example.com", "@example.com"
    ])
    func invalidEmailDoesNotReachRepository(email: String) async {
        let repository = LoginEmailRecordingRepository()
        let model = LoginViewModel(loginRepository: repository)
        model.email = email
        model.password = "password"
        #expect(await model.submitLogin() == nil)
        #expect(model.errorMessage != nil)
        #expect(await repository.emails.isEmpty)
    }

    @Test("로그인과 로컬 계정 조회가 같은 이메일을 사용한다")
    func normalizedEmailMatchesStoredAccount() async throws {
        let repository = LoginEmailRecordingRepository()
        let model = LoginViewModel(loginRepository: repository)
        model.email = " Tester@Example.COM \n"
        model.password = "password"
        let session = try #require(await model.submitLogin())
        #expect(session.email == "tester@example.com")
        #expect(await repository.emails == ["tester@example.com"])
        #expect(!model.isLoading)
        #expect(model.errorMessage == nil)
    }
}

private actor LoginEmailRecordingRepository: LoginRepositoryProtocol {
    private(set) var emails: [String] = []

    func login(email: String, password: String) async throws -> LoginSession {
        emails.append(email)
        return LoginSession(userId: 1, email: email, nickname: "tester",
                            accessToken: "test", refreshToken: nil,
                            accessTokenExpiresIn: 3600, onboardingCompleted: false)
    }

    func oauthLogin(provider: String, authorizationCode: String, redirectURI: String) async throws -> LoginOAuthSession {
        throw NetworkError.invalidResponse
    }

    func logout(refreshToken: String) async throws {}
}
