import Foundation

/// 응답 디코딩 실패는 화면에 "불러오지 못했어요"로만 남아 원인을 되짚을 단서가 없다.
/// 어긋난 키 경로만 DEBUG 빌드 콘솔에 남긴다 — 응답 본문과 토큰은 기록하지 않는다
/// (`TokenDebugLoggerPlugin`이 지키는 것과 같은 원칙).
nonisolated enum NetworkDebugLog {
    static func logDecodingFailure(path: String, statusCode: Int, error: any Error) {
        #if DEBUG
        print("🧩 [Decode] \(path) → HTTP \(statusCode) 디코딩 실패: \(description(for: error))")
        #endif
    }

    static func description(for error: any Error) -> String {
        guard let decodingError = error as? DecodingError else { return "\(error)" }

        switch decodingError {
        case let .keyNotFound(key, context):
            return "키 없음 '\(key.stringValue)' at \(keyPath(context))"
        case let .valueNotFound(type, context):
            return "값 없음(\(type)) at \(keyPath(context))"
        case let .typeMismatch(type, context):
            return "타입 불일치(기대: \(type)) at \(keyPath(context))"
        case let .dataCorrupted(context):
            return "형식 오류 at \(keyPath(context)) — \(context.debugDescription)"
        @unknown default:
            return "\(decodingError)"
        }
    }

    private static func keyPath(_ context: DecodingError.Context) -> String {
        let path = context.codingPath.map(\.stringValue).joined(separator: ".")
        return path.isEmpty ? "<root>" : path
    }
}
