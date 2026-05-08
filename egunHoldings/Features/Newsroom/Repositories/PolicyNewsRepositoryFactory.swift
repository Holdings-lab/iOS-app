import Foundation

nonisolated enum PolicyNewsRepositoryFactory {
    static func makeDefault(userId: Int64? = nil) -> PolicyNewsRepositoryProtocol {
        LivePolicyNewsRepository(userId: userId)
    }
}
