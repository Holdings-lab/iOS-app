import Combine
import Foundation

@MainActor
final class OnboardingFlowViewModel: ObservableObject {
    @Published var financialGoal: FinancialGoal = .seedMoney
    @Published var targetAmount: Int64 = FinancialGoal.seedMoney.defaultTargetAmount
    @Published var investmentHorizon: InvestmentHorizon?
    @Published var maxDrawdownTolerance: MaxDrawdownTolerance?
    @Published var investmentProfile: InvestmentProfile?
    @Published private(set) var selectedWatchAssets: Set<WatchAssetSector> = []
    @Published private(set) var connectedInstitutionID: String?
    @Published var brokerageCredential = BrokerageCredentialInput()
    @Published private(set) var isBrokerageCredentialSubmitted = false
    @Published private(set) var brokerageConnectionId: String?

    private let brokerageConnectionRepository: BrokerageConnectionRepositoryProtocol
    private var hasCustomTargetAmount = false

    init(
        brokerageConnectionRepository: BrokerageConnectionRepositoryProtocol = LiveBrokerageConnectionRepository()
    ) {
        self.brokerageConnectionRepository = brokerageConnectionRepository
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

    var connectedInstitution: AccountInstitution? {
        guard let connectedInstitutionID else { return nil }
        return AuthMockData.brokerageInstitutions.first(where: { $0.id == connectedInstitutionID })
    }

    // MARK: - Step 1~2: 투자 목적 · 목표 금액

    func selectFinancialGoal(_ goal: FinancialGoal) {
        financialGoal = goal
        if !hasCustomTargetAmount {
            targetAmount = goal.defaultTargetAmount
        }
    }

    func updateTargetAmount(_ amount: Int64) {
        targetAmount = amount
        hasCustomTargetAmount = amount != financialGoal.defaultTargetAmount
    }

    // MARK: - Step 5: 투자 성향 소프트컨펌

    func profileConflictsWithDrawdown(_ profile: InvestmentProfile) -> Bool {
        guard let maxDrawdownTolerance else { return false }
        return !RiskProfileConsistency.isConsistent(profile: profile, tolerance: maxDrawdownTolerance)
    }

    // MARK: - Step 6: 관심 섹터

    var canAdvanceFromWatchAssetsStep: Bool {
        (1...5).contains(selectedWatchAssets.count)
    }

    func toggleWatchAsset(_ sector: WatchAssetSector) {
        if selectedWatchAssets.contains(sector) {
            selectedWatchAssets.remove(sector)
            return
        }

        guard selectedWatchAssets.count < 5 else { return }
        selectedWatchAssets.insert(sector)
    }

    // MARK: - Step 7: 계좌 연결

    func canConnect(_ institution: AccountInstitution) -> Bool {
        connectableInstitutionIDs.contains(institution.id)
    }

    func selectInstitution(_ institution: AccountInstitution) {
        guard canConnect(institution) else { return }
        connectedInstitutionID = institution.id
    }

    func skipBrokerageConnection() {
        connectedInstitutionID = nil
        brokerageCredential = BrokerageCredentialInput()
        isBrokerageCredentialSubmitted = false
    }

    // MARK: - Step 8: 완료 처리

    /// 서버가 요청을 정상 수신했다는 응답을 받았을 때만 true를 반환한다. 실패/미응답이어도
    /// 온보딩 자체는 막지 않되, 호출부(Step8 완료 화면)가 이 결과를 보고 목업 대기 여부를 결정한다.
    func submitSettings(userId: Int64?) async -> Bool {
        guard let userId else { return false }

        do {
            let body = try NetworkJSONCoding.encodeJSON(
                OnboardingSettingsPatchRequestDTO(
                    investmentHorizon: (investmentHorizon ?? .threeToFiveYears).rawValue,
                    maxDrawdownTolerance: (maxDrawdownTolerance ?? .withinTen).percentValue,
                    investmentProfile: (investmentProfile ?? .balanced).rawValue
                )
            )
            _ = try await APIClientFactory.makeDefault().requestResult(
                BackendEndpoint.updateMeSettings(userId: userId, body: body),
                as: EmptyAPIResult.self
            )
            return true
        } catch {
            return false
        }
    }

    func submitWatchAssets(userId: Int64?) async -> Bool {
        guard let userId else { return false }

        do {
            let body = try NetworkJSONCoding.encodeJSON(
                WatchAssetsUpdateRequestDTO(sectors: selectedWatchAssets.map(\.rawValue))
            )
            _ = try await APIClientFactory.makeDefault().requestResult(
                BackendEndpoint.updateWatchAssets(userId: userId, body: body),
                as: EmptyAPIResult.self
            )
            return true
        } catch {
            return false
        }
    }

    /// Step 7 "연결하기" 시점에 즉시 호출된다. 서버 공개키가 아직 배포되지 않았거나(BrokerageConnectionError.serverKeyUnavailable)
    /// 요청이 실패하면 기존과 동일하게 짧은 대기 후 제출된 것으로 처리해 온보딩 진행은 막지 않는다.
    func submitBrokerageConnectionIfNeeded(userId: Int64?) async {
        guard let institutionID = connectedInstitutionID, brokerageCredential.isComplete else { return }

        if let userId {
            do {
                let connection = try await brokerageConnectionRepository.connect(
                    userId: userId,
                    institutionID: institutionID,
                    credential: BrokerageCredentialPayloadDTO(
                        loginId: brokerageCredential.brokerageID,
                        loginPassword: brokerageCredential.brokeragePassword,
                        accountPassword: brokerageCredential.accountPassword
                    )
                )
                brokerageConnectionId = connection.connectionId
                isBrokerageCredentialSubmitted = true
                return
            } catch {
                // 백엔드/공개키 미준비 — 아래 목업 경로로 폴백
            }
        }

        try? await Task.sleep(nanoseconds: 400_000_000)
        isBrokerageCredentialSubmitted = true
    }

    func submitGoal(userId: Int64?) async -> Bool {
        guard let userId else { return false }

        do {
            let body = try NetworkJSONCoding.encodeJSON(
                GoalUpdateRequestDTO(financialGoal: financialGoal.rawValue, targetAmount: targetAmount)
            )
            _ = try await APIClientFactory.makeDefault().requestResult(
                BackendEndpoint.updateGoal(userId: userId, body: body),
                as: EmptyAPIResult.self
            )
            return true
        } catch {
            return false
        }
    }

    func makeOnboardingResult() -> OnboardingResult {
        let rebalancing = OnboardingRebalancingPreference(
            investmentProfile: investmentProfile ?? .balanced,
            investmentHorizon: investmentHorizon ?? .threeToFiveYears,
            maxDrawdownTolerance: maxDrawdownTolerance ?? .withinTen
        )

        return OnboardingResult(
            connectedInstitutionIDs: connectedInstitutionID.map { [$0] } ?? [],
            selectedSectorIDs: [],
            selectedKeywordIDs: [],
            investmentStyleID: (investmentProfile ?? .balanced).legacyStyle.rawValue,
            rebalancingPreference: rebalancing,
            selectedAssetSymbols: [],
            primaryAssetSymbol: nil,
            financialGoal: financialGoal.rawValue,
            targetAmount: targetAmount,
            selectedWatchAssetIDs: selectedWatchAssets.map(\.rawValue),
            isBrokerageCredentialSubmitted: isBrokerageCredentialSubmitted
        )
    }
}
