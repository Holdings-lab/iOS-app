import SwiftUI

struct HomeSecondaryPolicySection: View {
    let policies: [HomeImpactPolicy]
    let onSelect: (HomeImpactPolicy) -> Void

    var body: some View {
        Group {
            if policies.isEmpty == false {
                VStack(alignment: .leading, spacing: 12) {
                    Text("이어서 볼 시그널")
                        .font(.pretendard(17, weight: .semibold))
                        .foregroundStyle(Color.foreground)

                    Text("오늘 대표 시그널 다음으로 확인할 변화예요")
                        .font(.pretendard(12, weight: .semibold))
                        .foregroundStyle(Color.mutedForeground.opacity(0.78))

                    VStack(spacing: 10) {
                        ForEach(policies.prefix(2)) { policy in
                            CompactSignalRow(
                                policy: policy,
                                onTap: {
                                    onSelect(policy)
                                }
                            )
                        }
                    }
                }
            }
        }
    }
}

private struct CompactSignalRow: View {
    let policy: HomeImpactPolicy
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HomeGlassCard(
                variant: .secondary,
                padding: EdgeInsets(top: 13, leading: 14, bottom: 13, trailing: 14)
            ) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(policy.title)
                            .font(.pretendard(15, weight: .semibold))
                            .foregroundStyle(Color.foreground.opacity(0.96))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 6) {
                            Text(policy.judgment.action.rawValue)
                                .font(.pretendard(12, weight: .semibold))
                                .foregroundStyle(policy.judgment.action.color)

                            Text("·")
                                .font(.pretendard(12, weight: .medium))
                                .foregroundStyle(Color.mutedForeground.opacity(0.5))

                            Text("노출 \(policy.meta.exposurePercent)%")
                                .font(.pretendard(12, weight: .medium))
                                .foregroundStyle(Color.mutedForeground.opacity(0.9))
                                .monospacedDigit()
                        }

                        Text(policy.judgment.keyReason)
                            .font(.pretendard(11, weight: .medium))
                            .foregroundStyle(Color.mutedForeground.opacity(0.76))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.mutedForeground.opacity(0.72))
                }
            }
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}
