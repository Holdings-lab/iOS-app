import Combine
import Foundation

enum RebalancingPreferenceStep: Int, CaseIterable, Identifiable {
    case profile
    case goalAndHorizon
    case riskResponse
    case allocation

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .profile: return "투자 성향"
        case .goalAndHorizon: return "목표와 기간"
        case .riskResponse: return "손실 대응"
        case .allocation: return "현금과 방식"
        }
    }
}

nonisolated protocol InvestmentProfileRepositoryProtocol: Sendable {
    func fetchInvestmentProfile(userId: Int64) async throws -> InvestmentProfileResponse
    func updateInvestmentProfile(userId: Int64, profile: InvestmentProfile) async throws -> InvestmentProfileResponse
}

nonisolated struct InvestmentProfileResponse: Decodable, Sendable, Equatable {
    let userId: Int64
    let investmentProfile: InvestmentProfile
    let displayName: String
}

nonisolated private struct InvestmentProfileRequestDTO: Encodable {
    let investmentProfile: String
}

nonisolated struct LiveInvestmentProfileRepository: InvestmentProfileRepositoryProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClientFactory.makeDefault()) {
        self.apiClient = apiClient
    }

    func fetchInvestmentProfile(userId: Int64) async throws -> InvestmentProfileResponse {
        try await apiClient.requestResult(
            BackendEndpoint.investmentProfile(userId: userId),
            as: InvestmentProfileResponse.self
        )
    }

    func updateInvestmentProfile(userId: Int64, profile: InvestmentProfile) async throws -> InvestmentProfileResponse {
        let body = try NetworkJSONCoding.encodeJSON(
            InvestmentProfileRequestDTO(investmentProfile: profile.rawValue)
        )

        do {
            return try await apiClient.requestResult(
                BackendEndpoint.updateInvestmentProfile(userId: userId, body: body),
                as: InvestmentProfileResponse.self
            )
        } catch {
            guard Self.shouldUseLocalProfileFallback(for: error) else {
                throw error
            }

            return InvestmentProfileResponse(
                userId: userId,
                investmentProfile: profile,
                displayName: profile.displayName
            )
        }
    }

    private static func shouldUseLocalProfileFallback(for error: Error) -> Bool {
        guard let networkError = error as? NetworkError else {
            return false
        }

        switch networkError {
        case .httpStatus(404), .notImplemented:
            return true
        case .apiFailure(let statusCode, let code, _):
            return statusCode == 404 || code == "FAIL-003"
        default:
            return false
        }
    }
}

@MainActor
final class OnboardingFlowViewModel: ObservableObject {
    @Published private(set) var selectedSectors: Set<InterestSector> = []
    @Published private(set) var selectedStyle: InvestmentStyleOption? = InvestmentProfile.balanced.legacyStyle
    @Published private(set) var rebalancingPreference = OnboardingRebalancingPreference()
    @Published private(set) var rebalancingStep: RebalancingPreferenceStep = .profile
    @Published private(set) var connectedInstitutionID: String?
    @Published private(set) var isSavingInvestmentProfile = false
    @Published private(set) var investmentProfileSaveError: String?
    @Published private(set) var savedInvestmentProfile: InvestmentProfileResponse?
    @Published var isOtherBrokerExpanded = false

    private let investmentProfileRepository: InvestmentProfileRepositoryProtocol
    private var didLoadRemoteInvestmentProfile = false

    init(investmentProfileRepository: InvestmentProfileRepositoryProtocol? = nil) {
        self.investmentProfileRepository = investmentProfileRepository ?? LiveInvestmentProfileRepository()
    }

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
        true
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
        rebalancingPreference.targetCashWeightOption.title
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

        switch style {
        case .stable:
            selectInvestmentProfile(.conservative)
        case .balanced, .growth:
            selectInvestmentProfile(.balanced)
        case .aggressive:
            selectInvestmentProfile(.aggressive)
        }
    }

    func selectInvestmentProfile(_ profile: InvestmentProfile) {
        rebalancingPreference.investmentProfile = profile
        selectedStyle = profile.legacyStyle
        investmentProfileSaveError = nil
    }

    func selectInvestmentGoal(_ goal: InvestmentGoal) {
        rebalancingPreference.investmentGoal = goal
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

    func selectTargetCashWeight(_ targetCashWeight: TargetCashWeight) {
        rebalancingPreference.targetCashWeight = targetCashWeight.rawValue
    }

    func selectAssetPreference(_ preference: AssetPreference) {
        rebalancingPreference.assetPreference = preference
    }

    func moveToNextRebalancingStep() -> Bool {
        let steps = RebalancingPreferenceStep.allCases
        guard let currentIndex = steps.firstIndex(of: rebalancingStep) else {
            return true
        }

        let nextIndex = steps.index(after: currentIndex)
        guard nextIndex < steps.endIndex else {
            return true
        }

        rebalancingStep = steps[nextIndex]
        return false
    }

    func moveToPreviousRebalancingStep() -> Bool {
        let steps = RebalancingPreferenceStep.allCases
        guard let currentIndex = steps.firstIndex(of: rebalancingStep), currentIndex > steps.startIndex else {
            return false
        }

        let previousIndex = steps.index(before: currentIndex)
        rebalancingStep = steps[previousIndex]
        return true
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
            investmentProfileSaveError = Self.makeErrorMessage(
                for: error,
                fallback: "투자성향을 저장하지 못했어요. 잠시 후 다시 시도해주세요."
            )
            isSavingInvestmentProfile = false
            return false
        }
    }

    private static func makeErrorMessage(for error: Error, fallback: String) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription,
           !description.isEmpty {
            return description
        }

        return fallback
    }

    private func debugLog(_ message: String) {
#if DEBUG
        print("[Onboarding] \(message)")
#endif
    }
}
