import SwiftUI

struct TransmissionMatchSection: View {
    let matches: [PolicyTransmissionMatch]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("전달경로 매칭")
                .font(.pretendard(15, weight: .semibold))
                .foregroundStyle(Color.foreground)

            Text("점수 대신, 왜 이 자산이 정책과 연결되는지 경로로 보여줘요.")
                .font(.pretendard(12, weight: .medium))
                .foregroundStyle(Color.mutedForeground)

            ForEach(matches) { match in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(match.policyTitle)
                                .font(.pretendard(12, weight: .medium))
                                .foregroundStyle(Color.mutedForeground)
                            Text(match.assetName)
                                .font(.pretendard(15, weight: .semibold))
                                .foregroundStyle(Color.foreground)
                        }
                        Spacer()
                        Text("노출 \(match.meta.exposurePercent)%")
                            .font(.pretendard(13, weight: .bold))
                            .foregroundStyle(match.meta.direction.color)
                    }

                    Text(match.summary)
                        .font(.pretendard(12, weight: .medium))
                        .foregroundStyle(Color.mutedForeground)

                    ForEach(match.factors) { factor in
                        HStack(alignment: .top, spacing: 8) {
                            Text(factor.title)
                                .font(.pretendard(11, weight: .semibold))
                                .foregroundStyle(Color.electricBlue)
                                .frame(width: 70, alignment: .leading)
                            Text(factor.detail)
                                .font(.pretendard(11, weight: .medium))
                                .foregroundStyle(Color.foreground)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Divider().background(Color.white.opacity(0.08))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("반대 근거")
                            .font(.pretendard(11, weight: .semibold))
                            .foregroundStyle(Color.policyAmber)
                        Text(match.meta.counterEvidence)
                            .font(.pretendard(11, weight: .medium))
                            .foregroundStyle(Color.mutedForeground)
                    }
                }
                .padding(16)
                .glassCard()
            }
        }
    }
}
