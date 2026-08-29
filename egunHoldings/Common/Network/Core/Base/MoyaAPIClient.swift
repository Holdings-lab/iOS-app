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
        let cancellationHandle = RequestCancellationHandle()

        let response = try await withTaskCancellationHandler {
            return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Moya.Response, Error>) in
                let request = provider.request(target) { result in
                    if cancellationHandle.isCancelled {
                        continuation.resume(throwing: CancellationError())
                        return
                    }

                    switch result {
                    case .success(let response):
                        continuation.resume(returning: response)
                    case .failure(let error):
                        continuation.resume(throwing: Self.mapMoyaError(error))
                    }
                }
                cancellationHandle.set(request)
            }
        } onCancel: {
            cancellationHandle.cancel()
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

/// Moya의 콜백 기반 취소 핸들을 Swift 동시성 취소와 연결한다.
/// 취소가 요청 생성보다 먼저 도착해도, 뒤늦게 등록된 요청을 바로 취소한다.
private nonisolated final class RequestCancellationHandle: @unchecked Sendable {
    private let lock = NSLock()
    private var request: Cancellable?
    private var cancelled = false

    var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }

    func set(_ request: Cancellable) {
        lock.lock()
        if cancelled {
            lock.unlock()
            request.cancel()
            return
        }
        self.request = request
        lock.unlock()
    }

    func cancel() {
        lock.lock()
        cancelled = true
        let request = request
        lock.unlock()
        request?.cancel()
    }
}
