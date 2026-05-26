import Foundation

nonisolated enum SignalRepositoryFactory {
    static func makeDefault() -> SignalRepositoryProtocol {
        MockSignalRepository()
    }
}
