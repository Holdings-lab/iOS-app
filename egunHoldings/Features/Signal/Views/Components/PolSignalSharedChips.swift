import SwiftUI

struct PolSignalReaderKeywordChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.pretendard(12, weight: .semibold, relativeTo: .caption))
            .foregroundStyle(PSColor.Reader.chipText)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(PSColor.Reader.chipBg, in: Capsule(style: .continuous))
    }
}

/// 초보자용 상태 배지 (지켜봐요 / 조심하세요 / 대응하세요).
struct SentimentPill: View {
    let kind: PolSignalVerdictKind

    var body: some View {
        Text(kind.sentimentLabel)
            .font(.pretendard(11, weight: .bold))
            .foregroundStyle(kind.sentimentForeground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(kind.sentimentSoft, in: Capsule(style: .continuous))
            .fixedSize()
    }
}
