import Foundation

nonisolated struct SettingsHomeResponseDTO: Decodable, Sendable {
    let user: User
    let notifications: Notifications
    let investment: Investment

    struct User: Decodable, Sendable {
        let nickname: String
        let email: String
        let avatarText: String
    }

    struct Notifications: Decodable, Sendable {
        let policyChangeAlert: Bool
        let briefingTime: String
    }

    struct Investment: Decodable, Sendable {
        let goal: Goal?
        let connectedAccounts: ConnectedAccounts
        let interests: Interests
    }

    struct Goal: Decodable, Sendable {
        let code: String
        let label: String
    }

    struct ConnectedAccounts: Decodable, Sendable {
        let count: Int
        let expiredCount: Int
    }

    struct Interests: Decodable, Sendable {
        let count: Int
    }
}

nonisolated struct UpdateNotificationSettingsRequestDTO: Encodable, Sendable {
    let policyChangeAlert: Bool?
    let briefingTime: String?
}

nonisolated struct NotificationSettingsResponseDTO: Decodable, Sendable {
    let policyChangeAlert: Bool
    let briefingTime: String
}

nonisolated struct TestNotificationResponseDTO: Decodable, Sendable {
    let status: String
    let message: String
}
