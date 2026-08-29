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
        guard
            request.response?.statusCode == 401,
            request.request?.value(forHTTPHeaderField: "Authorization") != nil
        else {
            completion(.doNotRetryWithError(error))
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
