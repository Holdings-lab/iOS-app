import Foundation

/// 뉴스룸 실서버 리포지토리.
/// 계약: `NewsroomController`/`NewsroomService` (api-server). 서버가 매 요청마다 동기적으로
/// 계산해서 응답하므로 (예전 다이제스트처럼 백그라운드 생성 후 폴링하는 상태가 없다) 재시도/대기 로직이 없다.
nonisolated struct LiveNewsroomDigestRepository: NewsroomDigestRepositoryProtocol {
    private let apiClient: APIClient
    private let quotes = NewsroomMarketQuoteRepository()
    private let sources: NewsroomSourceFeedRepository

    init(apiClient: APIClient = APIClientFactory.makeDefault()) {
        self.apiClient = apiClient
        self.sources = NewsroomSourceFeedRepository(apiClient: apiClient)
    }

    func fetchBriefing(briefingDate: String? = nil) async throws -> NewsroomBriefing {
        let response = try await apiClient.requestEnvelope(
            BackendEndpoint.newsroom(briefingDate: briefingDate),
            as: NewsroomBriefingResponseDTO.self
        )

        // 서버는 ML 피드 장애 시에도 errorState를 result에 담아 503으로 응답한다.
        // requestResult를 쓰면 isSuccess=false를 먼저 던져 이 상태를 잃으므로, 화면에서
        // 재시도 안내를 보여줄 수 있도록 result가 있으면 보존한다.
        if let result = response.result {
            return result.toDomain()
        }

        throw NetworkError.apiFailure(
            statusCode: nil,
            code: response.code,
            message: response.message
        )
    }

    func fetchDetail(ticker: String, briefingDate: String? = nil) async throws -> NewsroomTickerDetail {
        let response = try await apiClient.requestResult(
            BackendEndpoint.newsroomDetail(ticker: ticker, briefingDate: briefingDate),
            as: NewsroomTickerDetailResponseDTO.self
        )
        return response.toDomain()
    }

    func fetchQuote(ticker: String) async -> NewsroomMarketQuote? {
        await quotes.fetch(ticker: ticker)
    }

    func fetchSources(ticker: String) async throws -> [NewsroomSourceItem] {
        try await sources.fetchSources(ticker: ticker)
    }
}
