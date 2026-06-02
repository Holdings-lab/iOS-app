import Combine
import Foundation

@MainActor
final class OnboardingFlowViewModel: ObservableObject {
    @Published private(set) var selectedSectors: Set<InterestSector> = []
    @Published private(set) var selectedKeywords: Set<InterestKeyword> = []
    @Published private(set) var selectedStyle: InvestmentStyleOption? = InvestmentProfile.balanced.legacyStyle
    @Published private(set) var rebalancingPreference = OnboardingRebalancingPreference()
    @Published private(set) var connectedInstitutionID: String?
    @Published private(set) var isSavingInvestmentProfile = false
    @Published private(set) var investmentProfileSaveError: String?
    @Published private(set) var savedInvestmentProfile: InvestmentProfileResponse?

    private let investmentProfileRepository: InvestmentProfileRepositoryProtocol
    private var didLoadRemoteInvestmentProfile = false

    init(investmentProfileRepository: InvestmentProfileRepositoryProtocol? = nil) {
        self.investmentProfileRepository = investmentProfileRepository ?? LiveInvestmentProfileRepository()
    }

    var allSectors: [InterestSector] {
        InterestSector.onboardingOptions
    }

    var allKeywordCategories: [InterestKeywordCategory] {
        InterestKeywordCategory.allCategories
    }

    var recommendedInstitution: AccountInstitution {
        AuthMockData.brokerageInstitutions.first(where: { $0.id == AccountInstitution.koreaInvestmentID })
            ?? AuthMockData.brokerageInstitutions[0]
    }

    var brokerageInstitutions: [AccountInstitution] {
        let orderedIDs = [
            AccountInstitution.koreaInvestmentID,
            "mirae",
            "kiwoom",
            "samsung_securities",
            "nh_invest",
            "shinhan_invest"
        ]

        return orderedIDs.compactMap { id in
            AuthMockData.brokerageInstitutions.first(where: { $0.id == id })
        }
    }

    var connectableInstitutionIDs: Set<String> {
        [AccountInstitution.koreaInvestmentID]
    }

    var canAdvanceFromSectorStep: Bool {
        !selectedSectors.isEmpty
    }

    var canAdvanceFromKeywordStep: Bool {
        selectedKeywords.count >= 3
    }

    var keywordSelectionCount: Int {
        selectedKeywords.count
    }

    var keywordNewsPreview: String {
        switch orderedSelectedKeywords.first?.id {
        case "qqq":
            return "美 연준 금리 동결에 QQQ 0.8% 상승 마감"
        case "nvidia":
            return "엔비디아, AI 칩 수요 급증으로 분기 매출 신기록"
        case "fomc":
            return "FOMC 의사록 공개 — 금리 인하 시점 불확실성 지속"
        case "tsla":
            return "테슬라, 2분기 인도량 전망치 하회 우려"
        case "xle":
            return "유가 3% 급등, XLE 에너지 ETF 동반 상승"
        default:
            return "선택한 키워드 기반 시그널이 분석되고 있어요"
        }
    }

    var previewItems: [OnboardingNewsPreviewItem] {
        let sectors = selectedSectors.isEmpty
            ? [InterestSector.semiconductor]
            : selectedSectors.sorted { $0.title < $1.title }

        let uniqueItems = sectors
            .flatMap(\.previewItems)

        var seenIDs = Set<String>()
        var result: [OnboardingNewsPreviewItem] = []

        for item in uniqueItems where !seenIDs.contains(item.id) {
            result.append(item)
            seenIDs.insert(item.id)

            if result.count == 1 {
                break
            }
        }

        return result
    }

    var selectedSectorSummary: String {
        let titles = selectedSectors
            .sorted { $0.title < $1.title }
            .map(\.title)

        return titles.isEmpty ? "선택 없음" : titles.joined(separator: ", ")
    }

    var selectedStyleSummary: String {
        rebalancingPreference.investmentProfile.displayName
    }

    var selectedInvestmentGoalSummary: String {
        rebalancingPreference.investmentGoal.title
    }

    var selectedInvestmentHorizonSummary: String {
        rebalancingPreference.investmentHorizon.title
    }

    var selectedDrawdownSummary: String {
        rebalancingPreference.maxDrawdownTolerance.title
    }

    var selectedDownturnBehaviorSummary: String {
        rebalancingPreference.downturnBehavior.title
    }

    var selectedTargetCashWeightSummary: String {
        "\(cashWeightPercent)%"
    }

    var selectedAssetPreferenceSummary: String {
        rebalancingPreference.assetPreference.title
    }

    var connectedInstitutionSummary: String {
        guard let institution = connectedInstitution else {
            return "나중에 연결하기"
        }

        return institution.name
    }

    var connectedInstitution: AccountInstitution? {
        guard let connectedInstitutionID else { return nil }
        return AuthMockData.brokerageInstitutions.first(where: { $0.id == connectedInstitutionID })
    }

    var cashWeightPercent: Int {
        Int((rebalancingPreference.targetCashWeight * 100).rounded())
    }

    var cashWeightDescription: String {
        switch cashWeightPercent {
        case ...5:
            return "공격적 운용, 기회 포착에 유리해요"
        case 6...15:
            return "기본 현금 완충을 남겨요"
        default:
            return "조정 대응 여력이 넉넉히 돼요"
        }
    }

    func recommendedHorizon(for goal: InvestmentGoal) -> InvestmentHorizon {
        switch goal {
        case .preserve:
            return .oneToThreeYears
        case .steadyGrowth:
            return .threeToFiveYears
        case .activeReturn:
            return .overFiveYears
        }
    }

