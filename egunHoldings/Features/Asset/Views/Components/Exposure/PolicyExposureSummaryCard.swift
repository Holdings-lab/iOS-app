import SwiftUI

struct PolicyExposureSummaryCard: View {
    let summaryItems: [PolicyExposureSummaryItem]
    let defenseReadiness: [DefenseReadinessItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("정책 노출도 요약")
                .font(.pretendard(15, weight: .semibold))
                .foregroundStyle(Color.foreground)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(summaryItems) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.title)
                            .font(.pretendard(12, weight: .semibold))
                            .foregroundStyle(Color.foreground)
                        Text("\(item.exposurePercent)%")
                            .font(.pretendard(18, weight: .bold))
                            .foregroundStyle(item.color)
                        Text(item.summary)
                            .font(.pretendard(11, weight: .medium))
                            .foregroundStyle(Color.mutedForeground)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("현금·달러 방어력과 정책 집중도")
                    .font(.pretendard(13, weight: .semibold))
                    .foregroundStyle(Color.foreground)

                ForEach(defenseReadiness) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(item.color.opacity(0.18))
                            .frame(width: 28, height: 28)
                            .overlay {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(item.color)
                            }

                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(item.title)
                                    .font(.pretendard(12, weight: .semibold))
                                    .foregroundStyle(Color.foreground)
                                Spacer()
                                Text(item.value)
                                    .font(.pretendard(12, weight: .bold))
                                    .foregroundStyle(item.color)
                            }

                            Text(item.summary)
                                .font(.pretendard(11, weight: .medium))
                                .foregroundStyle(Color.mutedForeground)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
    }
}
