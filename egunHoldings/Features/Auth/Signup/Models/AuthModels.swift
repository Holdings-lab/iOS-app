import Foundation

enum AppRoute: Equatable {
    case loading
    case auth
    case onboarding
    case main
}

nonisolated struct AppUserSession: Codable, Sendable {
    var userId: Int64?
    var token: String
    var refreshToken: String?
    var expiresAt: Date
    let userName: String
    let email: String
    var onboardingCompleted: Bool
    var onboardingResult: OnboardingResult?
    var brokerBalanceSnapshot: BrokerBalanceSnapshot?

    var isTokenValid: Bool {
        Date() < expiresAt
    }
}

nonisolated struct RegisteredAuthAccount: Codable, Sendable, Identifiable {
    var userId: Int64?
    var userName: String
    var email: String
    var password: String
    var onboardingCompleted: Bool
    var onboardingResult: OnboardingResult?
    var brokerBalanceSnapshot: BrokerBalanceSnapshot?

    var id: String {
        normalizedEmail
    }

    var normalizedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

nonisolated struct OnboardingResult: Codable, Sendable {
    var connectedInstitutionIDs: [String]
    var selectedSectorIDs: [String]
    var investmentStyleID: String
    var rebalancingPreference: OnboardingRebalancingPreference?
    var selectedAssetSymbols: [String]
    var primaryAssetSymbol: String?

    init(
        connectedInstitutionIDs: [String] = [],
        selectedSectorIDs: [String] = [],
        investmentStyleID: String = InvestmentStyleOption.balanced.rawValue,
        rebalancingPreference: OnboardingRebalancingPreference? = nil,
        selectedAssetSymbols: [String] = [],
        primaryAssetSymbol: String? = nil
    ) {
        self.connectedInstitutionIDs = connectedInstitutionIDs
        self.selectedSectorIDs = selectedSectorIDs
        self.investmentStyleID = investmentStyleID
        self.rebalancingPreference = rebalancingPreference
        self.selectedAssetSymbols = selectedAssetSymbols
        self.primaryAssetSymbol = primaryAssetSymbol
    }

    private enum CodingKeys: String, CodingKey {
        case connectedInstitutionIDs
        case selectedSectorIDs
        case investmentStyleID
        case rebalancingPreference
        case selectedAssetSymbols
        case primaryAssetSymbol
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        connectedInstitutionIDs = try container.decodeIfPresent([String].self, forKey: .connectedInstitutionIDs) ?? []
        selectedSectorIDs = try container.decodeIfPresent([String].self, forKey: .selectedSectorIDs) ?? []
        investmentStyleID = try container.decodeIfPresent(String.self, forKey: .investmentStyleID) ?? InvestmentStyleOption.balanced.rawValue
        rebalancingPreference = try container.decodeIfPresent(OnboardingRebalancingPreference.self, forKey: .rebalancingPreference)
        selectedAssetSymbols = try container.decodeIfPresent([String].self, forKey: .selectedAssetSymbols) ?? []
        primaryAssetSymbol = try container.decodeIfPresent(String.self, forKey: .primaryAssetSymbol)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(connectedInstitutionIDs, forKey: .connectedInstitutionIDs)
        try container.encode(selectedSectorIDs, forKey: .selectedSectorIDs)
        try container.encode(investmentStyleID, forKey: .investmentStyleID)
        try container.encodeIfPresent(rebalancingPreference, forKey: .rebalancingPreference)
        try container.encode(selectedAssetSymbols, forKey: .selectedAssetSymbols)
        try container.encodeIfPresent(primaryAssetSymbol, forKey: .primaryAssetSymbol)
    }
}

enum AccountCategory: String, Codable {
    case securities
    case bank
}

struct AccountInstitution: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let emoji: String
    let accentHex: String
    let category: AccountCategory
    let isPopular: Bool
}

extension AccountInstitution {
    static let koreaInvestmentID = "korea_investment"

    var displaySubtitle: String {
        switch id {
        case Self.koreaInvestmentID:
            return "시뮬레이션 계정으로 실제 포트폴리오 반응을 미리 확인할 수 있어요"
        case "kiwoom":
            return "국내 주식 중심 보유 계좌를 연결하기 좋아요"
        case "samsung_securities":
            return "연금과 ETF 비중을 함께 보기 좋은 증권사예요"
        case "mirae":
            return "해외 ETF와 성장 섹터 비중 확인에 유리해요"
        case "nh_invest":
            return "배당과 방어 자산 흐름을 함께 체크할 수 있어요"
        default:
            return "설정 후 보유 종목 기준으로 정책 영향도를 계산해드려요"
        }
    }
}

