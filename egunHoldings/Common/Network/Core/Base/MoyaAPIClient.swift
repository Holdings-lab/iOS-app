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
            requestClosure: Self.requestClosure,
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

    /// 뉴스룸은 서버가 ML 피드와 종목 로고를 순서대로 준비할 수 있어 일반 API보다 오래 걸린다.
    /// 전역 기본값(15초)으로 정상 2xx 응답을 중간에 끊지 않도록 해당 경로에만 제한을 늘린다.
    private static let requestClosure: MoyaProvider<EndpointTarget>.RequestClosure = { endpoint, completion in
        do {
            var request = try endpoint.urlRequest()
            if let timeout = APIRequestTimeoutPolicy.timeout(for: request) {
                request.timeoutInterval = timeout
            }
            completion(.success(request))
        } catch {
            completion(.failure(.underlying(error, nil)))
        }
    }
}

/// 화면별로 서버 처리 시간이 크게 다른 요청만 별도 제한을 둔다.
/// URLSession의 전역 기본 제한을 바꾸지 않아 다른 화면의 실패 감지는 그대로 빠르게 유지된다.
nonisolated enum APIRequestTimeoutPolicy {
    static let newsroom: TimeInterval = 30
    static let brokerData: TimeInterval = 30

    static func timeout(for request: URLRequest) -> TimeInterval? {
        guard let path = request.url?.path else { return nil }
        if path == "/api/newsroom" || path.hasPrefix("/api/newsroom/") {
            return newsroom
        }
        if path == "/api/portfolio" || path == "/api/holdings" || path == "/api/daily-briefing" {
            return brokerData
        }
        return nil
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
