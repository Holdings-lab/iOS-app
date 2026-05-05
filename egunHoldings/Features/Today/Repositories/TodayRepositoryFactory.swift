import Foundation

nonisolated enum TodayRepositoryFactory {
    static func makeDefault() -> TodayRepositoryProtocol {
        LiveTodayRepository()
    }
}
