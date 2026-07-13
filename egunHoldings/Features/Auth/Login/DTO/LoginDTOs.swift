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
    let onboardingCompleted: Bool

    func toDomain(fallbackEmail: String) -> LoginSession {
        LoginSession(
            userId: userId,
            email: email ?? fallbackEmail,
            nickname: nickname ?? Self.defaultNickname(from: email ?? fallbackEmail),
            accessToken: accessToken,
            refreshToken: refreshToken,
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
