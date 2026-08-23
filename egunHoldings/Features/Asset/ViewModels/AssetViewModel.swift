import Combine
import SwiftUI

@MainActor
final class AssetViewModel: ObservableObject {
    @Published private(set) var portfolioDisplay: AssetPortfolioDisplay

    private var brokerBalanceSnapshot: BrokerBalanceSnapshot?

    init(
        brokerBalanceSnapshot: BrokerBalanceSnapshot? = nil
    ) {
        self.brokerBalanceSnapshot = brokerBalanceSnapshot
        portfolioDisplay = AssetPortfolioDisplay(
            snapshot: brokerBalanceSnapshot ?? Self.makeFallbackBalanceSnapshot()
        )
    }

    /// 로그인/부트스트랩 이후 늦게 도착하는 잔고 조회 응답을 반영한다.
    /// AssetView를 재생성하지 않고 표시용 데이터만 갱신해 스크롤 위치를 유지한다.
    func updateBrokerBalance(_ snapshot: BrokerBalanceSnapshot?) {
        guard snapshot != brokerBalanceSnapshot else { return }
        brokerBalanceSnapshot = snapshot
        portfolioDisplay = AssetPortfolioDisplay(snapshot: snapshot ?? Self.makeFallbackBalanceSnapshot())
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
