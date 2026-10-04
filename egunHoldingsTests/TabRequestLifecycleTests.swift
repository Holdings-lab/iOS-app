import Foundation
import Testing
@testable import egunHoldings

@MainActor
struct TabRequestLifecycleTests {
    @Test("오늘 탭을 떠났다가 돌아오면 진행 중인 조회에 합류한다")
    func sharesTodayRequestAfterCancellation() async throws {
        let source = GatedTabTodayRepository()
        let repository = SharedTodayRepository(repository: source)
        let first = Task { try await dashboard(repository) }
        await waitUntil { source.count == 1 }
        first.cancel()
        do { _ = try await first.value; Issue.record("취소된 화면은 결과를 받지 않아야 한다") } catch {}
        let second = Task { try await dashboard(repository) }
        await Task.yield()
        source.finish()
        _ = try await second.value
        #expect(source.count == 1)
        // 완료 후 새로고침은 다시 조회한다.
        let refresh = Task { try await dashboard(repository) }
        await waitUntil { source.count == 2 }
        source.finish()
        _ = try await refresh.value
        #expect(source.count == 2)
    }

    @Test("다른 사용자나 변경된 자산으로 조회하면 이전 요청을 재사용하지 않는다")
    func separatesTodayContexts() async throws {
        let source = GatedTabTodayRepository()
        let repository = SharedTodayRepository(repository: source)
        let first = Task { try await dashboard(repository) }
        await waitUntil { source.count == 1 }
        let second = Task { try await dashboard(repository, userId: 2) }
        await waitUntil { source.count == 2 }
        source.finish()
        _ = try await second.value
        source.finish(index: 0)
        _ = try? await first.value
        #expect(source.count == 2)
    }

    @Test("자산 탭의 취소된 대기와 재방문이 중복 조회나 오류 화면을 만들지 않는다")
    func sharesAssetRequestAfterCancellation() async {
        let source = GatedTabBalanceRepository()
        let model = AssetViewModel(brokerBalanceRepository: source)
        let first = Task { await model.loadIfNeeded() }
        await waitUntil { source.count == 1 }
        first.cancel()
        #expect(await first.value == nil)
        #expect(model.loadState == .loading)
        let second = Task { await model.loadIfNeeded() }
        await Task.yield()
        source.finish(AppMockData.brokerBalanceSnapshot)
        #expect(await second.value == AppMockData.brokerBalanceSnapshot)
        #expect(source.count == 1)
        #expect(model.loadState == .loaded)
    }

    @Test("늦은 자산 응답이 더 최신 세션 잔고를 덮지 않는다")
    func ignoresSupersededAssetResponse() async {
        let source = GatedTabBalanceRepository()
        let model = AssetViewModel(brokerBalanceRepository: source)
        let request = Task { await model.reload() }
        await waitUntil { source.count == 1 }
        let latest = AppMockData.brokerBalanceSnapshot
        model.updateBrokerBalance(latest)
        let old = BrokerBalanceSnapshot(broker: "test", environment: "test", accountNumber: "",
            productCode: "", totalEvaluationAmount: 0, stockEvaluationAmount: 0, cashAmount: 0,
            totalPurchaseAmount: 0, totalProfitLossAmount: 0, holdings: [], fetchedAt: .distantPast)
        source.finish(old)
        #expect(await request.value == nil)
        #expect(model.loadState == .loaded)
        #expect(model.portfolioDisplay?.totalEvaluationText == AssetPortfolioDisplay(snapshot: latest).totalEvaluationText)
    }

    private func dashboard(_ repository: TodayRepositoryProtocol, userId: Int64 = 1) async throws -> TodayDashboard {
        try await repository.fetchDashboard(userId: userId, userAssetProfile: AppMockData.userAssetProfile,
                                            portfolioSnapshot: AppMockData.portfolioSnapshot)
    }

    private func waitUntil(_ predicate: () -> Bool) async {
        for _ in 0..<1000 {
            if predicate() { return }
            await Task.yield()
        }
        #expect(predicate())
    }
}

@MainActor
private final class GatedTabTodayRepository: TodayRepositoryProtocol {
    private(set) var count = 0
    private var gates: [CheckedContinuation<TodayDashboard, Never>?] = []
    func fetchDashboard(userId: Int64?, userAssetProfile: UserAssetProfile, portfolioSnapshot: PortfolioSnapshot,
                        onSection: (@MainActor @Sendable (TodaySectionUpdate) -> Void)?) async throws -> TodayDashboard {
        count += 1
        return await withCheckedContinuation { gates.append($0) }
    }
    func finish(index: Int? = nil) {
        let index = index ?? gates.count - 1
        gates[index]?.resume(returning: MockTodayRepository.makeDashboard(
            userAssetProfile: AppMockData.userAssetProfile, portfolioSnapshot: AppMockData.portfolioSnapshot))
        gates[index] = nil
    }
}

@MainActor
private final class GatedTabBalanceRepository: BrokerBalanceRepositoryProtocol {
    private(set) var count = 0
    private var gate: CheckedContinuation<BrokerBalanceSnapshot, Never>?
    func fetchPortfolioBalance() async throws -> BrokerBalanceSnapshot {
        count += 1
        return await withCheckedContinuation { gate = $0 }
    }
    func finish(_ snapshot: BrokerBalanceSnapshot) {
        gate?.resume(returning: snapshot)
        gate = nil
    }
}
