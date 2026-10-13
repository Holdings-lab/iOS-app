import Foundation
import Testing
@testable import egunHoldings

struct OnboardingAPIContractTests {
    @Test("온보딩은 목표 금액 없이 투자 성향과 관심 섹터만 서버에 보낸다")
    func usesOnboardingProfileContract() async throws {
        let queue = OnboardingRequestQueue(responses: [
            envelope(resultJSON: "{}"),
        ])
        let repository = LiveOnboardingRepository(apiClient: OnboardingAPIClient(queue: queue))

        try await repository.updateProfile(
            userId: 1,
            investmentHorizon: .threeToFiveYears,
            maxDrawdownTolerance: .withinTwenty,
            investmentProfile: .balanced,
            interests: [.semiconductor, .healthcare]
        )
        let requests = await queue.recordedRequests()
        #expect(requests.map(\.path) == ["/api/onboarding/profile"])
        #expect(requests.map(\.method.rawValue) == ["PATCH"])
        let profile: ProfileRequestBody = try decodeBody(requests[0])
        #expect(profile.investmentHorizon == "THREE_TO_FIVE_YEARS")
        #expect(profile.riskTolerance == "WITHIN_20")
        #expect(profile.investmentStyle == "MODERATE")
        #expect(profile.interests == ["SEMICONDUCTOR", "HEALTHCARE_BIO"])
    }

    @Test("온보딩의 15억원 목표와 계좌 건너뛰기는 서버 요청 없이 로컬 결과에 남는다")
    @MainActor
    func keepsGoalAndSkipLocally() async {
        let queue = OnboardingRequestQueue(responses: [])
        let viewModel = OnboardingFlowViewModel(
            onboardingRepository: LiveOnboardingRepository(apiClient: OnboardingAPIClient(queue: queue))
        )
        viewModel.updateTargetAmount(1_500_000_000)
        #expect(await viewModel.skipBrokerageConnection())
        #expect(viewModel.makeOnboardingResult().targetAmount == 1_500_000_000)
        #expect(await queue.recordedRequests().isEmpty)
    }

    @Test("온보딩 enum은 화면 rawValue가 아닌 서버 wireValue로 변환한다")
    func mapsAllWireValues() {
        #expect(InvestmentProfile.allCases.map(\.wireValue) == ["CONSERVATIVE", "MODERATE", "AGGRESSIVE"])
        #expect(InvestmentHorizon.allCases.map(\.wireValue) == [
            "UNDER_1Y", "ONE_TO_THREE_YEARS", "THREE_TO_FIVE_YEARS", "OVER_FIVE_YEARS",
        ])
        #expect(MaxDrawdownTolerance.allCases.map(\.wireValue) == ["WITHIN_5", "WITHIN_10", "WITHIN_20", "OVER_30"])
        #expect(WatchAssetSector.allCases.map(\.wireValue) == [
            "SEMICONDUCTOR", "AI_PLATFORM", "SECONDARY_BATTERY", "GREEN_ENERGY",
            "FINANCE", "HEALTHCARE_BIO", "CONSUMER_RETAIL", "REAL_ESTATE_REIT",
        ])
    }

    private func decodeBody<T: Decodable>(_ endpoint: Endpoint) throws -> T {
        let data = try #require(endpoint.body)
        return try NetworkJSONCoding.makeDecoder().decode(T.self, from: data)
    }

    private func envelope(resultJSON: String) -> Data {
        Data(#"{"isSuccess":true,"code":"SUCCESS-200","message":"OK","result":\#(resultJSON)}"#.utf8)
    }
}

private struct ProfileRequestBody: Decodable {
    let investmentHorizon: String
    let riskTolerance: String
    let investmentStyle: String
    let interests: [String]
}

private enum OnboardingRequestError: Error {
    case missingResponse
}

private actor OnboardingRequestQueue {
    private var responses: [Data]
    private var requests: [Endpoint] = []

    init(responses: [Data]) {
        self.responses = responses
    }

    func nextResponse(for endpoint: Endpoint) throws -> Data {
        requests.append(endpoint)
        guard !responses.isEmpty else { throw OnboardingRequestError.missingResponse }
        return responses.removeFirst()
    }

    func recordedRequests() -> [Endpoint] { requests }
}

private struct OnboardingAPIClient: APIClient {
    let queue: OnboardingRequestQueue

    nonisolated func request<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        let data = try await queue.nextResponse(for: endpoint)
        return try NetworkJSONCoding.makeDecoder().decode(type, from: data)
    }
}
