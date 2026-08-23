import Foundation

/// 뉴스룸 실서버 리포지토리.
/// 계약: `NewsroomController`/`NewsroomService` (api-server). 서버가 매 요청마다 동기적으로
/// 계산해서 응답하므로 (예전 다이제스트처럼 백그라운드 생성 후 폴링하는 상태가 없다) 재시도/대기 로직이 없다.
nonisolated struct LiveNewsroomDigestRepository: NewsroomDigestRepositoryProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClientFactory.makeDefault()) {
        self.apiClient = apiClient
    }

    func fetchBriefing(briefingDate: String? = nil) async throws -> NewsroomBriefing {
        let response = try await apiClient.requestResult(
            BackendEndpoint.newsroom(briefingDate: briefingDate),
            as: NewsroomBriefingResponseDTO.self
        )
        return response.toDomain()
    }

    func fetchDetail(ticker: String, briefingDate: String? = nil) async throws -> NewsroomTickerDetail {
        let response = try await apiClient.requestResult(
            BackendEndpoint.newsroomDetail(ticker: ticker, briefingDate: briefingDate),
            as: NewsroomTickerDetailResponseDTO.self
        )
        return response.toDomain()
    }
}
