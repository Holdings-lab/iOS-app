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
}

private struct SuccessfulEmptyResultClient: APIClient {
    nonisolated func request<T: Decodable>(_: Endpoint, as type: T.Type) async throws -> T {
        let data = Data(
            #"{"isSuccess":true,"code":"OK","message":"","result":null}"#.utf8
        )
        return try JSONDecoder().decode(type, from: data)
    }
}