struct OnboardingNewsPreviewItem: Identifiable, Hashable {
    let id: String
    let sectorID: String
    let title: String
    let summary: String
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
        case .activeReturn: return "적극적으로 수익 추구"
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
        case .overFiveYears: return "장기 변동성을 더 넓게 허용할 수 있어요"
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
        case .overThirty: return "-30% 이상도 가능"
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

enum DownturnBehavior: String, CaseIterable, Identifiable, Codable, Sendable {
    case reduce = "REDUCE"
    case hold = "HOLD"
    case buyMore = "BUY_MORE"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reduce: return "비중을 줄이고 싶어요"
        case .hold: return "일단 유지하고 싶어요"
        case .buyMore: return "기회로 보고 추가 매수하고 싶어요"
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

nonisolated struct OnboardingRebalancingPreference: Codable, Sendable, Equatable {
    var investmentProfile: InvestmentProfile
    var investmentGoal: InvestmentGoal
    var investmentHorizon: InvestmentHorizon
    var maxDrawdownTolerance: MaxDrawdownTolerance
    var downturnBehavior: DownturnBehavior
    var targetCashWeight: Double
    var assetPreference: AssetPreference

    init(
        investmentProfile: InvestmentProfile = .balanced,
        investmentGoal: InvestmentGoal = .steadyGrowth,
        investmentHorizon: InvestmentHorizon = .threeToFiveYears,
        maxDrawdownTolerance: MaxDrawdownTolerance = .withinTen,
        downturnBehavior: DownturnBehavior = .hold,
        targetCashWeight: Double = TargetCashWeight.ten.rawValue,
        assetPreference: AssetPreference = .etfAndStocks
    ) {
        self.investmentProfile = investmentProfile
        self.investmentGoal = investmentGoal
        self.investmentHorizon = investmentHorizon
        self.maxDrawdownTolerance = maxDrawdownTolerance
        self.downturnBehavior = downturnBehavior
        self.targetCashWeight = targetCashWeight
        self.assetPreference = assetPreference
    }

    var targetCashWeightOption: TargetCashWeight {
        TargetCashWeight.allCases.first { $0.rawValue == targetCashWeight } ?? .ten
    }
}

enum InterestSector: String, CaseIterable, Identifiable, Codable {
    case semiconductor
    case energy
    case finance
    case defense
    case bio
    case realEstate
    case ev
    case ai

    var id: String { rawValue }

    var title: String {
        switch self {
        case .semiconductor: return "반도체"
        case .energy: return "에너지"
        case .finance: return "금융"
        case .defense: return "방산"
        case .bio: return "바이오"
        case .realEstate: return "부동산"
        case .ev: return "2차전지"
        case .ai: return "AI·소프트웨어"
        }
    }

    var emoji: String {
        switch self {
        case .semiconductor: return "💾"
        case .energy: return "⚡️"
        case .finance: return "🏦"
        case .defense: return "🛡️"
        case .bio: return "🧬"
        case .realEstate: return "🏠"
        case .ev: return "🔋"
        case .ai: return "🤖"
        }
    }

    var colorHex: String {
        switch self {
        case .semiconductor: return "8B5CF6"
        case .energy: return "10B981"
        case .finance: return "3B82F6"
        case .defense: return "EF4444"
        case .bio: return "F59E0B"
        case .realEstate: return "06B6D4"
        case .ev: return "5BBBFF"
        case .ai: return "9F7CFF"
        }
    }

    var description: String {
        switch self {
        case .semiconductor:
            return "보조금·수출 규제와 금리 변화에 민감한 대표 성장 섹터"
        case .energy:
            return "원자재와 전력 인프라 정책이 수익률에 바로 반영돼요"
        case .finance:
            return "금리 경로와 대출 규제 변화에 빠르게 반응해요"
        case .defense:
            return "예산 확대와 수출 승인 뉴스가 수급에 크게 작동해요"
        case .bio:
            return "임상·허가 정책과 세제 변화 영향을 자주 받아요"
        case .realEstate:
            return "대출 규제와 공급 정책이 리츠·건설주에 연결돼요"
        case .ev:
            return "보조금과 공급망 뉴스가 배터리 ETF 흐름을 흔들어요"
        case .ai:
            return "반도체·클라우드 투자 정책과 맞물려 강하게 움직여요"
        }
    }

