import SwiftUI

struct ActionLaneBoardSection: View {
    let actionOptions: [PolicyActionOption]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("4분면 액션 큐")
                .font(.pretendard(15, weight: .semibold))
                .foregroundStyle(Color.foreground)

            Text("추천이 아니라, 행동 옵션과 틀릴 조건을 같이 보여주는 결정 보드예요.")
                .font(.pretendard(12, weight: .medium))
                .foregroundStyle(Color.mutedForeground)

            ForEach(PolicyActionLane.allCases) { lane in
                let items = actionOptions.filter { $0.lane == lane }
                if !items.isEmpty {
                    ActionLaneCard(lane: lane, items: items)
                }
            }
        }
    }
}

private struct ActionLaneCard: View {
    let lane: PolicyActionLane
    let items: [PolicyActionOption]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: lane.symbol)
                    .foregroundStyle(lane.color)
                Text(lane.rawValue)
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(Color.foreground)
            }

            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.pretendard(13, weight: .semibold))
                                .foregroundStyle(Color.foreground)
                            Text(item.reason)
                                .font(.pretendard(11, weight: .medium))
                                .foregroundStyle(Color.mutedForeground)
                        }
                        Spacer()
                        Text("확신도 \(item.meta.confidence)")
                            .font(.pretendard(11, weight: .semibold))
                            .foregroundStyle(lane.color)
                    }

                    HStack(spacing: 8) {
                        LaneMetaChip(text: "영향 자산 \(item.affectedAssets.joined(separator: ", "))", color: .electricBlue)
                        LaneMetaChip(text: item.effectiveWindow, color: .policyAmber)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("먼저 이렇게 보세요")
                            .font(.pretendard(11, weight: .semibold))
                            .foregroundStyle(Color.foreground)
                        Text(item.recommendation)
                            .font(.pretendard(11, weight: .medium))
                            .foregroundStyle(Color.mutedForeground)

                        Text("무효화 조건")
                            .font(.pretendard(11, weight: .semibold))
                            .foregroundStyle(Color.policyCoral)
                        Text(item.meta.invalidationCondition)
                            .font(.pretendard(11, weight: .medium))
                            .foregroundStyle(Color.mutedForeground)
                    }
                    .padding(10)
                    .background(Color.subtle, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .padding(12)
                .background(Color.subtle, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(16)
        .glassCard()
    }
}

private struct LaneMetaChip: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.pretendard(10, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: KDXRadius.chip, style: .continuous))
    }
}
