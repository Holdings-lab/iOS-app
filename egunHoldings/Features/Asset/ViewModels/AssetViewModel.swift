import Combine
import SwiftUI

@MainActor
final class AssetViewModel: ObservableObject {
    @Published var selectedSegment: AssetSegment = .overview
    @Published var isBrokerConnectionPresented = false
    @Published var navigationDestination: AssetNavigationDestination?
    @Published var selectedRecommendationFilter: RebalancingRecommendationFilter = .all
    @Published private(set) var rebalancingLoadState: RebalancingLoadState = .idle
    @Published private(set) var rebalancingDashboard: RebalancingDashboard

    let dashboard: AssetDashboard
    let portfolioDisplay: AssetPortfolioDisplay

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
        portfolioDisplay = AssetPortfolioDisplay(
            snapshot: brokerBalanceSnapshot ?? Self.makeFallbackBalanceSnapshot()
        )
        rebalancingDashboard = MockAssetRebalancingRepository.makeDashboard(userId: userId)
    }

    var filteredRebalancingRecommendations: [RebalancingRecommendation] {
        guard let action = selectedRecommendationFilter.action else {
            return rebalancingDashboard.recommendations
        }

        return rebalancingDashboard.recommendations.filter { $0.action == action }
    }

    func account(id: Int) -> AssetAccount? {
        dashboard.accounts.first { $0.id == id }
    }

    var weeklyAdjustmentNotice: AssetAdjustmentNotice? {
        guard rebalancingLoadState != .idle, rebalancingLoadState != .loading else {
            return nil
        }

        let tradeCount = rebalancingDashboard.summary.tradeCount
        guard tradeCount > 0 else { return nil }

        return AssetAdjustmentNotice(
            id: 1,
            title: "이번 주 조정 제안 \(tradeCount)건",
            summary: "전체 자산 기준으로 매수와 현금 확보 조정이 필요해요.",
            count: tradeCount,
            color: .electricBlue
        )
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
            if message == nil {
                return "서버 연결 전까지 예시 추천을 표시합니다."
            }

            return "서버 연결 전까지 예시 추천을 표시합니다."
        }
    }

    func selectSegment(_ segment: AssetSegment) {
        withAnimation(Self.pageTransitionAnimation) {
            if segment != .overview {
                navigationDestination = nil
            }

            selectedSegment = segment
        }
    }

    func showOverallPolicyDetail() {
        navigationDestination = .overallPolicy
    }

    func selectAssetAccount(_ account: AssetAccount) {
        navigationDestination = .account(account.id)
    }

    func closeAssetDrilldown() {
        navigationDestination = nil
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

    private static func makeFallbackBalanceSnapshot() -> BrokerBalanceSnapshot {
        BrokerBalanceSnapshot(
            broker: "KIS",
            environment: "MOCK",
            accountNumber: "sandbox",
            productCode: "01",
            totalEvaluationAmount: 10_950_000,
            stockEvaluationAmount: 10_444_326,
            cashAmount: 505_674,
            totalPurchaseAmount: 6_600_000,
            totalProfitLossAmount: 4_350_000,
            holdings: [
                BrokerHoldingSnapshot(
                    symbol: "QQQ",
                    name: "인베스코 QQQ ETF",
                    quantity: 10,
                    averagePurchasePrice: 660_000,
                    purchaseAmount: 6_600_000,
                    evaluationAmount: 10_444_326,
                    profitLossAmount: 3_844_326,
                    profitLossRate: 58.2
                )
            ],
            fetchedAt: Date()
        )
    }

    private static let pageTransitionAnimation = Animation.easeInOut(duration: 0.28)
}

struct AssetPortfolioDisplay {
    let totalEvaluationText: String
    let heroProfitText: String
    let heroProfitTone: AssetProfitTone
    let compositionSegments: [AssetCompositionSegment]
    let holdings: [AssetPortfolioHoldingRow]
    let totalProfitText: String
    let totalProfitRateText: String
    let principalText: String

    init(snapshot: BrokerBalanceSnapshot) {
        totalEvaluationText = Self.krw(snapshot.totalEvaluationAmount)

        let profitRate = Self.profitRate(
            profitAmount: snapshot.totalProfitLossAmount,
            purchaseAmount: snapshot.totalPurchaseAmount
        )
        heroProfitTone = AssetProfitTone(value: snapshot.totalProfitLossAmount)
        heroProfitText = "\(Self.signedKRW(snapshot.totalProfitLossAmount)) (\(Self.percent(profitRate))) 누적 수익"
        totalProfitText = Self.signedKRW(snapshot.totalProfitLossAmount)
        totalProfitRateText = Self.percent(profitRate)
        principalText = Self.krw(snapshot.totalPurchaseAmount)

        compositionSegments = Self.makeCompositionSegments(snapshot: snapshot)
        holdings = Self.makeHoldingRows(snapshot: snapshot)
    }

