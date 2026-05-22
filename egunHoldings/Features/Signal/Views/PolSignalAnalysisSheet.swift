import SwiftUI

struct PolSignalAnalysisSheet: View {
    let payload: PolSignalAnalysisPayload
    var onOpenDetail: (Int) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss

    private var event: PolSignalEvent {
        PolSignalFlowMockData.event(id: payload.eventId)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header
                verdictSection
                reasonsSection
                scenarioSection
                scheduleSection
                footer
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .background(PSColor.surface.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                PolSignalTag(text: event.category, style: tagStyle)
                Text("분석 완료")
                    .font(.pretendard(12, weight: .semibold, relativeTo: .caption))
                    .foregroundStyle(PSColor.primary)
                Spacer(minLength: 0)
                Text("v\(payload.analysisVersion)")
                    .font(.pretendard(11, weight: .medium, relativeTo: .caption2))
                    .foregroundStyle(PSColor.textFaint)
                    .lineLimit(1)
            }

            Text(event.title)
                .font(.pretendard(22, weight: .bold, relativeTo: .title2))
                .foregroundStyle(PSColor.textPrimary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            Text("\(event.exposureSummary) 보유 중인 당신, 확인해보세요.")
                .font(.pretendard(14, weight: .regular, relativeTo: .body))
                .foregroundStyle(PSColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var verdictSection: some View {
        PolSignalCard(variant: .surfaceAlt) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    PolSignalVerdictBadge(label: event.verdictKind.label)
                    Text("판정")
                        .font(.pretendard(13, weight: .semibold, relativeTo: .caption))
                        .foregroundStyle(PSColor.textSecondary)
                    Spacer(minLength: 0)
                }

                Text(event.verdict)
                    .font(.pretendard(17, weight: .bold, relativeTo: .headline))
                    .foregroundStyle(PSColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(event.reason)
                    .font(.pretendard(14, weight: .regular, relativeTo: .body))
                    .foregroundStyle(PSColor.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var reasonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PolSignalSectionHeader(title: "근거", meta: "\(reasons.count)가지")

            VStack(spacing: 8) {
                ForEach(Array(reasons.enumerated()), id: \.offset) { _, reason in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: reason.iconName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(reason.color)
                            .frame(width: 34, height: 34)
                            .background(reason.color.opacity(0.10), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(reason.title)
                                .font(.pretendard(14, weight: .semibold, relativeTo: .body))
                                .foregroundStyle(PSColor.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(reason.detail)
                                .font(.pretendard(13, weight: .regular, relativeTo: .footnote))
                                .foregroundStyle(PSColor.textSecondary)
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(PSColor.surfaceAlt, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    private var scenarioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PolSignalSectionHeader(title: "시나리오", meta: "Lead A")

            VStack(spacing: 8) {
                ForEach(event.scenarios) { scenario in
                    HStack(spacing: 10) {
                        Text(scenario.code)
                            .font(.pretendard(13, weight: .bold, relativeTo: .caption))
                            .foregroundStyle(scenario.code == "A" ? Color.white : PSColor.primary)
                            .frame(width: 30, height: 30)
                            .background(scenario.code == "A" ? PSColor.primary : PSColor.primarySoft, in: Circle())

                        Text("\(scenario.probability)%")
                            .font(.pretendard(14, weight: .bold, relativeTo: .body))
                            .foregroundStyle(PSColor.textPrimary)
                            .monospacedDigit()
                            .frame(width: 42, alignment: .leading)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(scenario.title)
                                .font(.pretendard(14, weight: .semibold, relativeTo: .body))
                                .foregroundStyle(PSColor.textPrimary)
                                .lineLimit(1)

                            Text(scenarioDeltaText(for: scenario))
                                .font(.pretendard(12, weight: .regular, relativeTo: .caption))
                                .foregroundStyle(PSColor.textSecondary)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(scenario.code == "A" ? PSColor.primarySoft : PSColor.surfaceAlt, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(scenario.code == "A" ? PSColor.primary.opacity(0.18) : PSColor.rule, lineWidth: 1)
                    }
                }
            }
        }
    }

    private var scheduleSection: some View {
        Label(event.checkSchedule, systemImage: "calendar")
            .font(.pretendard(14, weight: .semibold, relativeTo: .body))
            .foregroundStyle(PSColor.textPrimary)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PSColor.surfaceAlt, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var footer: some View {
        Button {
            dismiss()
            onOpenDetail(event.id)
        } label: {
            HStack(spacing: 6) {
                Text("전체 분석 보기")
                    .font(.pretendard(15, weight: .semibold, relativeTo: .body))
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(PSColor.primary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background(PSColor.primarySoft, in: RoundedRectangle(cornerRadius: PSRadius.button, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var tagStyle: PolSignalTagStyle {
        switch event.category {
        case "반도체":
            return .semi
        case "환율", "금리":
            return .rate
        default:
            return .policy
        }
    }

    private var reasons: [(iconName: String, title: String, detail: String, color: Color)] {
        [
            (
                iconName: "exclamationmark.triangle.fill",
                title: event.title,
                detail: event.sourceSummary,
                color: PSColor.primary
            ),
            (
                iconName: "chart.line.uptrend.xyaxis",
                title: event.expectedImpact,
                detail: event.reason,
                color: event.verdictKind.accent
            ),
            (
                iconName: "person.crop.circle.badge.checkmark",
                title: "내 자산 연결",
                detail: event.exposureSummary.isEmpty ? "직접 노출은 낮게 계산됐어요." : "\(event.exposureSummary)와 연결돼요.",
                color: PSColor.success
            )
        ]
    }

    private func scenarioDeltaText(for scenario: PolSignalScenario) -> String {
        let delta: String
        switch scenario.code {
        case "A":
            delta = "±1%"
        case "B":
            delta = "+2%"
        default:
            delta = "-1.5%"
        }

        return "\(scenario.outcome) · \(delta)"
    }
}
