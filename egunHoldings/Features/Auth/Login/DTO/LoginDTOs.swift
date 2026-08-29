import Foundation

nonisolated struct LoginRequestDTO: Encodable, Sendable {
    let email: String
    let password: String
}

nonisolated struct LoginResponseDTO: Decodable, Sendable {
    let userId: Int64
    let email: String?
    let nickname: String?
    let accessToken: String
    let refreshToken: String?
    /// 액세스 토큰 만료까지 남은 초 (서버 `AuthDto.LoginResult.accessTokenExpiresIn`).
    /// 서버 API LIST의 로그인 응답 스펙에는 없는 필드라 옵셔널로 둔다 — 자세한 배경은
    /// `AuthTokenDefaults.assumedAccessTokenLifetime` 주석 참고.
    let accessTokenExpiresIn: Int64?
    let onboardingCompleted: Bool

    func toDomain(fallbackEmail: String) -> LoginSession {
        LoginSession(
            userId: userId,
            email: email ?? fallbackEmail,
            nickname: nickname ?? Self.defaultNickname(from: email ?? fallbackEmail),
            accessToken: accessToken,
            refreshToken: refreshToken,
            accessTokenExpiresIn: accessTokenExpiresIn ?? AuthTokenDefaults.assumedAccessTokenLifetime,
            onboardingCompleted: onboardingCompleted
        )
    }

    private static func defaultNickname(from email: String) -> String {
        let localPart = email.split(separator: "@").first.map(String.init) ?? ""
        return localPart.isEmpty ? "투자자" : localPart
    }
}

nonisolated struct LoginOAuthRequestDTO: Encodable, Sendable {
    let provider: String
    let authorizationCode: String
    let redirectUri: String
}

nonisolated struct LogoutRequestDTO: Encodable, Sendable {
    let refreshToken: String
}

nonisolated struct LoginOAuthResponseDTO: Decodable, Sendable {
    let userId: Int64
    let email: String?
    let nickname: String?
    let accessToken: String
    let refreshToken: String?
    let onboardingCompleted: Bool
    let newUser: Bool

    func toDomain() -> LoginOAuthSession {
        LoginOAuthSession(
            userId: userId,
            email: email ?? "",
            nickname: nickname ?? "투자자",
            accessToken: accessToken,
            refreshToken: refreshToken,
            onboardingCompleted: onboardingCompleted,
            newUser: newUser
        )
    }
}
