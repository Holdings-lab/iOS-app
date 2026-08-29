import Foundation

nonisolated enum FinancialGoal: String, CaseIterable, Identifiable, Codable, Sendable {
    case retirement = "RETIREMENT"
    case seedMoney = "SEED_MONEY"
    case surplusFunds = "SURPLUS_FUNDS"
    case homePurchase = "HOME_PURCHASE"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .retirement: return "은퇴 자금 마련"
        case .seedMoney: return "목돈(종잣돈) 모으기"
        case .surplusFunds: return "여유자금 굴리기"
        case .homePurchase: return "내 집 마련"
        }
    }

    var symbol: String {
        switch self {
        case .retirement: return "figure.walk"
        case .seedMoney: return "banknote"
        case .surplusFunds: return "leaf"
        case .homePurchase: return "house"
        }
    }

    var defaultTargetAmount: Int64 {
        switch self {
        case .retirement: return 500_000_000
        case .seedMoney: return 50_000_000
        case .surplusFunds: return 30_000_000
        case .homePurchase: return 300_000_000
        }
    }

    var targetAmountSliderRange: ClosedRange<Double> {
        switch self {
        case .retirement: return 100_000_000...2_000_000_000
        case .seedMoney: return 10_000_000...300_000_000
        case .surplusFunds: return 5_000_000...200_000_000
        case .homePurchase: return 50_000_000...1_000_000_000
        }
    }

    var targetAmountSliderStep: Double {
        switch self {
        case .retirement, .homePurchase: return 10_000_000
        case .seedMoney, .surplusFunds: return 5_000_000
        }
    }
}

enum WatchAssetSector: String, CaseIterable, Identifiable, Codable, Sendable {
    case semiconductor = "SEMICONDUCTOR"
    case aiPlatform = "AI_PLATFORM"
    case secondaryBattery = "SECONDARY_BATTERY"
    case greenEnergy = "GREEN_ENERGY"
    case finance = "FINANCE"
    case healthcare = "HEALTHCARE"
    case consumer = "CONSUMER"
    case realEstate = "REAL_ESTATE"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .semiconductor: return "반도체"
        case .aiPlatform: return "AI · 플랫폼"
        case .secondaryBattery: return "2차전지"
        case .greenEnergy: return "친환경 · 에너지"
        case .finance: return "금융"
        case .healthcare: return "헬스케어 · 바이오"
        case .consumer: return "소비재 · 리테일"
        case .realEstate: return "부동산 · 리츠"
        }
    }

    var emoji: String {
        switch self {
        case .semiconductor: return "💾"
        case .aiPlatform: return "🤖"
        case .secondaryBattery: return "🔋"
        case .greenEnergy: return "⚡️"
        case .finance: return "🏦"
        case .healthcare: return "🧬"
        case .consumer: return "🛍️"
        case .realEstate: return "🏠"
        }
    }
}

enum OnboardingCurrencyFormatter {
    static func wonText(_ amount: Int64) -> String {
        let eok = amount / 100_000_000
        let man = (amount % 100_000_000) / 10_000

        if eok > 0 {
            guard man > 0 else { return "\(eok)억원" }
            return "\(eok)억 \(man.formatted())만원"
        }

        return "\(man.formatted())만원"
    }
}

/// Step 7 계좌 연결 진행 단계.
/// 앱키·시크릿은 서버가 보유하므로 사용자가 입력할 크리덴셜은 없지만, 연결이 어떤 순서로
/// 이뤄지는지는 그대로 노출한다. 각 단계는 실제 모의투자 잔고 조회 한 번에 대응한다.
/// 연결이 끝난 뒤 Step 7·Step 8이 보여주는 계좌 요약.
/// 잔고 조회가 실패하면 각 필드가 nil이 되고, 화면은 숫자 없이 연결 완료만 노출한다.
struct LinkedDemoAccount: Equatable, Sendable {
    let accountNumber: String?
    let holdingCount: Int?
    let totalEvaluationAmount: Int?

    /// 계좌번호는 앞 4자리만 노출한다.
    var maskedAccountNumber: String? {
        guard let accountNumber, accountNumber.count > 4 else { return accountNumber }
        return accountNumber.prefix(4) + String(repeating: "•", count: accountNumber.count - 4)
    }
}

enum BrokerageLinkStage: Int, CaseIterable, Identifiable, Sendable {
    case authenticating
    case verifyingAccount
    case loadingHoldings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .authenticating:
            return "한국투자증권 모의투자 서버에 연결하는 중"
        case .verifyingAccount:
            return "모의투자 계좌를 확인하는 중"
        case .loadingHoldings:
            return "보유 종목을 불러오는 중"
        }
    }
}

enum MaxDrawdownTolerance: String, CaseIterable, Identifiable, Codable, Sendable {
    case withinFive = "WITHIN_5"
    case withinTen = "WITHIN_10"
    case withinTwenty = "WITHIN_20"
    case overThirty = "OVER_30"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .withinFive: return "-5% 이내"
        case .withinTen: return "-10% 이내"
        case .withinTwenty: return "-20% 이내"
        case .overThirty: return "-30% 이상"
        }
    }

    var subtitle: String {
        switch self {
        case .withinFive: return "작은 손실에도 빠르게 방어해요"
        case .withinTen: return "일반적인 조정은 감내하되 과열은 줄여요"
        case .withinTwenty: return "중기 변동성을 열어두고 기회를 봐요"
        case .overThirty: return "큰 흔들림도 성장 기회로 볼 수 있어요"
        }
    }

    var symbol: String {
        switch self {
        case .withinFive: return "minus.circle"
        case .withinTen: return "arrow.down.forward.circle"
        case .withinTwenty: return "waveform.path.ecg"
        case .overThirty: return "flame"
        }
    }
}

extension MaxDrawdownTolerance {
    static let onboardingOptions: [MaxDrawdownTolerance] = [.withinTen, .withinTwenty, .overThirty]

    var onboardingAssumedAmountText: String {
        switch self {
        case .withinFive: return "950만원"
        case .withinTen: return "900만원"
        case .withinTwenty: return "800만원"
        case .overThirty: return "700만원 이하"
        }
    }

    /// 서버 API는 이 값을 문자열 enum이 아닌 순수 숫자(5/10/20/30)로 받는다.
    nonisolated var percentValue: Int {
        switch self {
        case .withinFive: return 5
        case .withinTen: return 10
        case .withinTwenty: return 20
        case .overThirty: return 30
        }
    }
}
