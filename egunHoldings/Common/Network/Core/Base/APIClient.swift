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
            return AppVocabulary.ErrorMessage.serverFallback
        case .invalidURL:
            return AppVocabulary.ErrorMessage.unknown
        case .invalidResponse:
            return AppVocabulary.ErrorMessage.serverFallback
        case .httpStatus, .apiFailure:
            return AppVocabulary.ErrorMessage.userFacing(for: self)
        case .emptyResult:
            return AppVocabulary.ErrorMessage.serverFallback
        case .decodingFailed:
            return AppVocabulary.ErrorMessage.serverFallback
        case .missingRefreshToken:
            return AppVocabulary.ErrorMessage.loginExpired
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
