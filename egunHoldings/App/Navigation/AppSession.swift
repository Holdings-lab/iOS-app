import Foundation

enum AppRoute: Equatable {
    case loading
    case auth
    case onboarding
    case main
}

nonisolated struct AppUserSession: Codable, Sendable {
    var userId: Int64?
    var token: String
    var refreshToken: String?
    var expiresAt: Date
    let userName: String
    let email: String
    var onboardingCompleted: Bool
    var onboardingResult: OnboardingResult?
    var brokerBalanceSnapshot: BrokerBalanceSnapshot?

    var isTokenValid: Bool {
        Date() < expiresAt
    }
}
