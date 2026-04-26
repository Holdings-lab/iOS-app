import Combine
import Foundation

@MainActor
final class OnboardingFlowViewModel: ObservableObject {
    @Published private(set) var selectedSectors: Set<InterestSector> = []
    @Published private(set) var selectedStyle: InvestmentStyleOption?
    @Published private(set) var connectedInstitutionID: String?
    @Published var isOtherBrokerExpanded = false

    var allSectors: [InterestSector] {
        InterestSector.allCases
    }

    var recommendedInstitution: AccountInstitution {
        AuthMockData.brokerageInstitutions.first(where: { $0.id == AccountInstitution.koreaInvestmentID })
            ?? AuthMockData.brokerageInstitutions[0]
    }

    var brokerageInstitutions: [AccountInstitution] {
        AuthMockData.brokerageInstitutions
    }

    var connectableInstitutionIDs: Set<String> {
        [AccountInstitution.koreaInvestmentID]
    }

    var otherInstitutions: [AccountInstitution] {
        AuthMockData.brokerageInstitutions.filter { $0.id != recommendedInstitution.id }
    }

    var canAdvanceFromSectorStep: Bool {
        !selectedSectors.isEmpty
    }

    var canAdvanceFromStyleStep: Bool {
        selectedStyle != nil
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

            if result.count == 2 {
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
        selectedStyle?.title ?? "미선택"
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

    func selectStyle(_ style: InvestmentStyleOption) {
        selectedStyle = style
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
        let orderedSectors = selectedSectors
            .sorted { $0.title < $1.title }
            .map(\.id)

        return OnboardingResult(
            connectedInstitutionIDs: connectedInstitutionID.map { [$0] } ?? [],
            selectedSectorIDs: orderedSectors,
            investmentStyleID: selectedStyle?.rawValue ?? InvestmentStyleOption.balanced.rawValue,
            selectedAssetSymbols: [],
            primaryAssetSymbol: nil
        )
    }
}
