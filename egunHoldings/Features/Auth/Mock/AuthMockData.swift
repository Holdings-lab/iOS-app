import Foundation

struct AuthMockData {
    static let institutions: [AccountInstitution] = [
        AccountInstitution(id: AccountInstitution.koreaInvestmentID, name: "한국투자증권", emoji: "🐻", accentHex: "2563EB", category: .securities, isPopular: true),
        AccountInstitution(id: "kiwoom", name: "키움증권", emoji: "🟠", accentHex: "F59E0B", category: .securities, isPopular: true),
        AccountInstitution(id: "samsung_securities", name: "삼성증권", emoji: "🔵", accentHex: "3B82F6", category: .securities, isPopular: true),
        AccountInstitution(id: "mirae", name: "미래에셋증권", emoji: "🟢", accentHex: "10B981", category: .securities, isPopular: true),
        AccountInstitution(id: "nh_invest", name: "NH투자증권", emoji: "🟡", accentHex: "FACC15", category: .securities, isPopular: true),
        AccountInstitution(id: "kb_securities", name: "KB증권", emoji: "🟤", accentHex: "D97706", category: .securities, isPopular: false),
        AccountInstitution(id: "hana_securities", name: "하나증권", emoji: "🔴", accentHex: "EF4444", category: .securities, isPopular: false),
        AccountInstitution(id: "shinhan_invest", name: "신한투자증권", emoji: "🔷", accentHex: "38BDF8", category: .securities, isPopular: false),
        AccountInstitution(id: "toss_securities", name: "토스증권", emoji: "💙", accentHex: "3B82F6", category: .securities, isPopular: false),
        AccountInstitution(id: "kakao_bank", name: "카카오뱅크", emoji: "💛", accentHex: "FACC15", category: .bank, isPopular: false),
        AccountInstitution(id: "toss_bank", name: "토스뱅크", emoji: "💙", accentHex: "3B82F6", category: .bank, isPopular: false),
        AccountInstitution(id: "kbank", name: "케이뱅크", emoji: "💜", accentHex: "A855F7", category: .bank, isPopular: false),
        AccountInstitution(id: "shinhan_bank", name: "신한은행", emoji: "🔷", accentHex: "0EA5E9", category: .bank, isPopular: false),
        AccountInstitution(id: "kb_bank", name: "KB국민은행", emoji: "⭐️", accentHex: "F59E0B", category: .bank, isPopular: false),
        AccountInstitution(id: "hana_bank", name: "하나은행", emoji: "🟢", accentHex: "22C55E", category: .bank, isPopular: false)
    ]

    static var brokerageInstitutions: [AccountInstitution] {
        institutions.filter { $0.category == .securities }
    }

    nonisolated static let defaultExistingUserOnboarding = OnboardingResult(
        connectedInstitutionIDs: [AccountInstitution.koreaInvestmentID],
        selectedSectorIDs: [InterestSector.semiconductor.rawValue, InterestSector.energy.rawValue],
        investmentStyleID: InvestmentStyleOption.balanced.rawValue,
        selectedAssetSymbols: ["QQQ"],
        primaryAssetSymbol: "QQQ"
    )

    nonisolated static let defaultRegisteredAccounts: [RegisteredAuthAccount] = [
        RegisteredAuthAccount(
            userId: 1,
            userName: "정책고수",
            email: "investor@policyfinance.app",
            onboardingCompleted: true,
            onboardingResult: defaultExistingUserOnboarding,
            brokerBalanceSnapshot: nil
        ),
        RegisteredAuthAccount(
            userId: 2,
            userName: "온보딩테스트",
            email: "eom175@naver.com",
            onboardingCompleted: false,
            onboardingResult: nil,
            brokerBalanceSnapshot: nil
        )
    ]

    static func makeAssetProfile(from onboarding: OnboardingResult?) -> UserAssetProfile {
        guard let onboarding else {
            return AppMockData.userAssetProfile
        }

        if !onboarding.selectedAssetSymbols.isEmpty {
            return makeAssetProfile(fromSelectedAssets: onboarding.selectedAssetSymbols)
        }

        let selectedSectors = onboarding.selectedSectorIDs.compactMap(InterestSector.init(rawValue:))
        let style = InvestmentStyleOption(rawValue: onboarding.investmentStyleID) ?? .balanced

        let etfBudget: Int
        let depositWeight: Int
        let loanWeight: Int

        switch style {
        case .aggressive:
            etfBudget = 70
            depositWeight = 10
            loanWeight = 20
        case .growth:
            etfBudget = 60
            depositWeight = 20
            loanWeight = 20
        case .balanced:
            etfBudget = 45
            depositWeight = 30
            loanWeight = 25
        case .stable:
            etfBudget = 30
            depositWeight = 45
            loanWeight = 25
        }

        let sectorPool = selectedSectors.isEmpty ? [.finance, .semiconductor] : Array(selectedSectors.prefix(4))
        var entries: [(String, AssetCategory, Int)] = []

        let baseETF = etfBudget / sectorPool.count
        var etfRemainder = etfBudget % sectorPool.count

        for sector in sectorPool {
            let extra = etfRemainder > 0 ? 1 : 0
            etfRemainder -= extra
            entries.append((etfName(for: sector), .etf, baseETF + extra))
        }

        let firstConnectedBank = institutions.first(where: { onboarding.connectedInstitutionIDs.contains($0.id) && $0.category == .bank })
        let depositName = firstConnectedBank.map { "\($0.name) 예금" } ?? "정기예금"
        entries.append((depositName, .depositSavings, depositWeight))
        entries.append(("주택담보대출", .loan, loanWeight))

        let holdings = entries.enumerated().map { index, entry in
            UserHoldingItem(
                id: index + 1,
                name: entry.0,
                category: entry.1,
                weightPercent: entry.2
            )
        }

        return UserAssetProfile(holdings: holdings)
    }

    private static func makeAssetProfile(fromSelectedAssets symbols: [String]) -> UserAssetProfile {
        let selectedAssets = symbols.compactMap(ETFAsset.asset(for:))

        guard !selectedAssets.isEmpty else {
            return AppMockData.userAssetProfile
        }

        let etfBudget = 65
        let reserveWeight = 20
        let bufferWeight = 15
        let baseWeight = etfBudget / selectedAssets.count
        var remainder = etfBudget % selectedAssets.count

        var holdings = selectedAssets.enumerated().map { index, asset in
            let extra = remainder > 0 ? 1 : 0
            remainder -= extra

            return UserHoldingItem(
                id: index + 1,
                name: asset.symbol,
                category: .etf,
                weightPercent: baseWeight + extra
            )
        }

        holdings.append(
            UserHoldingItem(
                id: holdings.count + 1,
                name: "현금성 자산",
                category: .depositSavings,
                weightPercent: reserveWeight
            )
        )
        holdings.append(
            UserHoldingItem(
                id: holdings.count + 1,
                name: "안전자산 버퍼",
                category: .depositSavings,
                weightPercent: bufferWeight
            )
        )

        return UserAssetProfile(holdings: holdings)
    }

    private static func etfName(for sector: InterestSector) -> String {
        switch sector {
        case .semiconductor: return "SOXX"
        case .energy: return "ICLN"
        case .finance: return "KODEX 은행 ETF"
        case .defense: return "ARIRANG K방산Fn"
        case .bio: return "XBI"
        case .mobility: return "DRIV"
        case .realEstate: return "VNQ"
        case .ev: return "LIT"
        case .ai: return "BOTZ"
        }
    }
}