    func recommendedRiskSettings(for profile: InvestmentProfile) -> (drawdown: MaxDrawdownTolerance, downturn: DownturnBehavior) {
        switch profile {
        case .conservative:
            return (.withinTen, .reduce)
        case .balanced:
            return (.withinTen, .hold)
        case .aggressive:
            return (.withinTwenty, .buyMore)
        }
    }

    func canConnect(_ institution: AccountInstitution) -> Bool {
        connectableInstitutionIDs.contains(institution.id)
    }

    func toggleSector(_ sector: InterestSector) {
        if selectedSectors.contains(sector) {
            selectedSectors.remove(sector)
        } else {
            selectedSectors.insert(sector)
        }
    }

    func toggleKeyword(_ keyword: InterestKeyword) {
        if selectedKeywords.contains(keyword) {
            selectedKeywords.remove(keyword)
        } else {
            selectedKeywords.insert(keyword)
        }
    }

    func selectInvestmentProfile(_ profile: InvestmentProfile) {
        rebalancingPreference.investmentProfile = profile
        selectedStyle = profile.legacyStyle
        applyRecommendedRiskSettings(for: profile)
        investmentProfileSaveError = nil
    }

    func selectInvestmentGoal(_ goal: InvestmentGoal) {
        rebalancingPreference.investmentGoal = goal
        rebalancingPreference.investmentHorizon = recommendedHorizon(for: goal)
    }

    func selectInvestmentHorizon(_ horizon: InvestmentHorizon) {
        rebalancingPreference.investmentHorizon = horizon
    }

    func selectMaxDrawdownTolerance(_ tolerance: MaxDrawdownTolerance) {
        rebalancingPreference.maxDrawdownTolerance = tolerance
    }

    func selectDownturnBehavior(_ behavior: DownturnBehavior) {
        rebalancingPreference.downturnBehavior = behavior
    }

    func setTargetCashWeight(percent: Int) {
        let boundedPercent = min(max(percent, 0), 30)
        rebalancingPreference.targetCashWeight = Double(boundedPercent) / 100
    }

    func selectAssetPreference(_ preference: AssetPreference) {
        rebalancingPreference.assetPreference = preference
    }

    func resetFundingDefaults() {
        setTargetCashWeight(percent: 10)
        selectAssetPreference(.etfAndStocks)
    }

    func connectRecommendedBroker() {
        connectedInstitutionID = recommendedInstitution.id
    }

    func selectInstitution(_ institution: AccountInstitution) {
        guard canConnect(institution) else { return }
        connectedInstitutionID = institution.id
    }

    func skipBrokerageConnection() {
        connectedInstitutionID = nil
    }

    private func applyRecommendedRiskSettings(for profile: InvestmentProfile) {
        let settings = recommendedRiskSettings(for: profile)
        rebalancingPreference.maxDrawdownTolerance = settings.drawdown
        rebalancingPreference.downturnBehavior = settings.downturn
    }

    private var orderedSelectedKeywords: [InterestKeyword] {
        allKeywordCategories
            .flatMap(\.keywords)
            .filter { selectedKeywords.contains($0) }
    }

    func makeOnboardingResult() -> OnboardingResult {
        let orderedSectors = selectedSectors
            .sorted { $0.title < $1.title }
            .map(\.id)

        let orderedKeywordIDs = orderedSelectedKeywords.map(\.id)

        return OnboardingResult(
            connectedInstitutionIDs: connectedInstitutionID.map { [$0] } ?? [],
            selectedSectorIDs: orderedSectors,
            selectedKeywordIDs: orderedKeywordIDs,
            investmentStyleID: rebalancingPreference.investmentProfile.legacyStyle.rawValue,
            rebalancingPreference: rebalancingPreference,
            selectedAssetSymbols: [],
            primaryAssetSymbol: nil
        )
    }

    func loadInvestmentProfileIfAvailable(userId: Int64?) async {
        guard let userId, !didLoadRemoteInvestmentProfile else { return }
        didLoadRemoteInvestmentProfile = true

        do {
            let response = try await investmentProfileRepository.fetchInvestmentProfile(userId: userId)
            savedInvestmentProfile = response
            selectInvestmentProfile(response.investmentProfile)
        } catch {
            debugLog("투자성향 조회 실패: \(String(describing: error))")
        }
    }

    func saveInvestmentProfile(userId: Int64?) async -> Bool {
        guard !isSavingInvestmentProfile else { return false }

        guard let userId else {
            investmentProfileSaveError = "사용자 정보를 찾지 못했어요. 다시 로그인한 뒤 시도해주세요."
            return false
        }

        isSavingInvestmentProfile = true
        investmentProfileSaveError = nil

        do {
            let response = try await investmentProfileRepository.updateInvestmentProfile(
                userId: userId,
                profile: rebalancingPreference.investmentProfile
            )
            savedInvestmentProfile = response
            isSavingInvestmentProfile = false
            return true
        } catch {
            debugLog("투자성향 저장 실패, 로컬 설정으로 계속 진행: \(String(describing: error))")
            savedInvestmentProfile = InvestmentProfileResponse(
                userId: userId,
                investmentProfile: rebalancingPreference.investmentProfile,
                displayName: rebalancingPreference.investmentProfile.displayName
            )
            investmentProfileSaveError = nil
            isSavingInvestmentProfile = false
            return true
        }
    }

    private func debugLog(_ message: String) {
#if DEBUG
        print("[Onboarding] \(message)")
#endif
    }
}
