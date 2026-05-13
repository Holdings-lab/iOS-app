import Combine
import SwiftUI

@MainActor
final class AssetViewModel: ObservableObject {
    @Published var selectedSegment: AssetSegment = .overview
    @Published var isBrokerConnectionPresented = false
    @Published var selectedRecommendationFilter: RebalancingRecommendationFilter = .all
    @Published private(set) var rebalancingLoadState: RebalancingLoadState = .idle
    @Published private(set) var rebalancingDashboard: RebalancingDashboard

    let dashboard: AssetDashboard

    private let userId: Int64?
    private let brokerBalanceSnapshot: BrokerBalanceSnapshot?
    private let rebalancingRepository: AssetRebalancingRepositoryProtocol
    private var didLoadRebalancing = false

    init(
        userId: Int64? = nil,
        brokerBalanceSnapshot: BrokerBalanceSnapshot? = nil,
        repository: AssetRepositoryProtocol? = nil,
        rebalancingRepository: AssetRebalancingRepositoryProtocol? = nil
    ) {
        self.userId = userId
        self.brokerBalanceSnapshot = brokerBalanceSnapshot
        self.rebalancingRepository = rebalancingRepository ?? AssetRebalancingRepositoryFactory.makeDefault()
        dashboard = (repository ?? MockAssetRepository()).fetchDashboard()
        rebalancingDashboard = MockAssetRebalancingRepository.makeDashboard(userId: userId)
    }

    var filteredRebalancingRecommendations: [RebalancingRecommendation] {
        guard let action = selectedRecommendationFilter.action else {
            return rebalancingDashboard.recommendations
        }

        return rebalancingDashboard.recommendations.filter { $0.action == action }
    }

    var rebalancingDataStatusText: String {
        switch rebalancingLoadState {
        case .idle:
            return "조정 제안 준비 중"
        case .loading:
            return "조정 제안 계산 중"
        case .loaded:
            return rebalancingDashboard.dataSource == "MOCK" ? "예시 데이터" : "서버 조정 제안 연결됨"
        case .usingFallback:
            return "예시 데이터"
        }
    }

    var rebalancingDataFootnote: String {
        switch rebalancingLoadState {
        case .idle:
            return "투자 성향과 보유 자산 기준의 조정 제안을 준비하고 있습니다."
        case .loading:
            return "서버가 투자 성향, 보유 수량, 현재 가격, 현금을 기준으로 조정 제안을 계산 중입니다."
        case .loaded:
            return rebalancingDashboard.dataSource == "REQUEST"
                ? "실계좌 보유 수량, 현재 가격, 현금을 서버로 보내 계산한 결과입니다."
                : "서버의 관심자산 기반 예시 포지션으로 계산한 결과입니다."
        case .usingFallback(let message):
            return message.map { "\($0)" }
                ?? "서버 연결 전까지 예시 추천을 표시합니다."
        }
    }

    func selectSegment(_ segment: AssetSegment) {
        selectedSegment = segment
    }

    func selectRecommendationFilter(_ filter: RebalancingRecommendationFilter) {
        selectedRecommendationFilter = filter
    }

    func loadRebalancingIfNeeded() async {
        guard !didLoadRebalancing else { return }
        didLoadRebalancing = true
        await refreshRebalancing()
    }

    func refreshRebalancing() async {
        rebalancingLoadState = .loading

        let startedAt = Date()
        let minimumDuration: TimeInterval = 0.8

        let nextState: RebalancingLoadState
        do {
            let dashboard = try await rebalancingRepository.fetchRebalancing(
                userId: userId,
                brokerBalanceSnapshot: brokerBalanceSnapshot
            )
            rebalancingDashboard = dashboard
            nextState = .loaded
        } catch {
            rebalancingDashboard = MockAssetRebalancingRepository.makeDashboard(userId: userId)
            nextState = .usingFallback(message: Self.errorMessage(for: error))
        }

        let elapsed = Date().timeIntervalSince(startedAt)
        if elapsed < minimumDuration {
            let remaining = minimumDuration - elapsed
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
        }

        rebalancingLoadState = nextState
    }

    func presentBrokerConnection() {
        isBrokerConnectionPresented = true
    }

    func dismissBrokerConnection() {
        isBrokerConnectionPresented = false
    }

    private static func errorMessage(for error: Error) -> String {
        AppVocabulary.ErrorMessage.userFacing(for: error)
    }
}
