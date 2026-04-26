import SwiftUI

struct HoldingExposureMatrixCard: View {
    let rows: [HoldingPolicyExposureRow]
    let hiddenBets: [HiddenPolicyBet]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("보유 자산 + 정책 노출 매트릭스")
                .font(.pretendard(15, weight: .semibold))
                .foregroundStyle(Color.foreground)

            ForEach(rows) { row in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(row.holdingName)
                            .font(.pretendard(13, weight: .semibold))
                            .foregroundStyle(Color.foreground)
                        Spacer()
                        Text("\(row.holdingWeightPercent)%")
                            .font(.pretendard(13, weight: .bold))
                            .foregroundStyle(Color.electricBlue)
                    }

                    FlowLayout(spacing: 8) {
                        ForEach(row.exposures) { chip in
                            Text("\(chip.title) · \(chip.exposureText)")
                                .font(.pretendard(10, weight: .semibold))
                                .foregroundStyle(chip.color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .glassEffect(.regular.tint(chip.color.opacity(0.16)), in: Capsule())
                        }
                    }

                    Text(row.note)
                        .font(.pretendard(11, weight: .medium))
                        .foregroundStyle(Color.mutedForeground)
                }
                .padding(12)
                .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("숨은 정책 베팅")
                    .font(.pretendard(13, weight: .semibold))
                    .foregroundStyle(Color.foreground)

                ForEach(hiddenBets) { bet in
                    HStack(alignment: .top, spacing: 10) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(bet.color.opacity(0.18))
                            .frame(width: 6)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(bet.title)
                                    .font(.pretendard(12, weight: .semibold))
                                    .foregroundStyle(Color.foreground)
                                Spacer()
                                Text("중복 \(bet.overlapPercent)%")
                                    .font(.pretendard(12, weight: .bold))
                                    .foregroundStyle(bet.color)
                            }
                            Text(bet.summary)
                                .font(.pretendard(11, weight: .medium))
                                .foregroundStyle(Color.mutedForeground)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(16)
        .glassCard()
    }
}

private struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    init(spacing: CGFloat, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        HStack(spacing: spacing) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
