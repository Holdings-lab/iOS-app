import Foundation

nonisolated enum SocialLoginProvider: String, CaseIterable, Hashable, Identifiable, Sendable {
    case apple
    case google
    case kakao = "kakao-talk"

    var id: String {
        rawValue
    }

    var assetName: String {
        rawValue
    }

    var displayTitle: String {
        switch self {
        case .apple:
            return "Sign With Apple"
        case .google:
            return "Sign with Google"
        case .kakao:
            return "카카오 로그인"
        }
    }

    var serverValue: String {
        switch self {
        case .apple:
            return "apple"
        case .google:
            return "google"
        case .kakao:
            return "kakao"
        }
    }
}

nonisolated struct LoginSession: Equatable, Sendable {
    let userId: Int64
    let email: String
    let nickname: String
    let accessToken: String
    let refreshToken: String?
    let onboardingCompleted: Bool
}

nonisolated struct LoginOAuthSession: Equatable, Sendable {
    let userId: Int64
    let email: String
    let nickname: String
    let accessToken: String
    let refreshToken: String?
    let onboardingCompleted: Bool
    let newUser: Bool
}
