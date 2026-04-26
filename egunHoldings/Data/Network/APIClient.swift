import Foundation

protocol APIClient: Sendable {
    nonisolated func request<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T
}

nonisolated enum NetworkError: Error, Sendable {
    case notImplemented
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed
    case missingRefreshToken
}

nonisolated struct StubAPIClient: APIClient {
    nonisolated func request<T: Decodable>(_: Endpoint, as _: T.Type) async throws -> T {
        throw NetworkError.notImplemented
    }
}
