import Foundation

/// Live 리포지토리가 서버 응답을 얻지 못해 Mock 데이터로 대체했을 때 남기는 디버그 전용 로거.
///
/// 서버 API LIST에 아직 등재되지 않은 엔드포인트가 여럿 있고(goal / holdings / holdings-news /
/// portfolio·rebalancing / signals), 이들의 폴백은 화면상 "정상 동작"과 구분되지 않는다.
/// 실서버 연동 여부를 눈으로 확인할 수 없으면 QA에서 영영 잡히지 않으므로, 폴백이 발생한
/// 지점과 원인을 명시적으로 남긴다.
///
/// DEBUG 빌드에서만 출력되며, "🧪 [Fallback" 으로 grep하면 관련 로그만 모아볼 수 있다.
nonisolated enum APIFallbackLog {
    /// - Parameters:
    ///   - endpoint: 실패한 API를 식별하는 짧은 이름 (예: `"GET /api/users/{id}/goal"`).
    ///   - error: 폴백을 유발한 오류.
    static func log(_ endpoint: String, error: some Error) {
        #if DEBUG
        print("🧪 [Fallback \(timeFormatter.string(from: Date()))] \(endpoint) → Mock 폴백: \(error)")
        #endif
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}
