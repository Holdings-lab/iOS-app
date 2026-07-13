import Foundation

/// UI/UX 검증용 시나리오. 화면 상태를 전부 커버한다 (Mock 레퍼런스 기준).
/// 가장 자주 보이는 상태는 `calmAllQuiet`다.
enum NewsroomDigestScenario: String, CaseIterable, Identifiable {
    /// A. calm + 전 종목 조용 (quietDays 각기 다름) — 기본 상태
    case calmAllQuiet
    /// B. calm + 일부 종목만 뉴스 (히어로/컴팩트/조용 혼재)
    case calmMixed
    /// C. alert + materiality high 다이제스트 포함
    case alert
    /// 네트워크 에러 — payload가 아니라 Repository 에러로 재현 (상세 가이드 §4.4)
    case loadFailure

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calmAllQuiet:
            return "조용한 주간"
        case .calmMixed:
            return "일부 종목 뉴스"
        case .alert:
            return "변동 이슈 발생"
        case .loadFailure:
            return "네트워크 에러"
        }
    }
}

/// 픽스처(`NewsroomDigestMockData`)를 그대로 돌려주는 얇은 어댑터.
/// 실 네트워크 연결은 API 스펙 확정 후 `LiveNewsroomDigestRepository`가 맡는다 —
/// 교체 지점은 `NewsroomDigestRepositoryFactory` 한 곳이고, 이 파일과 UI는 건드리지 않는다.
nonisolated struct MockNewsroomDigestRepository: NewsroomDigestRepositoryProtocol {
    let scenario: NewsroomDigestScenario

    init(scenario: NewsroomDigestScenario = .calmAllQuiet) {
        self.scenario = scenario
    }

    func fetchDigest(userAssetProfile: UserAssetProfile) async throws -> NewsroomDigest {
        try? await Task.sleep(nanoseconds: 350_000_000)

        switch scenario {
        case .calmAllQuiet:
            return NewsroomDigestMockData.calmAllQuiet
        case .calmMixed:
            return NewsroomDigestMockData.calmMixed
        case .alert:
            return NewsroomDigestMockData.alert
        case .loadFailure:
            throw URLError(.notConnectedToInternet)
        }
    }
}