    private static func makeCompositionSegments(snapshot: BrokerBalanceSnapshot) -> [AssetCompositionSegment] {
        let categorizedAmounts = snapshot.holdings.reduce(into: [AssetHoldingCategory: Int]()) { result, holding in
            let category = AssetHoldingCategory(symbol: holding.symbol)
            result[category, default: 0] += holding.evaluationAmount
        }

        let entries = [
            AssetCompositionSegment(
                title: "ETF",
                percent: percentInt(categorizedAmounts[.etf, default: 0], total: snapshot.totalEvaluationAmount),
                color: AssetTabPalette.etfSegment
            ),
            AssetCompositionSegment(
                title: "주식",
                percent: percentInt(categorizedAmounts[.stock, default: 0], total: snapshot.totalEvaluationAmount),
                color: AssetTabPalette.stockSegment
            ),
            AssetCompositionSegment(
                title: "현금",
                percent: percentInt(snapshot.cashAmount, total: snapshot.totalEvaluationAmount),
                color: AssetTabPalette.cashSegment
            )
        ]

        return entries.filter { $0.percent > 0 }
    }

    private static func makeHoldingRows(snapshot: BrokerBalanceSnapshot) -> [AssetPortfolioHoldingRow] {
        var rows = snapshot.holdings.enumerated().map { index, holding in
            AssetPortfolioHoldingRow(
                id: "holding-\(holding.symbol)-\(index)",
                symbol: holding.symbol,
                title: displayName(for: holding),
                subtitle: "\(holding.quantity)주 보유",
                amountText: krw(holding.evaluationAmount),
                profitText: "\(signedKRW(holding.profitLossAmount)) (\(percent(holding.profitLossRate)))",
                profitTone: AssetProfitTone(value: holding.profitLossAmount),
                isCash: false
            )
        }

        if snapshot.cashAmount > 0 {
            rows.append(
                AssetPortfolioHoldingRow(
                    id: "cash",
                    symbol: nil,
                    title: "현금·예수금",
                    subtitle: "예수금 포함",
                    amountText: krw(snapshot.cashAmount),
                    profitText: "—",
                    profitTone: .flat,
                    isCash: true
                )
            )
        }

        return rows
    }

    private static func displayName(for holding: BrokerHoldingSnapshot) -> String {
        let trimmedName = holding.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty == false {
            return trimmedName
        }

        switch holding.symbol.uppercased() {
        case "QQQ":
            return "인베스코 QQQ ETF"
        case "SOXX":
            return "iShares 반도체 ETF"
        case "XLF":
            return "금융 셀렉트 ETF"
        default:
            return holding.symbol.uppercased()
        }
    }

    private static func profitRate(profitAmount: Int, purchaseAmount: Int) -> Double {
        guard purchaseAmount > 0 else { return 0 }
        return Double(profitAmount) / Double(purchaseAmount) * 100
    }

    private static func percentInt(_ amount: Int, total: Int) -> Int {
        guard total > 0 else { return 0 }
        return Int((Double(amount) / Double(total) * 100).rounded())
    }

    private static func krw(_ value: Int) -> String {
        currencyFormatter.string(from: NSNumber(value: value)) ?? "₩0"
    }

    private static func signedKRW(_ value: Int) -> String {
        let sign = value > 0 ? "+" : ""
        return "\(sign)\(krw(value))"
    }

    private static func percent(_ value: Double) -> String {
        let sign = value > 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, value)
    }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "KRW"
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}

struct AssetCompositionSegment: Identifiable {
    let title: String
    let percent: Int
    let color: Color

    var id: String { title }
}

struct AssetPortfolioHoldingRow: Identifiable {
    let id: String
    let symbol: String?
    let title: String
    let subtitle: String
    let amountText: String
    let profitText: String
    let profitTone: AssetProfitTone
    let isCash: Bool
}

enum AssetProfitTone {
    case up
    case down
    case flat

    init(value: Int) {
        if value > 0 {
            self = .up
        } else if value < 0 {
            self = .down
        } else {
            self = .flat
        }
    }

    var color: Color {
        switch self {
        case .up:
            return AssetTabPalette.up
        case .down:
            return AssetTabPalette.down
        case .flat:
            return AssetTabPalette.neutral
        }
    }
}

private enum AssetHoldingCategory {
    case etf
    case stock

    init(symbol: String) {
        let normalized = symbol.uppercased()
        if Self.etfSymbols.contains(normalized) {
            self = .etf
        } else {
            self = .stock
        }
    }

    private static let etfSymbols: Set<String> = [
        "QQQ", "SOXX", "XLF", "SPY", "VOO", "IVV", "VTI", "TLT", "GLD",
        "ICLN", "XLE", "SMH", "DIA", "IWM", "ARKK"
    ]
}
