import Foundation
@preconcurrency import Moya
@preconcurrency import Alamofire

nonisolated final class MoyaAPIClient: APIClient, @unchecked Sendable {
    private let provider: MoyaProvider<EndpointTarget>

    init(
        session: Alamofire.Session,
        plugins: [PluginType] = []
    ) {
        provider = MoyaProvider<EndpointTarget>(
            session: session,
            plugins: plugins
        )
    }

    nonisolated func request<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        let target = EndpointTarget(endpoint: endpoint)

        let response = try await withCheckedThrowingContinuation { continuation in
            provider.request(target) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: Self.mapMoyaError(error))
                }
            }
        }

        do {
            let decoder = NetworkJSONCoding.makeDecoder()
            return try decoder.decode(T.self, from: response.data)
        } catch {
            throw NetworkError.decodingFailed
        }
    }

    private static func mapMoyaError(_ error: MoyaError) -> Error {
        switch error {
        case .statusCode(let response):
            if let apiError = try? NetworkJSONCoding.makeDecoder().decode(APIResponse<EmptyAPIResult>.self, from: response.data) {
                return NetworkError.apiFailure(
                    statusCode: response.statusCode,
                    code: apiError.code,
                    message: apiError.message
                )
            }

            return NetworkError.httpStatus(response.statusCode)
        case .objectMapping, .encodableMapping:
            return NetworkError.decodingFailed
        default:
            return error
        }
    }
}
