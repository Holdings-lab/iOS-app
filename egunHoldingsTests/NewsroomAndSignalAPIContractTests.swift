import Foundation
import Testing
@testable import egunHoldings

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
        #expect(detail?.toDomain().stock.logoURL?.absoluteString == "https://cdn.example.com/logos/005930.png")
        #expect(detail?.toDomain().sources.first?.thumbnailURL?.absoluteString == "https://cdn.example.com/news/1.jpg")
    }

    @Test("시그널 요약과 카드가 현재 홈 시그널 경로를 사용한다")
    func fetchesSignalsFromHomeSecondaryEndpoint() async throws {
        let queue = SignalContractRequestQueue(responses: [
            envelope(resultJSON: secondarySignalsJSON),
            envelope(resultJSON: secondarySignalsJSON),
        ])
        let repository = LiveSignalRepository(apiClient: SignalContractAPIClient(queue: queue))

        let signals = try await repository.fetchThemeSignals()
        let cards = try await repository.fetchSignalCards(theme: .semiconductor)
        let requests = await queue.recordedRequests()

        #expect(requests.map(\.path) == ["/api/home/signals/secondary", "/api/home/signals/secondary"])
        #expect(signals.count == 1)
        #expect(signals.first?.theme == .semiconductor)
        #expect(signals.first?.myExposurePercent == 32)
        #expect(cards.count == 1)
        #expect(cards.first?.description == "AI 반도체 수요 변화에 대비해 비중을 점검하세요.")
    }

    private var briefingJSON: String {
        #"{"header":{"title":"뉴스룸","subtitle":"보유 종목 브리핑"},"holdings":[{"ticker":"005930","name":"삼성전자","logoUrl":"https://cdn.example.com/logos/005930.png","weightPct":32.0,"briefingType":"Hero"}]}"#
    }

    private var detailJSON: String {
        #"{"stock":{"ticker":"005930","name":"삼성전자","logoUrl":"https://cdn.example.com/logos/005930.png"},"headline":"반도체 뉴스","sources":[{"title":"기사 제목","publisher":"뉴스","thumbnailUrl":"https://cdn.example.com/news/1.jpg"}]}"#
    }

    private var secondarySignalsJSON: String {
        #"[{"title":"반도체","shortJudgement":"점검","exposurePercent":32,"oneLineReason":"AI 반도체 수요 변화에 대비해 비중을 점검하세요."}]"#
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
