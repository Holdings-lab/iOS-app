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
        guard
            urlRequest.value(forHTTPHeaderField: "Authorization") != nil,
            tokenStore.isAccessTokenExpiring()
        else {
            completion(.success(urlRequest))
            return
        }

        TokenDebugLog.log("선제적 갱신 트리거 → \(urlRequest.url?.path ?? "?") 요청 전 만료 임박 감지 (\(TokenDebugLog.expiryDescription(for: tokenStore)))")

        Task {
            do {
                let tokenPayload = try await coordinator.refresh(using: refresher)
                tokenStore.updateTokens(tokenPayload)

                var adaptedRequest = urlRequest
                adaptedRequest.setValue("Bearer \(tokenPayload.accessToken)", forHTTPHeaderField: "Authorization")
                completion(.success(adaptedRequest))
            } catch {
                TokenDebugLog.log("선제적 갱신 실패 → 기존 토큰으로 요청을 계속 진행합니다: \(error)")
                completion(.success(urlRequest))
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

        TokenDebugLog.log("401 응답 수신 → \(request.request?.url?.path ?? "?") 리액티브 갱신 시도")

        Task {
            do {
                let tokenPayload = try await coordinator.refresh(using: refresher)
                tokenStore.updateTokens(tokenPayload)
                TokenDebugLog.log("리액티브 갱신 성공 → 요청 재시도")
                completion(.retry)
            } catch {
                TokenDebugLog.log("리액티브 갱신 실패 → 세션 종료 처리(재로그인 필요): \(error)")
                tokenStore.clearTokens()
                completion(.doNotRetryWithError(error))
            }
        }
    }
}

extension AuthRefreshInterceptor {
    static let transientRetryLimit = 1

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
    private var refreshTask: Task<AuthTokenPayload, Error>?

    func refresh(using refresher: AccessTokenRefreshing) async throws -> AuthTokenPayload {
        if let refreshTask {
            TokenDebugLog.log("이미 진행 중인 갱신 요청에 합류합니다 (중복 호출 방지)")
            return try await refreshTask.value
        }

        let task = Task {
            try await refresher.refreshAccessToken()
        }
        refreshTask = task

        defer {
            refreshTask = nil
        }

        return try await task.value
    }
}
