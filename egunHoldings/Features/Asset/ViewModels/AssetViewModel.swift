import Combine
import SwiftUI

@MainActor
final class AssetViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case failed(String)
    }

    @Published private(set) var portfolioDisplay: AssetPortfolioDisplay?
    @Published private(set) var loadState: LoadState
    @Published private(set) var isConnecting = false

    private var brokerBalanceSnapshot: BrokerBalanceSnapshot?
    private let brokerBalanceRepository: BrokerBalanceRepositoryProtocol
    private let brokerageConnectionRepository: BrokerageConnectionRepositoryProtocol

    init(
        brokerBalanceSnapshot: BrokerBalanceSnapshot? = nil,
        brokerBalanceRepository: BrokerBalanceRepositoryProtocol = BackendPortfolioBalanceRepository(),
        brokerageConnectionRepository: BrokerageConnectionRepositoryProtocol = LiveBrokerageConnectionRepository()
    ) {
        self.brokerBalanceSnapshot = brokerBalanceSnapshot
        self.brokerBalanceRepository = brokerBalanceRepository
        self.brokerageConnectionRepository = brokerageConnectionRepository

        if let brokerBalanceSnapshot {
            portfolioDisplay = AssetPortfolioDisplay(snapshot: brokerBalanceSnapshot)
            loadState = Self.isEmptyPortfolio(brokerBalanceSnapshot) ? .empty : .loaded
        } else {
            portfolioDisplay = nil
            loadState = .idle
        }
    }

    func loadIfNeeded() async -> BrokerBalanceSnapshot? {
        guard loadState == .idle else { return nil }
        return await reload()
    }

    @discardableResult
    func reload() async -> BrokerBalanceSnapshot? {
        guard !isConnecting else { return nil }
        loadState = .loading

        do {
            let snapshot = try await brokerBalanceRepository.fetchPortfolioBalance()
            apply(snapshot)
            return snapshot
        } catch {
            portfolioDisplay = nil
            loadState = .failed(AppVocabulary.ErrorMessage.userFacing(for: error, fallback: "자산을 불러오지 못했어요."))
            return nil
        }
    }

    @discardableResult
    func connectKISDemoAccount() async -> BrokerBalanceSnapshot? {
        guard !isConnecting else { return nil }
        isConnecting = true
        defer { isConnecting = false }

        do {
            let connection = try await brokerageConnectionRepository.connectKISDemoAccount(
                institutionID: AccountInstitution.koreaInvestmentID
            )
            try await brokerageConnectionRepository.sync(accountId: connection.accountId)
            let snapshot = try await brokerBalanceRepository.fetchPortfolioBalance()
            apply(snapshot)
            return snapshot
        } catch {
            loadState = .failed(AppVocabulary.ErrorMessage.userFacing(for: error, fallback: "한국투자증권 모의투자 계좌를 연결하지 못했어요."))
            return nil
        }
    }

    /// 로그인/부트스트랩 이후 늦게 도착하는 잔고 조회 응답을 반영한다.
    /// AssetView를 재생성하지 않고 표시용 데이터만 갱신해 스크롤 위치를 유지한다.
    func updateBrokerBalance(_ snapshot: BrokerBalanceSnapshot?) {
        guard snapshot != brokerBalanceSnapshot else { return }
        brokerBalanceSnapshot = snapshot
        guard let snapshot else { return }
        apply(snapshot)
    }

    private func apply(_ snapshot: BrokerBalanceSnapshot) {
        brokerBalanceSnapshot = snapshot
        portfolioDisplay = AssetPortfolioDisplay(snapshot: snapshot)
        loadState = Self.isEmptyPortfolio(snapshot) ? .empty : .loaded
    }

    private static func isEmptyPortfolio(_ snapshot: BrokerBalanceSnapshot) -> Bool {
        snapshot.accountNumber.isEmpty
            && snapshot.holdings.isEmpty
            && snapshot.totalEvaluationAmount == 0
            && snapshot.cashAmount == 0
    }
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
        let holdingValues = snapshot.holdings.reduce(into: [AssetHoldingCategory: Int]()) { result, holding in
            let category = AssetHoldingCategory(symbol: holding.symbol)
            result[category, default: 0] += holding.marketValue
        }
        let holdingValueTotal = holdingValues.values.reduce(0, +)
        let investedAmount = max(snapshot.totalEvaluationAmount - snapshot.cashAmount, 0)
        let categorizedAmounts: [AssetHoldingCategory: Int]

        if holdingValueTotal > 0 {
            categorizedAmounts = holdingValues.mapValues { holdingValue in
                Int((Double(holdingValue) / Double(holdingValueTotal) * Double(investedAmount)).rounded())
            }
        } else {
            categorizedAmounts = investedAmount > 0 ? [.stock: investedAmount] : [:]
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
                amountText: currency(holding.marketValue, code: holding.currencyCode),
                profitText: "\(signedCurrency(holding.profitLossAmount, code: holding.currencyCode)) (\(percent(holding.profitLossRate)))",
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
                    amountText: currency(snapshot.cashAmount, code: "KRW"),
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
        currency(value, code: "KRW")
    }

    private static func currency(_ value: Int, code: String) -> String {
        let normalizedCode = code.uppercased()
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = normalizedCode
        formatter.locale = Locale(identifier: normalizedCode == "KRW" ? "ko_KR" : "en_US")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(normalizedCode) 0"
    }

    private static func signedKRW(_ value: Int) -> String {
        signedCurrency(value, code: "KRW")
    }

    private static func signedCurrency(_ value: Int, code: String) -> String {
        let sign = value > 0 ? "+" : ""
        return "\(sign)\(currency(value, code: code))"
    }

    private static func percent(_ value: Double) -> String {
        let sign = value > 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, value)
    }

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
