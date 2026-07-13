import Foundation

nonisolated struct OnboardingResult: Codable, Sendable {
    var connectedInstitutionIDs: [String]
    var selectedSectorIDs: [String]
    var selectedKeywordIDs: [String]
    var investmentStyleID: String
    var rebalancingPreference: OnboardingRebalancingPreference?
    var selectedAssetSymbols: [String]
    var primaryAssetSymbol: String?
    var financialGoal: String
    var targetAmount: Int64
    var selectedWatchAssetIDs: [String]
    var isBrokerageCredentialSubmitted: Bool

    init(
        connectedInstitutionIDs: [String] = [],
        selectedSectorIDs: [String] = [],
        selectedKeywordIDs: [String] = [],
        investmentStyleID: String = InvestmentStyleOption.balanced.rawValue,
        rebalancingPreference: OnboardingRebalancingPreference? = nil,
        selectedAssetSymbols: [String] = [],
        primaryAssetSymbol: String? = nil,
        financialGoal: String = FinancialGoal.seedMoney.rawValue,
        targetAmount: Int64 = FinancialGoal.seedMoney.defaultTargetAmount,
        selectedWatchAssetIDs: [String] = [],
        isBrokerageCredentialSubmitted: Bool = false
    ) {
        self.connectedInstitutionIDs = connectedInstitutionIDs
        self.selectedSectorIDs = selectedSectorIDs
        self.selectedKeywordIDs = selectedKeywordIDs
        self.investmentStyleID = investmentStyleID
        self.rebalancingPreference = rebalancingPreference
        self.selectedAssetSymbols = selectedAssetSymbols
        self.primaryAssetSymbol = primaryAssetSymbol
        self.financialGoal = financialGoal
        self.targetAmount = targetAmount
        self.selectedWatchAssetIDs = selectedWatchAssetIDs
        self.isBrokerageCredentialSubmitted = isBrokerageCredentialSubmitted
    }

    private enum CodingKeys: String, CodingKey {
        case connectedInstitutionIDs
        case selectedSectorIDs
        case selectedKeywordIDs
        case investmentStyleID
        case rebalancingPreference
        case selectedAssetSymbols
        case primaryAssetSymbol
        case financialGoal
        case targetAmount
        case selectedWatchAssetIDs
        case isBrokerageCredentialSubmitted
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        connectedInstitutionIDs = try container.decodeIfPresent([String].self, forKey: .connectedInstitutionIDs) ?? []
        selectedSectorIDs = try container.decodeIfPresent([String].self, forKey: .selectedSectorIDs) ?? []
        selectedKeywordIDs = try container.decodeIfPresent([String].self, forKey: .selectedKeywordIDs) ?? []
        investmentStyleID = try container.decodeIfPresent(String.self, forKey: .investmentStyleID) ?? InvestmentStyleOption.balanced.rawValue
        rebalancingPreference = try container.decodeIfPresent(OnboardingRebalancingPreference.self, forKey: .rebalancingPreference)
        selectedAssetSymbols = try container.decodeIfPresent([String].self, forKey: .selectedAssetSymbols) ?? []
        primaryAssetSymbol = try container.decodeIfPresent(String.self, forKey: .primaryAssetSymbol)
        financialGoal = try container.decodeIfPresent(String.self, forKey: .financialGoal) ?? FinancialGoal.seedMoney.rawValue
        targetAmount = try container.decodeIfPresent(Int64.self, forKey: .targetAmount) ?? FinancialGoal.seedMoney.defaultTargetAmount
        selectedWatchAssetIDs = try container.decodeIfPresent([String].self, forKey: .selectedWatchAssetIDs) ?? []
        isBrokerageCredentialSubmitted = try container.decodeIfPresent(Bool.self, forKey: .isBrokerageCredentialSubmitted) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(connectedInstitutionIDs, forKey: .connectedInstitutionIDs)
        try container.encode(selectedSectorIDs, forKey: .selectedSectorIDs)
        try container.encode(selectedKeywordIDs, forKey: .selectedKeywordIDs)
        try container.encode(investmentStyleID, forKey: .investmentStyleID)
        try container.encodeIfPresent(rebalancingPreference, forKey: .rebalancingPreference)
        try container.encode(selectedAssetSymbols, forKey: .selectedAssetSymbols)
        try container.encodeIfPresent(primaryAssetSymbol, forKey: .primaryAssetSymbol)
        try container.encode(financialGoal, forKey: .financialGoal)
        try container.encode(targetAmount, forKey: .targetAmount)
        try container.encode(selectedWatchAssetIDs, forKey: .selectedWatchAssetIDs)
        try container.encode(isBrokerageCredentialSubmitted, forKey: .isBrokerageCredentialSubmitted)
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
