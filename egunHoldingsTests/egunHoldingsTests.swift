import Alamofire
import Foundation
import Testing
@testable import egunHoldings

struct egunHoldingsTests {
    @Test("성공한 빈 API 응답을 강제 캐스팅 없이 처리한다")
    func successfulEmptyAPIResponse() async throws {
        let client = SuccessfulEmptyResultClient()

        let _: EmptyAPIResult = try await client.requestResult(
            BackendEndpoint.health(),
            as: EmptyAPIResult.self
        )
    }

    @Test("디코딩 실패 로그가 어긋난 키 경로를 짚어 준다")
    func describesDecodingFailure() throws {
        struct Detail: Decodable { let stock: Stock; struct Stock: Decodable { let ticker: String } }
        do {
            _ = try JSONDecoder().decode(Detail.self, from: Data(#"{"stock":{}}"#.utf8))
            Issue.record("디코딩이 실패해야 한다")
        } catch {
            let described = NetworkDebugLog.description(for: error)
            #expect(described.contains("ticker"))
            #expect(described.contains("stock"))
        }
        #expect(NetworkDebugLog.description(for: URLError(.timedOut)).isEmpty == false)
    }

    @Test("끊긴 keep-alive 커넥션만 재시도 대상으로 본다")
    func retriesOnlyLostConnections() {
        let lost = URLError(.networkConnectionLost)
        #expect(AuthRefreshInterceptor.isRetriableTransportError(lost))
        #expect(AuthRefreshInterceptor.isRetriableTransportError(AFError.sessionTaskFailed(error: lost)))

        // 다시 보내도 결과가 같거나, 우리가 의도적으로 끊은 요청은 재시도하지 않는다.
        for code: URLError.Code in [.notConnectedToInternet, .timedOut, .cancelled, .cannotFindHost] {
            #expect(!AuthRefreshInterceptor.isRetriableTransportError(URLError(code)))
        }
        #expect(!AuthRefreshInterceptor.isRetriableTransportError(NetworkError.decodingFailed))
    }
}

nonisolated private struct SuccessfulEmptyResultClient: APIClient {
    nonisolated func request<T: Decodable>(_: Endpoint, as type: T.Type) async throws -> T {
        let data = Data(
            #"{"isSuccess":true,"code":"OK","message":"","result":null}"#.utf8
        )
        return try JSONDecoder().decode(type, from: data)
    }
}
