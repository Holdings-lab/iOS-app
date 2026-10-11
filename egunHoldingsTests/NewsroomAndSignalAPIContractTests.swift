import Foundation
import Testing
@testable import egunHoldings

@MainActor
struct NewsroomAndSignalAPIContractTests {
    @Test("Notion 명세의 뉴스 제목·AI 결론·근거·뉴스 본문을 분리해 보존한다",
          arguments: ["Hero", "Compact"])
    func mapsDocumentedNewsroomContent(briefingType: String) async throws {
        let headline = "테크 대기업들의 AI 경쟁 심화"
        let prediction = "QQQ는 향후 15일간 횡보할 가능성이 있습니다."
        let reason = "AI 투자가 성장을 뒷받침합니다. 비용 상승은 수익성을 압박합니다."
        let content = "팔란티르 주가는 2.4% 상승했습니다. 가계 채무 연체는 증가했습니다."
        let listJSON = #"{"header":{"title":"뉴스룸","subtitle":"보유 종목 브리핑"},"holdings":[{"ticker":"QQQ","name":"Invesco QQQ Trust","weightPct":35,"briefingType":"\#(briefingType)","headline":"\#(headline)","summary":"\#(prediction)"}]}"#
        let listRepository = LiveNewsroomDigestRepository(
            apiClient: NewsroomContractAPIClient(data: envelope(resultJSON: listJSON))
        )
        let briefing = try await listRepository.fetchBriefing()
        #expect(briefing.holdings.first?.headline == headline)
        #expect(briefing.holdings.first?.summary == prediction)

        let detailJSON = #"{"stock":{"ticker":"QQQ","name":"Invesco QQQ Trust"},"headline":"\#(headline)","aiJudgement":{"title":"AI는 이렇게 판단했어요","headline":"\#(prediction)","disclaimer":"본 내용은 투자 판단의 근거가 아닙니다."},"summary":{"body":"\#(reason)","findings":["\#(content)"]}}"#
        let detailRepository = LiveNewsroomDigestRepository(
            apiClient: NewsroomContractAPIClient(data: envelope(resultJSON: detailJSON))
        )
        let detail = try await detailRepository.fetchDetail(ticker: "QQQ")
        #expect(detail.headline == headline)
        #expect(detail.aiJudgement?.titleText == "AI는 이렇게 판단했어요")
        #expect(detail.aiJudgement?.headline == prediction)
        #expect(detail.aiJudgement?.reason == reason)
        #expect(detail.aiJudgement?.disclaimerText == "본 내용은 투자 판단의 근거가 아닙니다.")
        #expect(detail.aiJudgement?.generatedAt == nil)
        #expect(detail.summaryBody == nil)
        #expect(detail.findings == [content])
    }

