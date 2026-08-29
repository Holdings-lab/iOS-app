import SwiftUI

struct PolSignalDetailView: View {
    let event: PolSignalEvent
    let proposal: PolSignalAdjustmentProposal
    let onAdjustmentTap: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedScenarioID: UUID?
    @State private var isSourceExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            navBar

            PFContentScrollView(
                alignment: .leading,
                spacing: 20,
                horizontalPadding: PSSpacing.screenHorizontal,
                topPadding: 12,
                bottomPadding: 24,
                scrollsToTopOnAppear: true,
                locksHorizontalOverflow: true
            ) {
                detailHeader
                exposureSection
                expectedImpactSection
                PolSignalAIBlock(text: event.aiSummary)
                scenarioSection
                sourceSummarySection
                scheduleSection
            }

            bottomCTA
        }
        .background(PSColor.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            selectedScenarioID = selectedScenarioID ?? event.scenarios.first?.id
        }
    }

    private var navBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(PSColor.textPrimary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("시그널 상세")
                .font(.pretendard(17, weight: .semibold))
                .foregroundStyle(PSColor.textPrimary)

            Spacer()

            Button {} label: {
                Image(systemName: "bookmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(PSColor.textPrimary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(PSColor.background)
    }

    private var detailHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            PolSignalFlowLayout(spacing: 8) {
                PolSignalTag(text: event.category, style: event.category == "반도체" ? .semi : .rate)
                PolSignalTag(text: "정책", style: .policy)
                PolSignalTag(text: "발표 대기", style: .primary)
                Text(event.institution)
                    .font(.pretendard(12, weight: .regular))
                    .foregroundStyle(PSColor.textSecondary)
                PolSignalBadge(text: event.dDay, style: .warn)
            }

            Text(event.title)
                .font(.pretendard(28, weight: .bold))
                .foregroundStyle(PSColor.textPrimary)
                .lineSpacing(1)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var exposureSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            PolSignalSectionHeader(title: "내 노출")

            PolSignalCard {
                PolSignalFlowLayout(spacing: 7) {
                    ForEach(event.exposures) { exposure in
                        PolSignalChip(text: "\(exposure.ticker) \(exposure.weightText)", color: exposure.color)
                    }
                }
            }
        }
    }

    private var expectedImpactSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            PolSignalSectionHeader(title: "예상 영향")

            Text(event.expectedImpact)
                .font(.pretendard(15, weight: .regular))
                .foregroundStyle(PSColor.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var scenarioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PolSignalSectionHeader(title: "시나리오", meta: "확률 기반")

            HStack(spacing: 6) {
                ForEach(event.scenarios) { scenario in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedScenarioID = scenario.id
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(scenario.code)
                                .font(.pretendard(12, weight: .semibold))
                            Text("\(scenario.probability)%")
                                .font(.pretendard(16, weight: .bold))
                                .monospacedDigit()
                        }
                        .foregroundStyle(selectedScenarioID == scenario.id ? Color.white : PSColor.textFaint)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedScenarioID == scenario.id ? PSColor.primary : PSColor.surface,
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(selectedScenarioID == scenario.id ? PSColor.primary : PSColor.border, lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            if let scenario = selectedScenario {
                PolSignalCard(variant: scenarioVariant(scenario)) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(scenario.title)
                                .font(.pretendard(16, weight: .bold))
                                .foregroundStyle(PSColor.textPrimary)
                            Spacer()
                            PolSignalBadge(text: scenario.outcome, style: scenarioBadgeStyle(scenario))
                        }

                        Text(scenario.note)
                            .font(.pretendard(14, weight: .regular))
                            .foregroundStyle(PSColor.textSecondary)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            PolSignalCallout(title: "판단 약화 조건", message: event.weakeningCondition, tone: .danger)
        }
    }

    private var sourceSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PolSignalSectionHeader(title: "원문 요약", meta: "\(event.institution) · \(event.timeText)")

            PolSignalCard {
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSourceExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Text(event.sourceHeadline)
                                .font(.pretendard(14, weight: .medium))
                                .foregroundStyle(PSColor.textPrimary)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(PSColor.textSecondary)
                                .rotationEffect(.degrees(isSourceExpanded ? 180 : 0))
                        }
                    }
                    .buttonStyle(.plain)

                    if isSourceExpanded {
                        Divider()
                            .background(PSColor.rule)
                            .padding(.top, 12)
                        Text(event.sourceSummary)
                            .font(.pretendard(13, weight: .regular))
                            .foregroundStyle(PSColor.textSecondary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 12)
                    }
                }
            }
        }
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PolSignalSectionHeader(title: "점검 일정")

            PolSignalCard(padding: EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)) {
                VStack(spacing: 0) {
                    scheduleRow(title: "발표 확인", value: event.checkSchedule)
                    Divider().background(PSColor.rule)
                    scheduleRow(title: "다시 보기", value: "5월 16일 23:00")
                }
            }

            PolSignalButton("+ 캘린더 추가 · 알림", style: .secondary) {}
        }
    }

    private func scheduleRow(title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(PSColor.primary)
                .frame(width: 28, height: 28)

            Text(title)
                .font(.pretendard(14, weight: .regular))
                .foregroundStyle(PSColor.textPrimary)

            Spacer()

            Text(value)
                .font(.pretendard(14, weight: .semibold))
                .foregroundStyle(PSColor.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 12)
    }

    private var bottomCTA: some View {
        PolSignalButton("조정 제안 보기", iconName: "arrow.right", style: .primary, action: onAdjustmentTap)
            .padding(.horizontal, PSSpacing.screenHorizontal)
            .padding(.top, 10)
            .padding(.bottom, 16)
            .background(PSColor.background)
    }

    private var selectedScenario: PolSignalScenario? {
        event.scenarios.first { $0.id == selectedScenarioID } ?? event.scenarios.first
    }

    private func scenarioVariant(_ scenario: PolSignalScenario) -> PolSignalCardVariant {
        switch scenario.code {
        case "A":
            return .surfaceAlt
        case "B":
            return .surfaceAlt
        default:
            return .danger
        }
    }

    private func scenarioBadgeStyle(_ scenario: PolSignalScenario) -> PolSignalBadgeStyle {
        switch scenario.code {
        case "A":
            return .success
        case "B":
            return .rate
        default:
            return .danger
        }
    }
}

