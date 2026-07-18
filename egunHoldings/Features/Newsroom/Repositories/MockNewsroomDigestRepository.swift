import Foundation

/// UI/UX 검증용 시나리오. 화면 상태를 전부 커버한다 (Mock 레퍼런스 기준).
/// 가장 자주 보이는 상태는 `calmAllQuiet`다.
enum NewsroomDigestScenario: String, CaseIterable, Identifiable {
    /// A. calm + 전 종목 조용 (quietDays 각기 다름) — 기본 상태
    case calmAllQuiet
    /// B. calm + 일부 종목만 뉴스 (히어로/컴팩트/조용 혼재)
    case calmMixed
    /// C. 두 개 이상 보유 종목에 겹친 공통 이슈 포함
    case alert
    /// 이전 캐시를 오프라인 표기와 함께 보여주는 상태.
    case cachedOffline
    /// 첫 자산 등록 직후 온디맨드 다이제스트를 만드는 상태.
    case firstGeneration
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
            return "포트폴리오 공통 이슈"
        case .cachedOffline:
            return "오프라인 캐시"
        case .firstGeneration:
            return "첫 브리핑 생성"
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

    var showsFirstGenerationState: Bool {
        scenario == .firstGeneration
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
        case .cachedOffline:
            return NewsroomDigestMockData.cachedOffline
        case .firstGeneration:
            return NewsroomDigestMockData.calmMixed
        case .loadFailure:
            throw URLError(.notConnectedToInternet)
        }
    }
}
