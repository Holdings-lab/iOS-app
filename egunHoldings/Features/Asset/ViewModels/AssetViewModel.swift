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
        let investedAmount = max(snapshot.totalEvaluationAmount - snapshot.cashAmount, 0)
        let categorizedAmounts = categorizedHoldingAmounts(snapshot: snapshot, investedAmount: investedAmount)
        var entries = AssetCompositionCategory.displayOrder.compactMap { category -> AssetCompositionSource? in
            guard let amount = categorizedAmounts[category], amount > 0 else { return nil }
            return AssetCompositionSource(category: category, amount: amount)
        }

        if snapshot.cashAmount > 0 {
            entries.append(.cash(snapshot.cashAmount))
        }

        return makeCompositionSegments(entries: entries, total: snapshot.totalEvaluationAmount)
    }

    /// 원화와 외화 종목을 같은 원시 숫자로 합산하지 않는다. 원화 종목은 그대로 쓰고,
    /// 외화 종목은 서버가 내려준 전체 투자 평가금액 중 남는 원화 금액으로 비례 배분한다.
    /// 따라서 화면의 모든 분류 금액은 항상 총 평가금액과 합계가 맞는다.
    private static func categorizedHoldingAmounts(
        snapshot: BrokerBalanceSnapshot,
        investedAmount: Int
    ) -> [AssetCompositionCategory: Int] {
        guard investedAmount > 0 else { return [:] }

        var domesticAmounts: [AssetCompositionCategory: Int] = [:]
        var foreignAmounts: [AssetCompositionCategory: Int] = [:]

        for holding in snapshot.holdings where holding.marketValue > 0 {
            let category = AssetCompositionCategory(holding: holding)
            if holding.currencyCode.uppercased() == "KRW" {
                domesticAmounts[category, default: 0] += holding.marketValue
            } else {
                foreignAmounts[category, default: 0] += holding.marketValue
            }
        }

        let domesticTotal = domesticAmounts.values.reduce(0, +)
        let foreignBudget = max(investedAmount - domesticTotal, 0)
        let allocatedForeign = allocate(foreignAmounts, total: foreignBudget)
        let combined = domesticAmounts.merging(allocatedForeign, uniquingKeysWith: +)

        if combined.isEmpty {
            return [.other: investedAmount]
        }
        return allocate(combined, total: investedAmount)
    }

    private static func makeCompositionSegments(
        entries: [AssetCompositionSource],
        total: Int
    ) -> [AssetCompositionSegment] {
        let percents = roundedAllocation(entries.map(\.amount), total: total)

        return zip(entries, percents).compactMap { entry, percent in
            guard percent > 0 else { return nil }
            return AssetCompositionSegment(title: entry.title, percent: percent, color: entry.color)
        }
    }

    /// 최대 잔여 방식으로 정수 비율의 합계를 정확히 100으로 맞춘다.
    private static func roundedAllocation(_ amounts: [Int], total: Int) -> [Int] {
        guard total > 0, amounts.isEmpty == false else { return Array(repeating: 0, count: amounts.count) }

        let raw = amounts.map { Double($0) / Double(total) * 100 }
        var result = raw.map { Int($0.rounded(.down)) }
        let remainder = max(0, 100 - result.reduce(0, +))
        let indices = raw.indices.sorted { index, otherIndex in
            let fraction = raw[index] - Double(result[index])
            let otherFraction = raw[otherIndex] - Double(result[otherIndex])
            return fraction == otherFraction ? index < otherIndex : fraction > otherFraction
        }

        for index in indices.prefix(remainder) {
            result[index] += 1
        }
        return result
    }

    /// 입력 비중을 지정 합계에 맞춰 배분한다. 통화별 원시 금액을 보정할 때 사용한다.
    private static func allocate(
        _ amounts: [AssetCompositionCategory: Int],
        total: Int
    ) -> [AssetCompositionCategory: Int] {
        let positiveAmounts = amounts.filter { $0.value > 0 }
        let amountTotal = positiveAmounts.values.reduce(0, +)
        guard total > 0, amountTotal > 0 else { return [:] }

        let ordered = AssetCompositionCategory.displayOrder.filter { positiveAmounts[$0] != nil }
        let raw = ordered.map { Double(positiveAmounts[$0, default: 0]) / Double(amountTotal) * Double(total) }
        var allocated = raw.map { Int($0.rounded(.down)) }
        let remainder = max(0, total - allocated.reduce(0, +))
        let indices = raw.indices.sorted { index, otherIndex in
            let fraction = raw[index] - Double(allocated[index])
            let otherFraction = raw[otherIndex] - Double(allocated[otherIndex])
            return fraction == otherFraction ? index < otherIndex : fraction > otherFraction
        }

        for index in indices.prefix(remainder) {
            allocated[index] += 1
        }

        return Dictionary(uniqueKeysWithValues: zip(ordered, allocated))
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

enum AssetCompositionCategory: Hashable, Sendable {
    case stockETF
    case individualStock
    case bond
    case goldCommodity
    case reit
    case other

    static let displayOrder: [AssetCompositionCategory] = [
        .stockETF, .individualStock, .bond, .goldCommodity, .reit, .other
    ]

    init(holding: BrokerHoldingSnapshot) {
        self.init(symbol: holding.symbol, name: holding.name, productType: holding.productType)
    }

    init(symbol: String, name: String, productType: String?) {
        let ticker = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let normalizedName = name.uppercased()
        let normalizedType = productType?.uppercased() ?? ""
        let isExplicitETF = normalizedType.contains("ETF")
            || Self.knownStockETFSymbols.contains(ticker)
            || normalizedName.contains("ETF")
            || Self.koreanETFPrefixes.contains { normalizedName.hasPrefix($0) }

        if Self.bondSymbols.contains(ticker) || normalizedType.contains("BOND") || normalizedType.contains("채권") {
            self = .bond
        } else if Self.goldCommoditySymbols.contains(ticker) {
            self = .goldCommodity
        } else if Self.reitSymbols.contains(ticker) || normalizedType.contains("REIT") || normalizedType.contains("리츠") {
            self = .reit
        } else if isExplicitETF, Self.containsAny(Self.bondKeywords, in: normalizedName) {
            self = .bond
        } else if isExplicitETF, Self.containsAny(Self.goldCommodityKeywords, in: normalizedName) {
            self = .goldCommodity
        } else if isExplicitETF, Self.containsAny(Self.reitKeywords, in: normalizedName) {
            self = .reit
        } else if isExplicitETF {
            self = .stockETF
        } else if normalizedType.contains("FUND") || normalizedType.contains("ETN") {
            self = .other
        } else {
            self = .individualStock
        }
    }

    var title: String {
        switch self {
        case .stockETF: return "주식 ETF"
        case .individualStock: return "개별주"
        case .bond: return "채권·채권 ETF"
        case .goldCommodity: return "금·원자재 ETF"
        case .reit: return "리츠"
        case .other: return "기타"
        }
    }

    var color: Color {
        switch self {
        case .stockETF: return AssetTabPalette.stockETFSegment
        case .individualStock: return AssetTabPalette.stockSegment
        case .bond: return AssetTabPalette.bondSegment
        case .goldCommodity: return AssetTabPalette.goldCommoditySegment
        case .reit: return AssetTabPalette.reitSegment
        case .other: return AssetTabPalette.otherSegment
        }
    }

    private static func containsAny(_ keywords: [String], in value: String) -> Bool {
        keywords.contains { value.contains($0) }
    }

    private static let knownStockETFSymbols: Set<String> = [
        "QQQ", "SOXX", "XLF", "SPY", "VOO", "IVV", "VTI", "ICLN", "XLE", "SMH", "DIA", "IWM", "ARKK",
        "XLK", "XLV", "XLP", "XLY", "XLB", "XLI", "XLU", "VUG", "VTV", "SCHD", "SPLG", "KWEB"
    ]
    private static let bondSymbols: Set<String> = [
        "TLT", "IEF", "SHY", "BND", "AGG", "LQD", "HYG", "TIP", "VGIT", "VCSH", "VGLT", "EMB"
    ]
    private static let goldCommoditySymbols: Set<String> = [
        "GLD", "IAU", "GLDM", "SGOL", "SIVR", "SLV", "USO", "DBC", "PDBC", "COMT"
    ]
    private static let reitSymbols: Set<String> = [
        "VNQ", "SCHH", "XLRE", "IYR", "RWR", "USRT", "REM"
    ]
    private static let koreanETFPrefixes = ["KODEX", "TIGER", "KBSTAR", "ARIRANG", "HANARO", "KOSEF", "TIMEFOLIO", "RISE", "PLUS", "ACE", "SOL"]
    private static let bondKeywords = ["BOND", "TREASURY", "국채", "채권", "회사채", "단기채", "장기채"]
    private static let goldCommodityKeywords = ["GOLD", "금", "SILVER", "은", "OIL", "원유", "COMMODITY", "원자재"]
    private static let reitKeywords = ["REIT", "리츠"]
}

private struct AssetCompositionSource {
    let title: String
    let color: Color
    let amount: Int

    init(category: AssetCompositionCategory, amount: Int) {
        title = category.title
        color = category.color
        self.amount = amount
    }

    static func cash(_ amount: Int) -> AssetCompositionSource {
        AssetCompositionSource(title: "현금", color: AssetTabPalette.cashSegment, amount: amount)
    }

    private init(title: String, color: Color, amount: Int) {
        self.title = title
        self.color = color
        self.amount = amount
    }
}
