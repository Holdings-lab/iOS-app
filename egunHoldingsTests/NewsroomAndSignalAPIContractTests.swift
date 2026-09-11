import Foundation
import Testing
@testable import egunHoldings

@MainActor
struct NewsroomAndSignalAPIContractTests {
    @Test("뉴스룸 로고와 기사 썸네일 URL을 도메인 모델에 보존한다")
    func mapsNewsroomImageURLs() throws {
        let briefing = try NetworkJSONCoding.makeDecoder().decode(
            APIResponse<NewsroomBriefingResponseDTO>.self,
            from: envelope(resultJSON: briefingJSON)
        ).result
        let detail = try NetworkJSONCoding.makeDecoder().decode(
            APIResponse<NewsroomTickerDetailResponseDTO>.self,
            from: envelope(resultJSON: detailJSON)
        ).result

        #expect(briefing?.toDomain().holdings.first?.logoURL?.absoluteString == "https://cdn.example.com/logos/005930.png")
        #expect(briefing?.toDomain().holdings.map(\.briefingType) == [.hero, .compact, .quiet])
        #expect(detail?.toDomain().stock.logoURL?.absoluteString == "https://cdn.example.com/logos/005930.png")
        #expect(detail?.toDomain().imageURL?.absoluteString == "https://cdn.example.com/news/hero.jpg")
        #expect(detail?.toDomain().sources.first?.thumbnailURL?.absoluteString == "https://cdn.example.com/news/1.jpg")
    }

    @Test("뉴스가 없는 보유 종목과 보유 자산 없음을 구분한다")
    func distinguishesNoRelatedNewsFromNoHoldings() {
        #expect(NewsroomDigestMockData.allQuiet.hasNoRelevantNews)
        #expect(!NewsroomDigestMockData.calmMixed.hasNoRelevantNews)
        #expect(!NewsroomDigestMockData.empty.hasNoRelevantNews)
    }

    @Test("뉴스룸 503 응답에 포함된 재시도 상태를 보존한다")
    func preservesNewsroomUnavailableState() async throws {
        let repository = LiveNewsroomDigestRepository(apiClient: NewsroomContractAPIClient(data: Data(#"{"isSuccess":false,"code":"NEWSROOM_UNAVAILABLE","message":"뉴스 소스 조회 중 오류가 발생했습니다.","result":{"header":{"title":"뉴스룸","subtitle":""},"holdings":[],"errorState":{"title":"뉴스를 불러오지 못했어요","summary":"잠시 후 다시 시도해 주세요.","buttonLabel":"다시 시도"}}}"#.utf8)))

        let briefing = try await repository.fetchBriefing()

        #expect(briefing.errorState?.title == "뉴스를 불러오지 못했어요")
        #expect(briefing.errorState?.buttonLabel == "다시 시도")
    }

    @Test("뉴스룸과 증권사 동기화 경로만 서버 처리 시간을 고려한 요청 제한을 사용한다")
    func usesLongerTimeoutOnlyForSlowServerPaths() {
        var newsroomRequest = URLRequest(url: URL(string: "https://holdings-lab.me/api/newsroom")!)
        newsroomRequest.timeoutInterval = 15
        let portfolioRequest = URLRequest(url: URL(string: "https://holdings-lab.me/api/portfolio")!)
        let holdingsRequest = URLRequest(url: URL(string: "https://holdings-lab.me/api/holdings")!)
        let briefingRequest = URLRequest(url: URL(string: "https://holdings-lab.me/api/daily-briefing")!)

        #expect(APIRequestTimeoutPolicy.timeout(for: newsroomRequest) == 30)
        #expect(APIRequestTimeoutPolicy.timeout(for: portfolioRequest) == 30)
        #expect(APIRequestTimeoutPolicy.timeout(for: holdingsRequest) == 30)
        #expect(APIRequestTimeoutPolicy.timeout(for: briefingRequest) == 30)
    }

    @Test("시그널 이벤트가 인증된 현재 경로를 사용한다")
    func fetchesEventsFromCurrentEndpoint() async throws {
        let queue = SignalContractRequestQueue(responses: [
            envelope(resultJSON: eventsJSON),
        ])
        let repository = LiveSignalRepository(
            userId: 1,
            apiClient: SignalContractAPIClient(queue: queue)
        )

        let events = try await repository.fetchEvents()
        let requests = await queue.recordedRequests()

        #expect(requests.map(\.path) == ["/api/events"])
        #expect(requests.first?.queryItems.map(\.name) == ["dateSegment", "category"])
        #expect(events.first?.id == 91)
        #expect(events.first?.title == "반도체 지원금 발표")
    }

    private var briefingJSON: String {
        #"{"header":{"title":"뉴스룸","subtitle":"보유 종목 브리핑"},"holdings":[{"ticker":"005930","name":"삼성전자","logoUrl":"https://cdn.example.com/logos/005930.png","weightPct":32.0,"briefingType":"Hero"},{"ticker":"NVDA","name":"NVIDIA","weightPct":12.0,"briefingType":"Compact"},{"ticker":"QQQ","name":"Invesco QQQ Trust","weightPct":35.0,"briefingType":"Quiet"}]}"#
    }

    private var detailJSON: String {
        #"{"stock":{"ticker":"005930","name":"삼성전자","logoUrl":"https://cdn.example.com/logos/005930.png"},"headline":"반도체 뉴스","imageUrl":"https://cdn.example.com/news/hero.jpg","sources":[{"title":"기사 제목","publisher":"뉴스","thumbnailUrl":"https://cdn.example.com/news/1.jpg"}]}"#
    }

    private var eventsJSON: String {
        #"{"items":[{"eventId":91,"title":"반도체 지원금 발표","tags":["반도체"],"relatedAssets":["SOXX"],"importanceStars":4}]}"#
    }

    private func envelope(resultJSON: String) -> Data {
        Data(#"{"isSuccess":true,"code":"SUCCESS-200","message":"OK","result":\#(resultJSON)}"#.utf8)
    }
}

private enum SignalContractError: Error {
    case missingResponse
}

private actor SignalContractRequestQueue {
    private var responses: [Data]
    private var requests: [Endpoint] = []

    init(responses: [Data]) {
        self.responses = responses
    }

    func nextResponse(for endpoint: Endpoint) throws -> Data {
        requests.append(endpoint)
        guard !responses.isEmpty else { throw SignalContractError.missingResponse }
        return responses.removeFirst()
    }

    func recordedRequests() -> [Endpoint] {
        requests
    }
}

private struct SignalContractAPIClient: APIClient {
    let queue: SignalContractRequestQueue

    nonisolated func request<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        let data = try await queue.nextResponse(for: endpoint)
        return try NetworkJSONCoding.makeDecoder().decode(type, from: data)
    }
}

private struct NewsroomContractAPIClient: APIClient {
    let data: Data

    nonisolated func request<T: Decodable>(_: Endpoint, as type: T.Type) async throws -> T {
        try NetworkJSONCoding.makeDecoder().decode(type, from: data)
    }
}