struct PolSignalAdjustmentProposalSheetView: View {
    let proposal: PolSignalAdjustmentProposal
    @Environment(\.dismiss) private var dismiss
    @State private var recorded: String?

    var body: some View {
        VStack(spacing: 0) {
            Capsule(style: .continuous)
                .fill(Color(hex: "CBD5E1"))
                .frame(width: 36, height: 5)
                .padding(.top, 10)

            sheetHeader

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    statusTags
                    proposalCard
                    reasonSection
                    effectSection
                    actionArea
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .background(PSColor.surface.ignoresSafeArea())
    }

    private var sheetHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("조정 제안")
                    .font(.pretendard(17, weight: .semibold))
                    .foregroundStyle(PSColor.textPrimary)
                Text(proposal.indexText + " ›")
                    .font(.pretendard(13, weight: .regular))
                    .foregroundStyle(PSColor.textSecondary)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(PSColor.textSecondary)
                    .frame(width: 30, height: 30)
                    .background(PSColor.surfaceAlt, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var statusTags: some View {
        HStack(spacing: 8) {
            PolSignalTag(text: proposal.badgeText, style: .primary)
            PolSignalTag(text: "정답 아님", style: .neutral)
        }
    }

    private var proposalCard: some View {
        PolSignalCard(variant: .tinted) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(proposal.currentLabel)
                        .font(.pretendard(14, weight: .semibold))
                        .foregroundStyle(PSColor.textPrimary)
                    Spacer()
                    Text(proposal.allocationChanges.joined(separator: " · "))
                        .font(.pretendard(12, weight: .regular))
                        .foregroundStyle(PSColor.textSecondary)
                }

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("\(Int(proposal.currentWeight))%")
                        .font(.pretendard(32, weight: .bold))
                        .foregroundStyle(PSColor.textPrimary)
                        .monospacedDigit()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(PSColor.textFaint)
                    Text("\(Int(proposal.proposedWeight))%")
                        .font(.pretendard(32, weight: .bold))
                        .foregroundStyle(PSColor.danger)
                        .monospacedDigit()
                }

                VStack(spacing: 10) {
                    ProposalWeightBar(title: "현재", value: proposal.currentWeight, color: PSColor.primary)
                    ProposalWeightBar(title: "제안 후", value: proposal.proposedWeight, color: PSColor.primary)
                }
            }
        }
    }

    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PolSignalSectionHeader(title: "조정 근거", meta: "\(proposal.reasons.count)가지")

            VStack(spacing: 8) {
                ForEach(proposal.reasons) { reason in
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: reason.iconName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(PSColor.primary)
                            .frame(width: 32, height: 32)
                            .background(PSColor.primarySoft, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                        Text(reason.title)
                            .font(.pretendard(14, weight: .regular))
                            .foregroundStyle(PSColor.textPrimary)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)

                        Text("근거 ›")
                            .font(.pretendard(13, weight: .semibold))
                            .foregroundStyle(PSColor.primary)
                    }
                    .padding(12)
                    .background(PSColor.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(PSColor.border, lineWidth: 1)
                    }
                }
            }
        }
    }

    private var effectSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PolSignalSectionHeader(title: "예상 효과")

            PolSignalCard(padding: EdgeInsets(top: 14, leading: 0, bottom: 14, trailing: 0)) {
                HStack(spacing: 0) {
                    ForEach(Array(proposal.effects.enumerated()), id: \.element.id) { index, effect in
                        VStack(spacing: 5) {
                            Text(effect.title)
                                .font(.pretendard(11, weight: .medium))
                                .foregroundStyle(PSColor.textFaint)
                            Text(effect.value)
                                .font(.pretendard(18, weight: .bold))
                                .foregroundStyle(effect.color)
                                .monospacedDigit()
                        }
                        .frame(maxWidth: .infinity)

                        if index < proposal.effects.count - 1 {
                            Divider().background(PSColor.rule)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var actionArea: some View {
        if let recorded {
            VStack(spacing: 10) {
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 44, height: 44)
                    .background(PSColor.success, in: Circle())

                Text("기록됐어요")
                    .font(.pretendard(17, weight: .bold))
                    .foregroundStyle(PSColor.success)

                Text("\(recorded) 상태로 남겼습니다. 실제 주문은 실행되지 않았어요.")
                    .font(.pretendard(13, weight: .regular))
                    .foregroundStyle(PSColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(18)
            .background(PSColor.successBg, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    PolSignalButton("대기 기록", style: .secondary) {
                        record("대기")
                    }
                    PolSignalButton("대응 기록", style: .primary) {
                        record("대응")
                    }
                }

                Text(proposal.helperText)
                    .font(.pretendard(12, weight: .regular))
                    .foregroundStyle(PSColor.textFaint)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private func record(_ value: String) {
        withAnimation(.easeInOut(duration: 0.28)) {
            recorded = value
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

private struct ProposalWeightBar: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.pretendard(12, weight: .medium))
                    .foregroundStyle(PSColor.textSecondary)
                Spacer()
                Text("\(Int(value))%")
                    .font(.pretendard(12, weight: .semibold))
                    .foregroundStyle(color)
                    .monospacedDigit()
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(PSColor.rule)
                    Capsule()
                        .fill(color)
                        .frame(width: max(0, proxy.size.width * value / 100))
                }
            }
            .frame(height: 8)
        }
    }
}
