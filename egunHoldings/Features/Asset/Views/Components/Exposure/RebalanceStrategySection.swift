import SwiftUI

struct RebalanceStrategySection: View {
    let noTradeZone: NoTradeZoneNote
    let constraints: [RebalanceConstraint]
    let scenarioVariants: [RebalanceScenarioVariant]
    let executionPlan: [RebalanceExecutionStep]
    let whyCard: RebalanceWhyCard

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("현재 배분 + 노트레이드 존")
                    .font(.pretendard(15, weight: .semibold))
                    .foregroundStyle(Color.foreground)

                Text(noTradeZone.title)
                    .font(.pretendard(13, weight: .semibold))
                    .foregroundStyle(Color.electricBlue)
                Text(noTradeZone.summary)
                    .font(.pretendard(12, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)

                ForEach(noTradeZone.bullets, id: \.self) { bullet in
                    Label(bullet, systemImage: "pause.circle.fill")
                        .font(.pretendard(11, weight: .medium))
                        .foregroundStyle(Color.foreground)
                }
            }
            .padding(16)
            .glassCard()

            VStack(alignment: .leading, spacing: 12) {
                Text("리밸런싱 모드와 제약조건")
                    .font(.pretendard(15, weight: .semibold))
                    .foregroundStyle(Color.foreground)

                ForEach(RebalanceMode.allCases) { mode in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode.rawValue)
                            .font(.pretendard(12, weight: .semibold))
                            .foregroundStyle(Color.foreground)
                        Text(mode.subtitle)
                            .font(.pretendard(11, weight: .medium))
                            .foregroundStyle(Color.mutedForeground)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(constraints) { constraint in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(constraint.title)
                                .font(.pretendard(11, weight: .medium))
                                .foregroundStyle(Color.mutedForeground)
                            Text(constraint.value)
                                .font(.pretendard(14, weight: .bold))
                                .foregroundStyle(Color.foreground)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
            .padding(16)
            .glassCard()

            VStack(alignment: .leading, spacing: 12) {
                Text("시나리오 슬라이더")
                    .font(.pretendard(15, weight: .semibold))
                    .foregroundStyle(Color.foreground)

                ForEach(scenarioVariants) { variant in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(variant.title)
                                .font(.pretendard(12, weight: .semibold))
                                .foregroundStyle(Color.foreground)
                            Text(variant.note)
                                .font(.pretendard(11, weight: .medium))
                                .foregroundStyle(Color.mutedForeground)
                        }
                        Spacer()
                        Text(variant.suggestedChange)
                            .font(.pretendard(12, weight: .bold))
                            .foregroundStyle(variant.color)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(16)
            .glassCard()

            VStack(alignment: .leading, spacing: 12) {
                Text("왜 타당한지 + 왜 아닐 수 있는지")
                    .font(.pretendard(15, weight: .semibold))
                    .foregroundStyle(Color.foreground)

                ForEach(Array(whyCard.supportingLines.enumerated()), id: \.offset) { _, line in
                    Label(line, systemImage: "checkmark.circle.fill")
                        .font(.pretendard(11, weight: .medium))
                        .foregroundStyle(Color.foreground)
                }

                Text("반대 1문장")
                    .font(.pretendard(12, weight: .semibold))
                    .foregroundStyle(Color.policyAmber)
                Text(whyCard.opposingLine)
                    .font(.pretendard(11, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)

                Text(whyCard.projectedExposureChange)
                    .font(.pretendard(11, weight: .semibold))
                    .foregroundStyle(Color.electricBlue)
            }
            .padding(16)
            .glassCard()

            VStack(alignment: .leading, spacing: 12) {
                Text("실행 계획서")
                    .font(.pretendard(15, weight: .semibold))
                    .foregroundStyle(Color.foreground)

                ForEach(executionPlan) { step in
                    HStack(alignment: .top, spacing: 10) {
                        Text(step.title)
                            .font(.pretendard(11, weight: .semibold))
                            .foregroundStyle(Color.electricBlue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .glassEffect(.regular.tint(Color.electricBlue.opacity(0.16)), in: Capsule())

                        Text(step.detail)
                            .font(.pretendard(11, weight: .medium))
                            .foregroundStyle(Color.foreground)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(16)
            .glassCard()
        }
    }
}
