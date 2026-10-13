import Foundation

/// 탭이 사라져도 진행 중인 읽기 요청은 유지하고, 돌아온 화면이 같은 요청에 합류한다.
/// 완료된 결과를 캐시하지 않아 명시적인 새로고침은 항상 새 데이터를 요청한다.
@MainActor
final class SharedTodayRepository: TodayRepositoryProtocol {
    private struct Context: Equatable {
        let userId: Int64?
        let profile: UserAssetProfile
        let portfolio: PortfolioSnapshot
    }

    private struct Flight {
        let id: UUID
        let context: Context
        let task: Task<TodayDashboard, Error>
    }

    private let repository: TodayRepositoryProtocol
    private var flight: Flight?
    private var listeners: [UUID: @MainActor @Sendable (TodaySectionUpdate) -> Void] = [:]

    init(repository: TodayRepositoryProtocol) {
        self.repository = repository
    }

    func fetchDashboard(
        userId: Int64?, userAssetProfile: UserAssetProfile, portfolioSnapshot: PortfolioSnapshot,
        onSection: (@MainActor @Sendable (TodaySectionUpdate) -> Void)?
    ) async throws -> TodayDashboard {
        try Task.checkCancellation()
        let context = Context(userId: userId, profile: userAssetProfile, portfolio: portfolioSnapshot)
        let current: Flight
        if let flight, flight.context == context {
            current = flight
        } else {
            flight?.task.cancel()
            listeners.removeAll()
            let id = UUID()
            let task = Task {
                defer {
                    if self.flight?.id == id { self.flight = nil }
                }
                return try await repository.fetchDashboard(
                    userId: userId, userAssetProfile: userAssetProfile, portfolioSnapshot: portfolioSnapshot,
                    onSection: { update in
                        guard self.flight?.id == id else { return }
                        for listener in self.listeners.values { listener(update) }
                    }
                )
            }
            current = Flight(id: id, context: context, task: task)
            flight = current
        }
        let listenerID = UUID()
        listeners[listenerID] = onSection
        defer { listeners[listenerID] = nil }
        return try await AsyncTaskWait.value(of: current.task)
    }

    func invalidateNews() async {
        await repository.invalidateNews()
    }

    func newsUpdates() async -> AsyncStream<[TodayNewsItem]> {
        await repository.newsUpdates()
    }
}
