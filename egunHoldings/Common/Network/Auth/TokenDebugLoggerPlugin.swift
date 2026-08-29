import Foundation
@preconcurrency import Moya

/// 모든 네트워크 응답을 받은 직후, 현재 액세스 토큰의 만료 상태를 Xcode 콘솔에 출력한다.
/// 요청/응답 바디와 토큰 값은 기록하지 않고, 토큰 수명 추적에만 집중한다.
nonisolated struct TokenDebugLoggerPlugin: PluginType {
    private let tokenStore: AuthTokenStore

    init(tokenStore: AuthTokenStore) {
        self.tokenStore = tokenStore
    }

    func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {
        let path = target.path
        let statusText: String

        switch result {
        case .success(let response):
            statusText = "HTTP \(response.statusCode)"
        case .failure(let error):
            statusText = "실패(\(error.errorDescription ?? "알 수 없는 오류"))"
        }

        TokenDebugLog.log("\(path) → \(statusText) | 액세스 토큰 \(TokenDebugLog.expiryDescription(for: tokenStore))")
    }
}
