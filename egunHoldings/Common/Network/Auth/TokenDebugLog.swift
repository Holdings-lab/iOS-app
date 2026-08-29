import Foundation

/// 토큰 발급/갱신 흐름을 Xcode 콘솔에서 추적하기 위한 디버그 전용 로거.
/// DEBUG 빌드에서만 출력되며, "🔐 [Token" 으로 grep하면 관련 로그만 모아볼 수 있다.
nonisolated enum TokenDebugLog {
    static func log(_ message: @autoclosure () -> String) {
        #if DEBUG
        print("🔐 [Token \(timeFormatter.string(from: Date()))] \(message())")
        #endif
    }

    static func expiryDescription(for tokenStore: AuthTokenStore) -> String {
        guard tokenStore.currentAccessToken() != nil else {
            return "액세스 토큰 없음"
        }

        guard let expiresAt = tokenStore.currentExpiresAt() else {
            return "만료시각 정보 없음"
        }

        let remaining = Int(expiresAt.timeIntervalSinceNow)
        let clock = timeFormatter.string(from: expiresAt)

        if remaining <= 0 {
            return "만료됨 (만료시각 \(clock), \(-remaining)초 경과)"
        }

        return "만료까지 \(remaining)초 (만료시각 \(clock))"
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}
