import Foundation

nonisolated enum SignalRepositoryFactory {
    static func makeDefault(userId: Int64? = nil) -> SignalRepositoryProtocol {
        LiveSignalRepository(userId: userId)
    }
}
