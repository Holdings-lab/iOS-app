import Foundation

nonisolated struct AuthAccountProfile: Equatable, Sendable {
    let userId: Int64
    let email: String
    let nickname: String
}
