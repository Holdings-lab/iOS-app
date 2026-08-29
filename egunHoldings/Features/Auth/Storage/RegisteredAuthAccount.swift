import Foundation

nonisolated struct RegisteredAuthAccount: Codable, Sendable, Identifiable {
    var userId: Int64?
    var userName: String
    var email: String
    var onboardingCompleted: Bool
    var onboardingResult: OnboardingResult?
    var brokerBalanceSnapshot: BrokerBalanceSnapshot?

    var id: String {
        normalizedEmail
    }

    var normalizedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
