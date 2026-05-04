import Foundation

protocol APIClient: Sendable {
    nonisolated func request<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T
}

nonisolated enum NetworkError: Error, Sendable {
    case notImplemented
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case apiFailure(statusCode: Int?, code: String, message: String)
    case emptyResult(code: String, message: String)
    case decodingFailed
    case missingRefreshToken
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "아직 구현되지 않은 네트워크 요청입니다."
        case .invalidURL:
            return "요청 주소가 올바르지 않습니다."
        case .invalidResponse:
            return "서버 응답이 올바르지 않습니다."
        case .httpStatus(let statusCode):
            return "서버 응답 상태 코드가 올바르지 않습니다. 상태 코드: \(statusCode)"
        case .apiFailure(_, _, let message):
            return message
        case .emptyResult:
            return "응답 데이터가 비어 있습니다."
        case .decodingFailed:
            return "응답 데이터를 해석하지 못했습니다."
        case .missingRefreshToken:
            return "리프레시 토큰이 없습니다."
        }
    }
}

extension APIClient {
    nonisolated func requestEnvelope<T: Decodable>(
        _ endpoint: Endpoint,
        as type: T.Type
    ) async throws -> APIResponse<T> {
        try await request(endpoint, as: APIResponse<T>.self)
    }

    nonisolated func requestResult<T: Decodable>(
        _ endpoint: Endpoint,
        as type: T.Type
    ) async throws -> T {
        let response = try await requestEnvelope(endpoint, as: type)

        guard response.isSuccess else {
            throw NetworkError.apiFailure(
                statusCode: nil,
                code: response.code,
                message: response.message
            )
        }

        if let result = response.result {
            return result
        }

        if T.self == EmptyAPIResult.self {
            return EmptyAPIResult() as! T
        }

        throw NetworkError.emptyResult(
            code: response.code,
            message: response.message
        )
    }
}

nonisolated struct StubAPIClient: APIClient {
    nonisolated func request<T: Decodable>(_: Endpoint, as _: T.Type) async throws -> T {
        throw NetworkError.notImplemented
    }
}