    var previewItems: [OnboardingNewsPreviewItem] {
        switch self {
        case .semiconductor:
            return [
                OnboardingNewsPreviewItem(id: "semi-1", sectorID: id, title: "미국 반도체 장비 규제 재검토", summary: "장비주와 나스닥 성장 ETF 변동성 확대 가능성"),
                OnboardingNewsPreviewItem(id: "semi-2", sectorID: id, title: "국내 반도체 세액공제 확대 논의", summary: "설비 투자 수혜 기대감으로 공급망 종목 관심 확대")
            ]
        case .energy:
            return [
                OnboardingNewsPreviewItem(id: "energy-1", sectorID: id, title: "전력망 투자 예산 증액 검토", summary: "재생에너지 ETF와 전력 인프라 종목 모멘텀 강화"),
                OnboardingNewsPreviewItem(id: "energy-2", sectorID: id, title: "원유 비축 정책 조정 가능성", summary: "원자재 가격 민감도가 높은 에너지주 주목")
            ]
        case .finance:
            return [
                OnboardingNewsPreviewItem(id: "finance-1", sectorID: id, title: "기준금리 인하 시점 발언 주목", summary: "은행·보험 ETF 수익성 전망 재평가"),
                OnboardingNewsPreviewItem(id: "finance-2", sectorID: id, title: "가계대출 규제 미세 조정 검토", summary: "대형 금융주와 배당 ETF 방어력 체크 필요")
            ]
        case .defense:
            return [
                OnboardingNewsPreviewItem(id: "defense-1", sectorID: id, title: "국방 예산 증액안 국회 논의", summary: "방산 수출 기대감과 장비주 강세 재점화 가능성"),
                OnboardingNewsPreviewItem(id: "defense-2", sectorID: id, title: "우방국 공동개발 계약 추진", summary: "중장기 수주 파이프라인 가시성 확대")
            ]
        case .bio:
            return [
                OnboardingNewsPreviewItem(id: "bio-1", sectorID: id, title: "바이오 특례 상장 요건 개편 검토", summary: "중소형 바이오 변동성 확대 구간 진입 가능성"),
                OnboardingNewsPreviewItem(id: "bio-2", sectorID: id, title: "혁신 신약 지원 예산 확대 발표", summary: "R&D 중심 바이오 ETF에 긍정 신호")
            ]
        case .realEstate:
            return [
                OnboardingNewsPreviewItem(id: "realestate-1", sectorID: id, title: "주택 공급 로드맵 추가 발표 예고", summary: "건설·리츠 관련 뉴스 해석 우선순위 상승"),
                OnboardingNewsPreviewItem(id: "realestate-2", sectorID: id, title: "대출 규제 완화 범위 재검토", summary: "부동산 금융과 리츠 ETF 동반 반응 가능성")
            ]
        case .ev:
            return [
                OnboardingNewsPreviewItem(id: "ev-1", sectorID: id, title: "배터리 보조금 기준 세부안 공개", summary: "2차전지 공급망 ETF 수급 변화 예상"),
                OnboardingNewsPreviewItem(id: "ev-2", sectorID: id, title: "핵심 광물 관세 협상 진전", summary: "소재주 원가 부담 완화 기대감 반영")
            ]
        case .ai:
            return [
                OnboardingNewsPreviewItem(id: "ai-1", sectorID: id, title: "AI 데이터센터 전력 지원책 논의", summary: "클라우드·반도체 동반 수혜 기대"),
                OnboardingNewsPreviewItem(id: "ai-2", sectorID: id, title: "공공 AI 도입 예산 확대 발표", summary: "소프트웨어·인프라 ETF 관심도 상승")
            ]
        }
    }

    var recommendedAssetSymbols: [String] {
        switch self {
        case .semiconductor: return ["SOXX"]
        case .energy: return ["ICLN"]
        case .finance: return ["KODEX 은행 ETF"]
        case .defense: return ["ARIRANG K방산Fn"]
        case .bio: return ["XBI"]
        case .realEstate: return ["VNQ"]
        case .ev: return ["LIT"]
        case .ai: return ["BOTZ"]
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
