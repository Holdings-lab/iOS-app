import Combine
import Foundation

@MainActor
final class OnboardingFlowViewModel: ObservableObject {
    @Published private(set) var selectedKeywords: Set<InterestKeyword> = []
    @Published private(set) var connectedInstitutionID: String?

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

    var connectedInstitution: AccountInstitution? {
        guard let connectedInstitutionID else { return nil }
        return AuthMockData.brokerageInstitutions.first(where: { $0.id == connectedInstitutionID })
    }

    func canConnect(_ institution: AccountInstitution) -> Bool {
        connectableInstitutionIDs.contains(institution.id)
    }

    func toggleKeyword(_ keyword: InterestKeyword) {
        if selectedKeywords.contains(keyword) {
            selectedKeywords.remove(keyword)
        } else {
            selectedKeywords.insert(keyword)
        }
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

    func makeOnboardingResult() -> OnboardingResult {
        OnboardingResult(
            connectedInstitutionIDs: connectedInstitutionID.map { [$0] } ?? [],
            selectedSectorIDs: [],
            selectedKeywordIDs: orderedSelectedKeywords.map(\.id),
            investmentStyleID: InvestmentStyleOption.balanced.rawValue,
            rebalancingPreference: nil,
            selectedAssetSymbols: [],
            primaryAssetSymbol: nil
        )
    }

    private var orderedSelectedKeywords: [InterestKeyword] {
        allKeywordCategories
            .flatMap(\.keywords)
            .filter { selectedKeywords.contains($0) }
    }
}
