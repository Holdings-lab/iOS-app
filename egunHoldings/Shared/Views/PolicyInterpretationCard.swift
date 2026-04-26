import SwiftUI

struct PolicyInterpretationCard: View {
    let eventTitle: String
    let assetName: String
    let probabilityText: String
    let signalText: String
    var compact: Bool = false

    var body: some View {
        PFSurfaceCard {
            VStack(alignment: .leading, spacing: compact ? 12 : 16) {
                Text("정책 이벤트")
                    .font(.pretendard(12, weight: .semibold))
                    .foregroundStyle(Color.midnightTextTertiary)

                Text(eventTitle)
                    .font(.pretendard(compact ? 20 : 24, weight: .bold))
                    .foregroundStyle(Color.midnightTextPrimary)

                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    Text(assetName)
                        .font(.pretendard(compact ? 18 : 20, weight: .semibold))
                        .foregroundStyle(Color.midnightTextPrimary)

                    Text(probabilityText)
                        .font(.pretendard(compact ? 28 : 30, weight: .bold))
                        .foregroundStyle(Color.midnightAccent)
                }

                HStack(spacing: 8) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.midnightTextSecondary)

                    Text(signalText)
                        .font(.pretendard(13, weight: .medium))
                        .foregroundStyle(Color.midnightTextSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    PolicyInterpretationCard(
        eventTitle: "금리 인상 발표",
        assetName: "QQQ 하락 가능성",
        probabilityText: "68%",
        signalText: "변동성 확대 가능성"
    )
    .padding(24)
    .background(PFGradientBackground())
}
