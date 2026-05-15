import SwiftUI

struct SignalView: View {
    @StateObject private var viewModel: PolSignalFlowViewModel
    @Binding private var externalRoute: PolSignalRoute?
    @State private var navigationPath: [PolSignalRoute]

    init(
        initialRoute: PolSignalRoute? = nil,
        externalRoute: Binding<PolSignalRoute?> = .constant(nil),
        viewModel: PolSignalFlowViewModel = PolSignalFlowViewModel()
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _externalRoute = externalRoute
        _navigationPath = State(initialValue: initialRoute.map { [$0] } ?? [])
    }

    init(viewModel: SignalViewModel) {
        self.init()
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            PFContentScrollView(
                alignment: .leading,
                spacing: 20,
                horizontalPadding: PSSpacing.screenHorizontal,
                topPadding: 12,
                bottomPadding: 112,
                scrollsToTopOnAppear: true,
                locksHorizontalOverflow: true
            ) {
                header
                vixCard
                feedTabs
                eventList
            }
            .policyFinanceLightTabChrome()
            .navigationDestination(for: PolSignalRoute.self) { route in
                switch route {
                case .detail(let eventId):
                    PolSignalDetailView(
                        event: viewModel.event(id: eventId),
                        proposal: viewModel.adjustmentProposal,
                        onAdjustmentTap: {
                            navigationPath.append(.adjustment)
                        }
                    )
                case .adjustment:
                    PolSignalAdjustmentProposalView(proposal: viewModel.adjustmentProposal)
                }
            }
        }
        .onAppear {
            consumeExternalRoute()
        }
        .onChange(of: externalRoute) { _, _ in
            consumeExternalRoute()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("시그널")
                .font(.pretendard(28, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            Text("정책 신호가 내 자산에 어떤 행동으로 이어지는지 확인하세요")
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var vixCard: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("VIX")
                    .font(.pretendard(11, weight: .bold))
                    .foregroundStyle(Color.textTertiary)

                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Text(viewModel.vixText)
                        .font(.pretendard(28, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .monospacedDigit()

                    Text(viewModel.vixChangeText)
                        .font(.pretendard(12, weight: .bold))
                        .foregroundStyle(Color.trendDown)
                        .monospacedDigit()
                }
            }

            Spacer(minLength: 0)

            Text(viewModel.vixCaption)
                .font(.pretendard(12, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }

    private var feedTabs: some View {
        HStack(spacing: 8) {
            ForEach(PolSignalFeedTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedFeedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.pretendard(13, weight: .bold))
                        .foregroundStyle(viewModel.selectedFeedTab == tab ? Color.white : Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            viewModel.selectedFeedTab == tab ? Color.brand : Color.elevated,
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(viewModel.selectedFeedTab == tab ? Color.brand : Color.hairline, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var eventList: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.filteredEvents) { event in
                Button {
                    navigationPath.append(.detail(event.id))
                } label: {
                    PolSignalEventCard(event: event)
                }
                .buttonStyle(PressScaleButtonStyle())
            }
        }
    }

    private func consumeExternalRoute() {
        guard let route = externalRoute else { return }
        navigationPath = [route]
        externalRoute = nil
    }
}

private struct PolSignalEventCard: View {
    let event: PolSignalEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                PolSignalChip(text: event.category, color: event.accentColor)
                PolSignalChip(text: event.dDay, color: event.accentColor, isProminent: true)
                Spacer(minLength: 0)
            }

            Text(event.title)
                .font(.pretendard(17, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            exposureRow

            Text(event.expectedImpact)
                .font(.pretendard(13, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(event.accentColor)
                    .padding(.top, 1)

                Text(event.aiSummary)
                    .font(.pretendard(12, weight: .medium))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(event.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            HStack(spacing: 6) {
                Text(event.ctaTitle)
                    .font(.pretendard(13, weight: .bold))

                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(event.accentColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }

    private var exposureRow: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("내 노출")
                .font(.pretendard(11, weight: .semibold))
                .foregroundStyle(Color.textTertiary)

            PolSignalFlowLayout(spacing: 6) {
                ForEach(event.exposures) { exposure in
                    PolSignalChip(text: "\(exposure.ticker) \(exposure.weightText)", color: exposure.color)
                }
            }
        }
    }
}

private struct PolSignalDetailView: View {
    let event: PolSignalEvent
    let proposal: PolSignalAdjustmentProposal
    let onAdjustmentTap: () -> Void

    @State private var selectedScenarioID: UUID?
    @State private var isSourceExpanded = false

    var body: some View {
        VStack(spacing: 0) {
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
                aiSummaryBlock
                scenarioSection
                sourceSummarySection
                scheduleSection
            }

            bottomCTA
        }
        .policyFinanceLightTabChrome(bottomInset: 0)
        .onAppear {
            selectedScenarioID = selectedScenarioID ?? event.scenarios.first?.id
        }
    }

    private var detailHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                PolSignalChip(text: event.category, color: event.accentColor, isProminent: true)
                PolSignalChip(text: event.institution, color: event.accentColor)
                PolSignalChip(text: event.dDay, color: event.accentColor)
            }

            Text(event.title)
                .font(.pretendard(25, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var exposureSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            PolSignalSectionTitle("내 노출")

            PolSignalFlowLayout(spacing: 7) {
                ForEach(event.exposures) { exposure in
                    PolSignalChip(text: "\(exposure.ticker) \(exposure.weightText)", color: exposure.color, isProminent: true)
                }
            }
        }
    }

    private var expectedImpactSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            PolSignalSectionTitle("예상 영향")

            Text(event.expectedImpact)
                .font(.pretendard(15, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.elevated, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.hairline, lineWidth: 1)
                }
        }
    }

    private var aiSummaryBlock: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(event.accentColor)
                .padding(.top, 1)

            Text(event.aiSummary)
                .font(.pretendard(14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(15)
        .background(event.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(event.accentColor.opacity(0.16), lineWidth: 1)
        }
    }

    private var scenarioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PolSignalSectionTitle("시나리오")

            HStack(spacing: 8) {
                ForEach(event.scenarios) { scenario in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedScenarioID = scenario.id
                        }
                    } label: {
                        VStack(spacing: 3) {
                            Text(scenario.code)
                                .font(.pretendard(14, weight: .bold))
                            Text("\(scenario.probability)%")
                                .font(.pretendard(11, weight: .semibold))
                                .monospacedDigit()
                        }
                        .foregroundStyle(selectedScenarioID == scenario.id ? Color.white : Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedScenarioID == scenario.id ? event.accentColor : Color.elevated,
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(selectedScenarioID == scenario.id ? event.accentColor : Color.hairline, lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            if let scenario = selectedScenario {
                VStack(alignment: .leading, spacing: 8) {
                    Text(scenario.title)
                        .font(.pretendard(16, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    Text(scenario.outcome)
                        .font(.pretendard(14, weight: .bold))
                        .foregroundStyle(event.accentColor)

                    Text(scenario.note)
                        .font(.pretendard(13, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(15)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.elevated, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.hairline, lineWidth: 1)
                }
            }

            warningBlock
        }
    }

    private var warningBlock: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.warning)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("판단 약화 조건")
                    .font(.pretendard(12, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text(event.weakeningCondition)
                    .font(.pretendard(12, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(13)
        .background(Color.warningBg, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.warningBorder, lineWidth: 1)
        }
    }

    private var sourceSummarySection: some View {
        DisclosureGroup(isExpanded: $isSourceExpanded) {
            Text(event.sourceSummary)
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
        } label: {
            Text(isSourceExpanded ? "원문 접기" : "원문 펼치기")
                .font(.pretendard(14, weight: .bold))
                .foregroundStyle(Color.textPrimary)
        }
        .accentColor(Color.textSecondary)
        .padding(15)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }

    private var scheduleSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(event.accentColor)
                .frame(width: 32, height: 32)
                .background(event.accentColor.opacity(0.1), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text("점검 일정")
                    .font(.pretendard(12, weight: .bold))
                    .foregroundStyle(Color.textTertiary)

                Text(event.checkSchedule)
                    .font(.pretendard(14, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
            }

            Spacer(minLength: 0)
        }
        .padding(15)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }

    private var bottomCTA: some View {
        Button(action: onAdjustmentTap) {
            HStack(spacing: 8) {
                Text("조정 제안 보기")
                    .font(.pretendard(16, weight: .bold))

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.brand, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(PressScaleButtonStyle())
        .padding(.horizontal, PSSpacing.screenHorizontal)
        .padding(.top, 10)
        .padding(.bottom, 16)
        .background(Color.canvas)
    }

    private var selectedScenario: PolSignalScenario? {
        event.scenarios.first { $0.id == selectedScenarioID } ?? event.scenarios.first
    }
}

private struct PolSignalAdjustmentProposalView: View {
    let proposal: PolSignalAdjustmentProposal
    @State private var recordState: String?

    var body: some View {
        PFContentScrollView(
            alignment: .leading,
            spacing: 20,
            horizontalPadding: PSSpacing.screenHorizontal,
            topPadding: 12,
            bottomPadding: 112,
            scrollsToTopOnAppear: true,
            locksHorizontalOverflow: true
        ) {
            header
            weightComparison
            reasonSection
            effectSection
            actionButtons
        }
        .policyFinanceLightTabChrome()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                PolSignalChip(text: proposal.badgeText, color: .brand, isProminent: true)
                PolSignalChip(text: proposal.indexText, color: .brand)
            }

            Text(proposal.title)
                .font(.pretendard(24, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var weightComparison: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .center) {
                Text("\(proposal.currentLabel) \(Int(proposal.currentWeight))%")
                    .font(.pretendard(18, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .monospacedDigit()

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.textTertiary)

                Spacer()

                Text("\(proposal.proposedLabel) \(Int(proposal.proposedWeight))%")
                    .font(.pretendard(18, weight: .bold))
                    .foregroundStyle(Color.brand)
                    .monospacedDigit()
            }

            VStack(spacing: 8) {
                ProposalWeightBar(title: "현재 비중", value: proposal.currentWeight, color: .trendDown)
                ProposalWeightBar(title: "제안 비중", value: proposal.proposedWeight, color: .brand)
            }

            PolSignalFlowLayout(spacing: 7) {
                ForEach(proposal.allocationChanges, id: \.self) { change in
                    PolSignalChip(text: change, color: change.contains("-") ? .trendDown : .success)
                }
            }
        }
        .padding(16)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }

    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PolSignalSectionTitle("조정 근거 \(proposal.reasons.count)가지")

            VStack(spacing: 10) {
                ForEach(proposal.reasons) { reason in
                    DisclosureGroup {
                        Text(reason.detail)
                            .font(.pretendard(12, weight: .medium))
                            .foregroundStyle(Color.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 8)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: reason.iconName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(reason.color)
                                .frame(width: 30, height: 30)
                                .background(reason.color.opacity(0.1), in: Circle())

                            Text(reason.title)
                                .font(.pretendard(13, weight: .bold))
                                .foregroundStyle(Color.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .accentColor(Color.textTertiary)
                    .padding(14)
                    .background(Color.elevated, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.hairline, lineWidth: 1)
                    }
                }
            }
        }
    }

    private var effectSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PolSignalSectionTitle("예상 효과")

            HStack(spacing: 10) {
                ForEach(proposal.effects) { effect in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(effect.title)
                            .font(.pretendard(11, weight: .semibold))
                            .foregroundStyle(Color.textTertiary)

                        Text(effect.value)
                            .font(.pretendard(18, weight: .bold))
                            .foregroundStyle(effect.color)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .monospacedDigit()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.elevated, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.hairline, lineWidth: 1)
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 11) {
            HStack(spacing: 10) {
                Button {
                    recordState = "대기 기록 완료"
                } label: {
                    Text("대기 기록")
                        .font(.pretendard(15, weight: .bold))
                        .foregroundStyle(Color.brand)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.brand.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(PressScaleButtonStyle())

                Button {
                    recordState = "대응 기록 완료"
                } label: {
                    Text("대응 기록")
                        .font(.pretendard(15, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.brand, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(PressScaleButtonStyle())
            }

            Text(recordState ?? proposal.helperText)
                .font(.pretendard(12, weight: .medium))
                .foregroundStyle(recordState == nil ? Color.textTertiary : Color.success)
                .frame(maxWidth: .infinity, alignment: .center)
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
                    .font(.pretendard(11, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)

                Spacer()

                Text("\(Int(value))%")
                    .font(.pretendard(11, weight: .bold))
                    .foregroundStyle(color)
                    .monospacedDigit()
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.subtle)
                    Capsule()
                        .fill(color)
                        .frame(width: max(0, proxy.size.width * value / 100))
                }
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    SignalView()
}
