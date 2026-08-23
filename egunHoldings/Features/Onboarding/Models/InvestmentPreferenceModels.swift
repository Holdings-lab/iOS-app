import Foundation

enum InvestmentProfile: String, CaseIterable, Identifiable, Codable, Sendable {
    case conservative = "CONSERVATIVE"
    case balanced = "BALANCED"
    case aggressive = "AGGRESSIVE"

    nonisolated var id: String { rawValue }

    nonisolated var displayName: String {
        switch self {
        case .conservative:
            return "안정형"
        case .balanced:
            return "중립형"
        case .aggressive:
            return "공격형"
        }
    }
}

struct InvestmentStyleAllocation: Identifiable, Hashable {
    let id: String
    let label: String
    let percentage: Int
    let colorHex: String
}

extension InvestmentProfile {
    var title: String {
        displayName
    }

    var subtitle: String {
        switch self {
        case .conservative:
            return "변동성을 줄이고 현금과 방어자산을 더 중시해요"
        case .balanced:
            return "수익과 안정 사이의 균형을 기준으로 조정해요"
        case .aggressive:
            return "변동성을 감수하고 성장자산 비중을 허용해요"
        }
    }

    var symbol: String {
        switch self {
        case .conservative: return "shield.lefthalf.filled"
        case .balanced: return "scale.3d"
        case .aggressive: return "chart.line.uptrend.xyaxis"
        }
    }

    var tintHex: String {
        switch self {
        case .conservative: return "378ADD"
        case .balanced: return "1D9E75"
        case .aggressive: return "E8593C"
        }
    }

    var impactSummary: String {
        switch self {
        case .conservative:
            return "현금 비중과 한 자산 최대 비중을 더 보수적으로 잡아요"
        case .balanced:
            return "유지할 현금 비중과 성장자산 비중을 균형 있게 맞춰요"
        case .aggressive:
            return "매수 기회 탐지와 성장자산 허용폭을 더 넓게 봐요"
        }
    }

    var legacyStyle: InvestmentStyleOption {
        switch self {
        case .conservative: return .stable
        case .balanced: return .balanced
        case .aggressive: return .aggressive
        }
    }
}

enum InvestmentGoal: String, CaseIterable, Identifiable, Codable, Sendable {
    case preserve = "PRESERVE"
    case steadyGrowth = "STEADY_GROWTH"
    case activeReturn = "ACTIVE_RETURN"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .preserve: return "안정적으로 지키기"
        case .steadyGrowth: return "꾸준히 불리기"
        case .activeReturn: return "적극적으로 추구"
        }
    }

    var subtitle: String {
        switch self {
        case .preserve: return "손실 억제와 현금 여력을 우선해요"
        case .steadyGrowth: return "장기 수익과 변동성 관리를 함께 봐요"
        case .activeReturn: return "기회가 보이면 더 빠르게 비중을 조정해요"
        }
    }

    var symbol: String {
        switch self {
        case .preserve: return "lock.shield"
        case .steadyGrowth: return "leaf"
        case .activeReturn: return "bolt.fill"
        }
    }
}

enum InvestmentHorizon: String, CaseIterable, Identifiable, Codable, Sendable {
    case underOneYear = "UNDER_1Y"
    case oneToThreeYears = "ONE_TO_THREE_YEARS"
    case threeToFiveYears = "THREE_TO_FIVE_YEARS"
    case overFiveYears = "OVER_FIVE_YEARS"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .underOneYear: return "1년 미만"
        case .oneToThreeYears: return "1~3년"
        case .threeToFiveYears: return "3~5년"
        case .overFiveYears: return "5년 이상"
        }
    }

    var subtitle: String {
        switch self {
        case .underOneYear: return "짧은 기간이라 방어 기준을 높여요"
        case .oneToThreeYears: return "현금과 ETF 비중을 함께 조절해요"
        case .threeToFiveYears: return "중기 조정과 성장 기회를 함께 봐요"
        case .overFiveYears: return "장기 복리를 우선해 변동성 허용폭을 넓혀요"
        }
    }

    var symbol: String {
        switch self {
        case .underOneYear: return "calendar"
        case .oneToThreeYears: return "calendar.badge.clock"
        case .threeToFiveYears: return "chart.bar.xaxis"
        case .overFiveYears: return "clock.arrow.circlepath"
        }
    }
}

enum DownturnBehavior: String, CaseIterable, Identifiable, Codable, Sendable {
    case reduce = "REDUCE"
    case hold = "HOLD"
    case buyMore = "BUY_MORE"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reduce: return "비중 줄이기"
        case .hold: return "일단 유지"
        case .buyMore: return "기회로 매수"
        }
    }

    var subtitle: String {
        switch self {
        case .reduce: return "하락 민감도를 높이고 현금화를 우선해요"
        case .hold: return "과도한 매매를 줄이고 균형을 유지해요"
        case .buyMore: return "가격 매력을 보고 분할 매수 여지를 둬요"
        }
    }

    var symbol: String {
        switch self {
        case .reduce: return "arrow.down.to.line"
        case .hold: return "pause.circle"
        case .buyMore: return "plus.circle"
        }
    }
}

