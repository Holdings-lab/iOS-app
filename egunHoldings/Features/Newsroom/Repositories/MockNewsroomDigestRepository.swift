import Foundation

/// UI/UX 검증용 시나리오. macroIssue/오프라인 캐시/생성중 폴링은 새 서버 계약에 없어졌으므로
/// 이제 목록 구성(혼재/전체 조용/빈 상태)과 실패만 다룬다.
enum NewsroomDigestScenario: String, CaseIterable, Identifiable {
    case mixed
    case allQuiet
    case empty
    case loadFailure

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mixed: return "일부 종목 뉴스"
        case .allQuiet: return "전 종목 조용"
        case .empty: return "보유 종목 없음"
        case .loadFailure: return "네트워크 에러"
        }
    }
}

/// 픽스처(`NewsroomDigestMockData`)를 그대로 돌려주는 얇은 어댑터.
/// 실 연결 교체 지점은 `NewsroomDigestRepositoryFactory` 한 곳 — 이 파일과 UI는 건드리지 않는다.
nonisolated struct MockNewsroomDigestRepository: NewsroomDigestRepositoryProtocol {
    let scenario: NewsroomDigestScenario

    init(scenario: NewsroomDigestScenario = .mixed) {
        self.scenario = scenario
    }

    func fetchBriefing(briefingDate: String? = nil) async throws -> NewsroomBriefing {
        try? await Task.sleep(nanoseconds: 350_000_000)

        switch scenario {
        case .mixed:
            return NewsroomDigestMockData.calmMixed
        case .allQuiet:
            return NewsroomDigestMockData.allQuiet
        case .empty:
            return NewsroomDigestMockData.empty
        case .loadFailure:
            throw URLError(.notConnectedToInternet)
        }
    }

    func fetchDetail(ticker: String, briefingDate: String? = nil) async throws -> NewsroomTickerDetail {
        try? await Task.sleep(nanoseconds: 250_000_000)

        guard let detail = NewsroomDigestMockData.detail(for: ticker) else {
            throw URLError(.badServerResponse)
        }
        return detail
    }
}
