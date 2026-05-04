import Foundation

nonisolated enum PolicyNewsRepositoryFactory {
    static func makeDefault() -> PolicyNewsRepositoryProtocol {
        LivePolicyNewsRepository()
    }
}