    @Test("daily.content는 문자열과 문자열 배열 모두에서 뉴스 본문으로 보존한다",
          arguments: [#""첫 뉴스. 둘째 뉴스.""#, #"["첫 뉴스. 둘째 뉴스."]"#])
    func decodesDailyContent(findingsJSON: String) throws {
        let json = #"{"stock":{"ticker":"QQQ","name":"QQQ"},"headline":"뉴스 제목","summary":{"findings":\#(findingsJSON)}}"#
        let detail = try JSONDecoder().decode(NewsroomTickerDetailResponseDTO.self, from: Data(json.utf8)).toDomain()
        #expect(detail.findings == ["첫 뉴스. 둘째 뉴스."])
    }

    @Test("AI alignment는 예측 지지 여부를 보존하고 캐시에서도 왕복한다",
          arguments: ["SUPPORTIVE", "MIXED", "CONTRADICTORY", "INSUFFICIENT"])
    func decodesDocumentedAlignment(rawValue: String) throws {
        let expected: [String: NewsroomAIAlignment] = [
            "SUPPORTIVE": .supportive, "MIXED": .mixed,
            "CONTRADICTORY": .contradictory, "INSUFFICIENT": .insufficient
        ]
        let json = #"{"headline":"예측 방향","alignment":"\#(rawValue)"}"#
        let judgement = try JSONDecoder().decode(NewsroomAIJudgementDTO.self, from: Data(json.utf8)).toDomain()
        #expect(judgement.alignment == expected[rawValue])
        let encoded = try JSONEncoder().encode(judgement)
        #expect(try JSONDecoder().decode(NewsroomAIJudgement.self, from: encoded) == judgement)
        #expect(NewsroomAIAlignment(rawValue: "UNKNOWN") == nil)
        #expect(NewsroomAIAlignment(rawValue: "BULLISH") == .positive)
        #expect(NewsroomAIAlignment(rawValue: "BEARISH") == .negative)
    }

    @Test("문자열 AI 판단의 근거는 summary.body에서 읽고 본문 중복을 제거한다")
    func usesSummaryBodyAsLegacyAIReason() async throws {
        let reason = "애플의 아이폰 주문 감소는 하락 요인입니다. AI 인프라 투자 확대는 상승 요인으로 작용합니다."
        let json = #"{"stock":{"ticker":"QQQ","name":"QQQ"},"headline":"기술주 뉴스","aiJudgement":"기술주 상승·하락 요인이 상충합니다.","summary":{"body":"\#(reason)","findings":["금리 상승"]}}"#
        let repository = LiveNewsroomDigestRepository(
            apiClient: NewsroomContractAPIClient(data: envelope(resultJSON: json))
        )
        let detail = try await repository.fetchDetail(ticker: "QQQ")

        #expect(detail.aiJudgement?.headline == "기술주 상승·하락 요인이 상충합니다.")
        #expect(detail.aiJudgement?.reason == reason)
        #expect(detail.aiJudgement?.hasReason == true)
        #expect(detail.summaryBody == nil)
        #expect(detail.findings == ["금리 상승"])
    }

    @Test("AI 카드의 근거는 이전 reason보다 summary.body를 우선한다",
          arguments: [nil, "", "  \n", "별도의 AI 근거입니다."] as [String?])
    func resolvesAIReason(reason: String?) throws {
        var judgement: [String: Any] = ["headline": "예측 방향"]
        if let reason { judgement["reason"] = reason }
        let data = try JSONSerialization.data(withJSONObject: [
            "stock": ["ticker": "QQQ", "name": "QQQ"], "headline": "기사 제목",
            "aiJudgement": judgement, "summary": ["body": "서버가 보내 준 근거입니다."]
        ])
        let detail = try JSONDecoder().decode(NewsroomTickerDetailResponseDTO.self, from: data).toDomain()
        #expect(detail.aiJudgement?.headline == "예측 방향")
        #expect(detail.aiJudgement?.reason == "서버가 보내 준 근거입니다.")
        #expect(detail.summaryBody == nil)
    }

    @Test("summary.body가 없거나 비면 AI 카드에서 이전 reason을 사용한다",
          arguments: [nil, "", "  \n"] as [String?])
    func preservesLegacyReasonWhenSummaryBodyIsMissing(body: String?) throws {
        var summary: [String: Any] = ["findings": ["뉴스 요약"]]
        if let body { summary["body"] = body }
        let data = try JSONSerialization.data(withJSONObject: [
            "stock": ["ticker": "QQQ", "name": "QQQ"], "headline": "뉴스 제목",
            "aiJudgement": ["headline": "AI 예측 문장", "reason": "이전 계약의 근거"],
            "summary": summary
        ])
        let detail = try JSONDecoder().decode(NewsroomTickerDetailResponseDTO.self, from: data).toDomain()
        #expect(detail.aiJudgement?.headline == "AI 예측 문장")
        #expect(detail.aiJudgement?.reason == "이전 계약의 근거")
        #expect(detail.summaryBody == nil)
        #expect(detail.findings == ["뉴스 요약"])
    }

    @Test("AI 판단이나 근거가 없으면 원래 본문과 결론을 보존한다")
    func preservesDetailsWithoutAIReason() throws {
        let withoutAI = Data(#"{"stock":{"ticker":"QQQ","name":"QQQ"},"headline":"기사","summary":{"body":"뉴스 본문"}}"#.utf8)
        let detail = try JSONDecoder().decode(NewsroomTickerDetailResponseDTO.self, from: withoutAI).toDomain()
        #expect(detail.aiJudgement == nil)
        #expect(detail.summaryBody == "뉴스 본문")

        let withoutSummary = Data(#"{"stock":{"ticker":"QQQ","name":"QQQ"},"headline":"기사","aiJudgement":"AI 결론"}"#.utf8)
        let headlineOnly = try JSONDecoder().decode(NewsroomTickerDetailResponseDTO.self, from: withoutSummary).toDomain()
        #expect(headlineOnly.aiJudgement?.headline == "AI 결론")
        #expect(headlineOnly.aiJudgement?.hasReason == false)
    }

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
