import Foundation
@preconcurrency import Alamofire

nonisolated final class AuthRefreshInterceptor: RequestInterceptor {
    private let tokenStore: AuthTokenStore
    private let refresher: AccessTokenRefreshing
    private let coordinator = TokenRefreshCoordinator()

    init(
        tokenStore: AuthTokenStore,
        refresher: AccessTokenRefreshing
    ) {
        self.tokenStore = tokenStore
        self.refresher = refresher
    }

    /// 요청을 실제로 내보내기 직전, 이미 Authorization 헤더가 붙어있는(=인증이 필요한) 요청인데
    /// 로컬에 기록된 만료시각이 임박/경과했다면 서버의 401을 기다리지 않고 선제적으로 갱신한다.
    /// 선제적 갱신이 실패해도(예: 일시적 네트워크 오류) 토큰은 지우지 않고 기존 토큰으로 그냥 진행한다 —
    /// 진짜 만료/폐기 여부는 서버가 401로 돌려줄 때 `retry`에서 확정적으로 처리한다.
    func adapt(
        _ urlRequest: URLRequest,
        for session: Alamofire.Session,
        completion: @escaping @Sendable (Result<URLRequest, any Error>) -> Void
    ) {
        guard urlRequest.value(forHTTPHeaderField: "Authorization") != nil else {
            completion(.success(urlRequest))
            return
        }
        guard let accessToken = tokenStore.currentAccessToken(), !accessToken.isEmpty else {
            completion(.failure(NetworkError.missingRefreshToken))
            return
        }
        // Alamofire 재시도는 원래 URLRequest를 재사용하므로 최신 토큰을 매번 다시 붙인다.
        var latestRequest = urlRequest
        latestRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        guard tokenStore.isAccessTokenExpiring() else {
            completion(.success(latestRequest))
            return
        }
        let request = latestRequest
        Task {
            do {
                _ = try await coordinator.refresh(using: refresher, token: accessToken, store: tokenStore)
                completion(.success(Self.withCurrentToken(request, store: tokenStore)))
            } catch {
                // 일시적인 지연/서버 오류는 로그인 세션을 삭제하지 않는다.
                completion(.success(Self.withCurrentToken(request, store: tokenStore)))
            }
        }
    }

    func retry(
        _ request: Alamofire.Request,
        for session: Alamofire.Session,
        dueTo error: any Error,
        completion: @escaping @Sendable (RetryResult) -> Void
    ) {
        // 앱이 한동안 유휴 상태였다면 서버가 이미 닫은 keep-alive 커넥션을 재사용하게 되고,
        // 그 뒤 첫 요청만 -1005로 끊긴다(응답 자체가 없어 401 재시도 경로에도 걸리지 않는다).
        // 새 커넥션으로 다시 보내면 그대로 성공하므로 부작용이 없는 GET만 한 번 재시도한다.
        if request.retryCount < Self.transientRetryLimit,
           request.request?.httpMethod == "GET",
           Self.isRetriableTransportError(error) {
            TokenDebugLog.log("연결 끊김 감지 → \(request.request?.url?.path ?? "?") 새 커넥션으로 1회 재시도")
            completion(.retry)
            return
        }

        guard
            request.response?.statusCode == 401,
            request.request?.value(forHTTPHeaderField: "Authorization") != nil
        else {
            completion(.doNotRetry)
            return
        }

        // 같은 요청에서 401 갱신을 반복하면 영원히 끝나지 않을 수 있다.
        guard request.retryCount < Self.authenticationRetryLimit else {
            completion(.doNotRetry)
            return
        }
        guard let currentToken = tokenStore.currentAccessToken(), !currentToken.isEmpty else {
            completion(.doNotRetry)
            return
        }
        if request.request?.value(forHTTPHeaderField: "Authorization") != "Bearer \(currentToken)" {
            // 다른 요청이 이미 갱신했거나 새 로그인 세션이 시작되었다.
            completion(.retry)
            return
        }
        Task {
            do {
                _ = try await coordinator.refresh(using: refresher, token: currentToken, store: tokenStore)
                completion(.retry)
            } catch {
                if tokenStore.currentAccessToken() == currentToken,
                   Self.invalidatesSession(error) {
                    tokenStore.clearTokens()
                }
                completion(.doNotRetryWithError(error))
            }
        }
    }

    private static func withCurrentToken(_ request: URLRequest, store: AuthTokenStore) -> URLRequest {
        var request = request
        let token = store.currentAccessToken().map { "Bearer \($0)" }
        request.setValue(token, forHTTPHeaderField: "Authorization")
        return request
    }

}

extension AuthRefreshInterceptor {
    static let transientRetryLimit = 1
    static let authenticationRetryLimit = 1

    static func invalidatesSession(_ error: any Error) -> Bool {
        if let error = error as? AFError, let code = error.responseCode {
            return code == 401 || code == 403
        }
        switch error as? NetworkError {
        case .missingRefreshToken: return true
        case .httpStatus(let code), .apiFailure(let code?, _, _): return code == 401 || code == 403
        default: return false
        }
    }

    /// 재시도해도 안전하고, 재시도하면 실제로 달라지는 전송 계층 오류만 고른다.
    /// 연결 없음/타임아웃처럼 다시 보내도 같은 결과인 오류는 호출자에게 그대로 전달한다.
    static func isRetriableTransportError(_ error: any Error) -> Bool {
        let underlying = (error as? AFError)?.underlyingError ?? error
        guard let urlError = underlying as? URLError else { return false }
        return urlError.code == .networkConnectionLost
    }
}

/// 동시에 여러 요청이 401을 받거나 만료를 감지해도 리프레시 네트워크 호출은 단 한 번만 나가도록
/// 직렬화한다(그렇지 않으면 리프레시 토큰이 회전 방식이라 두 번째 호출이 이미 폐기된 토큰으로 실패한다).
actor TokenRefreshCoordinator {
    private var refreshTask: (token: String, task: Task<AuthTokenPayload, Error>)?

    func refresh(using refresher: AccessTokenRefreshing, token: String, store: AuthTokenStore) async throws -> AuthTokenPayload {
        // 401 처리 Task가 실행되기 전에 다른 요청의 갱신이 이미 끝났을 수 있다.
        // 완료된 갱신을 다시 시작하면 회전된 리프레시 토큰을 불필요하게 재사용한다.
        guard let currentToken = store.currentAccessToken() else {
            throw NetworkError.missingRefreshToken
        }
        if currentToken != token {
            return AuthTokenPayload(accessToken: currentToken, refreshToken: store.currentRefreshToken(),
                                    expiresAt: store.currentExpiresAt() ?? .distantPast)
        }
        if let refreshTask, refreshTask.token == token {
            TokenDebugLog.log("이미 진행 중인 갱신 요청에 합류합니다 (중복 호출 방지)")
            return try await refreshTask.task.value
        }

        let task = Task {
            let payload = try await refresher.refreshAccessToken()
            // 합류한 호출자가 깨어나기 전에 한 번 저장해 늦은 401도 새 토큰을 보게 한다.
            if store.currentAccessToken() == token { store.updateTokens(payload) }
            return payload
        }
        refreshTask = (token, task)

        defer {
            if refreshTask?.token == token { refreshTask = nil }
        }

        return try await task.value
    }
}