enum TargetCashWeight: Double, CaseIterable, Identifiable, Codable, Sendable {
    case five = 0.05
    case ten = 0.10
    case twenty = 0.20

    var id: Double { rawValue }

    var title: String {
        switch self {
        case .five: return "5%"
        case .ten: return "10%"
        case .twenty: return "20%"
        }
    }

    var subtitle: String {
        switch self {
        case .five: return "투자 비중을 높게 유지해요"
        case .ten: return "기본 현금 완충을 남겨요"
        case .twenty: return "조정장 대응 여력을 넉넉히 둬요"
        }
    }

    var symbol: String {
        switch self {
        case .five: return "banknote"
        case .ten: return "dollarsign.circle"
        case .twenty: return "tray.full"
        }
    }
}

enum AssetPreference: String, CaseIterable, Identifiable, Codable, Sendable {
    case etfFocused = "ETF_FOCUSED"
    case etfAndStocks = "ETF_AND_STOCKS"
    case highVolatilityAllowed = "HIGH_VOLATILITY_ALLOWED"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .etfFocused: return "ETF 중심"
        case .etfAndStocks: return "ETF + 개별주"
        case .highVolatilityAllowed: return "성장주/고변동성 자산도 허용"
        }
    }

    var subtitle: String {
        switch self {
        case .etfFocused: return "분산된 ETF를 중심으로 추천해요"
        case .etfAndStocks: return "ETF를 기본으로 핵심 개별주도 열어둬요"
        case .highVolatilityAllowed: return "성장 테마와 변동성 자산까지 살펴요"
        }
    }

    var symbol: String {
        switch self {
        case .etfFocused: return "square.stack.3d.up"
        case .etfAndStocks: return "list.bullet.rectangle"
        case .highVolatilityAllowed: return "sparkline"
        }
    }
}

enum InvestmentStyleOption: String, CaseIterable, Identifiable, Codable {
    case aggressive
    case growth
    case balanced
    case stable

    var id: String { rawValue }

    var title: String {
        switch self {
        case .aggressive: return "공격적 투자"
        case .growth: return "성장형 투자"
        case .balanced: return "균형형 투자"
        case .stable: return "안정형 투자"
        }
    }

    var subtitle: String {
        switch self {
        case .aggressive: return "높은 리스크 감수"
        case .growth: return "중장기 성장에 집중"
        case .balanced: return "수익과 안정의 균형"
        case .stable: return "원금 보존 최우선"
        }
    }

    var symbol: String {
        switch self {
        case .aggressive: return "flame"
        case .growth: return "chart.line.uptrend.xyaxis"
        case .balanced: return "target"
        case .stable: return "shield"
        }
    }

    var emoji: String {
        switch self {
        case .aggressive: return "🔥"
        case .growth: return "📈"
        case .balanced: return "🎯"
        case .stable: return "🛡"
        }
    }

    var tintHex: String {
        switch self {
        case .aggressive: return "E8593C"
        case .growth: return "7C6FFF"
        case .balanced: return "1D9E75"
        case .stable: return "378ADD"
        }
    }

    var iconBackgroundOpacity: Double {
        0.18
    }

    var allocations: [InvestmentStyleAllocation] {
        switch self {
        case .aggressive:
            return [
                InvestmentStyleAllocation(id: "aggressive-1", label: "테마·고변동", percentage: 55, colorHex: "E8593C"),
                InvestmentStyleAllocation(id: "aggressive-2", label: "성장 섹터", percentage: 30, colorHex: "7C6FFF"),
                InvestmentStyleAllocation(id: "aggressive-3", label: "현금 비중", percentage: 15, colorHex: "5BBBFF")
            ]
        case .growth:
            return [
                InvestmentStyleAllocation(id: "growth-1", label: "성장 섹터", percentage: 50, colorHex: "7C6FFF"),
                InvestmentStyleAllocation(id: "growth-2", label: "ETF·테마", percentage: 30, colorHex: "A78BFA"),
                InvestmentStyleAllocation(id: "growth-3", label: "현금 비중", percentage: 20, colorHex: "5BBBFF")
            ]
        case .balanced:
            return [
                InvestmentStyleAllocation(id: "balanced-1", label: "핵심 ETF", percentage: 40, colorHex: "1D9E75"),
                InvestmentStyleAllocation(id: "balanced-2", label: "배당·방어", percentage: 35, colorHex: "5BBBFF"),
                InvestmentStyleAllocation(id: "balanced-3", label: "현금 비중", percentage: 25, colorHex: "7C6FFF")
            ]
        case .stable:
            return [
                InvestmentStyleAllocation(id: "stable-1", label: "채권·배당", percentage: 45, colorHex: "378ADD"),
                InvestmentStyleAllocation(id: "stable-2", label: "우량 ETF", percentage: 25, colorHex: "5BBBFF"),
                InvestmentStyleAllocation(id: "stable-3", label: "현금 비중", percentage: 30, colorHex: "7C6FFF")
            ]
        }
    }
}
