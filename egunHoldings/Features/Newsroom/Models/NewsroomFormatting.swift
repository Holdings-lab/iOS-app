import Foundation
import SwiftUI

/// 목록 카드는 요약 전문 대신 첫 문장만 보여준다(전문은 상세 화면에서 읽는다).
/// 마침표를 직접 찾으면 "7.30%"나 "U.S." 같은 값에서 잘리므로 ICU 문장 경계를 쓴다.
nonisolated enum NewsroomSummaryText {
    static func firstSentence(of summary: String) -> String {
        let trimmed = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        var first: String?
        trimmed.enumerateSubstrings(in: trimmed.startIndex..<trimmed.endIndex, options: .bySentences) { substring, _, _, stop in
            guard let sentence = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !sentence.isEmpty else { return }
            first = sentence
            stop = true
        }
        return first ?? trimmed
    }
}

nonisolated enum NewsroomPercentFormat {
    static func signed(_ value: Double) -> String {
        let sign = value > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", value))%"
    }

    static func weight(_ value: Double) -> String {
        guard value.isFinite else { return "—" }
        return value.rounded() == value ? String(format: "%.0f", value) : String(format: "%.2f", value)
    }

    static func color(for value: Double) -> Color {
        if value > 0 { return Color.emerald }
        if value < 0 { return Color.policyCoral }
        return Color.textPrimary
    }
}

