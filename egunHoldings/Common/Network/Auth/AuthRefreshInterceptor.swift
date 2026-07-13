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

    func adapt(
        _ urlRequest: URLRequest,
        for session: Alamofire.Session,
        completion: @escaping @Sendable (Result<URLRequest, any Error>) -> Void
    ) {
        completion(.success(urlRequest))
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

        Task {
            do {
                let tokenPayload = try await coordinator.refresh(using: refresher)
                tokenStore.updateTokens(tokenPayload)
                completion(.retry)
            } catch {
                tokenStore.clearTokens()
                completion(.doNotRetryWithError(error))
            }
        }
    }
}

actor TokenRefreshCoordinator {
    private var refreshTask: Task<AuthTokenPayload, Error>?

    func refresh(using refresher: AccessTokenRefreshing) async throws -> AuthTokenPayload {
        if let refreshTask {
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
