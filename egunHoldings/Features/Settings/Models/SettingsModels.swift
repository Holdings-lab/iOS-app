import SwiftUI

// MARK: - Policy categories (신규 — 설정 탭 전용)

struct PolicyCategory: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
}

// MARK: - Connected accounts (신규 — 설정 탭 전용)

enum AccountStatus {
    case ok, reauth, error
}

struct BrokerMeta: Identifiable {
    let id: String
    let glyph: String
    let name: String
    let tint: Color
    let bg: Color
}

struct ConnectedAccount: Identifiable {
    let brokerId: String
    var status: AccountStatus
    var lastSync: String?

    var id: String { brokerId }
}

// MARK: - MaxDrawdownTolerance 설정 탭 전용 힌트 문구

extension MaxDrawdownTolerance {
    var settingsHint: String {
        switch percentValue {
        case 10: return "작은 하락에도 민감하게 반응해요"
        case 20: return "어느 정도의 변동은 견딜 수 있어요"
        default: return "큰 폭의 하락도 감내할 수 있어요"
        }
    }
}

// MARK: - FinancialGoal 설정 탭 전용 금액 프리셋 (온보딩과 슬라이더 범위가 달라 분리)

struct SettingsGoalPreset {
    let amount: Int64
    let min: Int64
    let max: Int64
    let step: Int64
}

extension FinancialGoal {
    var settingsEmoji: String {
        switch self {
        case .retirement: return "🌇"
        case .seedMoney: return "🌰"
        case .surplusFunds: return "🧺"
        case .homePurchase: return "🏠"
        }
    }

    var settingsPreset: SettingsGoalPreset {
        switch self {
        case .retirement: return SettingsGoalPreset(amount: 500_000_000, min: 100_000_000, max: 1_500_000_000, step: 50_000_000)
        case .seedMoney: return SettingsGoalPreset(amount: 50_000_000, min: 10_000_000, max: 300_000_000, step: 5_000_000)
        case .surplusFunds: return SettingsGoalPreset(amount: 30_000_000, min: 5_000_000, max: 200_000_000, step: 5_000_000)
        case .homePurchase: return SettingsGoalPreset(amount: 300_000_000, min: 50_000_000, max: 1_000_000_000, step: 50_000_000)
        }
    }
}

// MARK: - WatchAssetSector 설정 탭 전용 설명 문구 (온보딩 칩에는 subtitle이 없어 분리)

extension WatchAssetSector {
    var subtitle: String {
        switch self {
        case .semiconductor: return "파운드리·메모리 공급망 이슈에 민감해요"
        case .aiPlatform: return "데이터센터 투자와 규제 흐름이 바로 반영돼요"
        case .secondaryBattery: return "전기차 수요와 원자재 가격에 연동돼요"
        case .greenEnergy: return "보조금과 전력 인프라 정책에 반응해요"
        case .finance: return "금리 경로와 대출 규제 변화에 빠르게 반응해요"
        case .healthcare: return "신약 승인·임상 결과에 따라 변동성이 커요"
        case .consumer: return "소비 심리와 유통 데이터에 민감하게 움직여요"
        case .realEstate: return "금리와 공급 정책에 따라 흐름이 바뀌어요"
        }
    }
}

// MARK: - Mock data

enum SettingsMockData {
    static let brokers: [BrokerMeta] = [
        BrokerMeta(id: "hi", glyph: "友", name: "한국투자증권", tint: Color(hex: "E84A4A"), bg: Color(hex: "FCEBEB")),
        BrokerMeta(id: "mi", glyph: "미", name: "미래에셋증권", tint: Color(hex: "F5852C"), bg: Color(hex: "FEF1E6")),
        BrokerMeta(id: "ki", glyph: "키", name: "키움증권", tint: Color(hex: "C8202E"), bg: Color(hex: "FAE9EB")),
        BrokerMeta(id: "sam", glyph: "삼", name: "삼성증권", tint: Color(hex: "1428A0"), bg: Color(hex: "E8EBF6")),
        BrokerMeta(id: "nh", glyph: "NH", name: "NH투자증권", tint: Color(hex: "00A04B"), bg: Color(hex: "E4F4EC")),
        BrokerMeta(id: "sh", glyph: "신", name: "신한투자증권", tint: Color(hex: "0046C7"), bg: Color(hex: "E6EDFB"))
    ]

    static let brokerByID: [String: BrokerMeta] = Dictionary(uniqueKeysWithValues: brokers.map { ($0.id, $0) })

    static let policyCategories: [PolicyCategory] = [
        PolicyCategory(id: "SEMI", title: "반도체 공급망", subtitle: "수출 규제 · 설비 투자 이슈"),
        PolicyCategory(id: "RATES", title: "통화정책 · 금리", subtitle: "기준금리, 국채 금리 흐름"),
        PolicyCategory(id: "FX", title: "환율", subtitle: "원달러 환율 변동"),
        PolicyCategory(id: "TRADE", title: "무역 · 관세", subtitle: "통상 협상, 관세 이슈"),
        PolicyCategory(id: "REALESTATE", title: "부동산 정책", subtitle: "대출 규제, 공급 정책"),
        PolicyCategory(id: "ENERGY", title: "에너지 · 친환경", subtitle: "전력 수급, 재생에너지 정책"),
        PolicyCategory(id: "LABOR", title: "노동시장", subtitle: "고용 지표, 최저임금"),
        PolicyCategory(id: "FISCAL", title: "재정정책", subtitle: "정부 예산, 감세·지출")
    ]

    static let initialAccounts: [ConnectedAccount] = [
        ConnectedAccount(brokerId: "hi", status: .ok, lastSync: "방금 전"),
        ConnectedAccount(brokerId: "mi", status: .reauth, lastSync: nil),
        ConnectedAccount(brokerId: "ki", status: .error, lastSync: nil)
    ]

    static let initialWatchSectors: Set<WatchAssetSector> = [.semiconductor, .aiPlatform]
    static let initialPolicyCategoryIDs: Set<String> = ["SEMI", "RATES", "FX"]
}
