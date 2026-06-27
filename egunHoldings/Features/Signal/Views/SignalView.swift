import SwiftUI

struct SignalView: View {
    @StateObject private var viewModel: PolSignalFlowViewModel
    @Binding private var externalRoute: PolSignalRoute?
    @State private var navigationPath: [PolSignalRoute]
    @State private var isProposalSheetPresented: Bool
    @State private var expandedAIEventID: Int?

    init(
        userId: Int64? = nil,
        initialRoute: PolSignalRoute? = nil,
        externalRoute: Binding<PolSignalRoute?> = .constant(nil),
        viewModel: PolSignalFlowViewModel? = nil
    ) {
        // Swift 6: default expression이 MainActor isolated init을 직접 호출할 수 없어서
        // nil을 기본값으로 받고 init body 안에서 lazily 생성. (TodayView와 동일 패턴)
        _viewModel = StateObject(wrappedValue: viewModel ?? PolSignalFlowViewModel(userId: userId))
        _externalRoute = externalRoute
        switch initialRoute {
        case .list:
            _navigationPath = State(initialValue: [])
            _isProposalSheetPresented = State(initialValue: false)
        case .detail(let id):
            _navigationPath = State(initialValue: [.detail(id)])
            _isProposalSheetPresented = State(initialValue: false)
        case .adjustment:
            _navigationPath = State(initialValue: [])
            _isProposalSheetPresented = State(initialValue: true)
        case .policyReader(let id):
            _navigationPath = State(initialValue: [.policyReader(id)])
            _isProposalSheetPresented = State(initialValue: false)
        case .themeDetail(let theme):
            _navigationPath = State(initialValue: [.themeDetail(theme)])
            _isProposalSheetPresented = State(initialValue: false)
        case .none:
            _navigationPath = State(initialValue: [])
            _isProposalSheetPresented = State(initialValue: false)
        }
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
                feedTabs
                selectedFeedContent
            }
            .background(PSColor.background.ignoresSafeArea())
            .navigationDestination(for: PolSignalRoute.self) { route in
                switch route {
                case .list:
                    EmptyView()
                case .detail(let eventId):
                    PolSignalDetailView(
                        event: viewModel.event(id: eventId),
                        proposal: viewModel.adjustmentProposal,
                        onAdjustmentTap: openProposalSheet
                    )
                case .adjustment:
                    EmptyView()
                case .policyReader(let id):
                    PolSignalPolicyReaderView(event: PolSignalFlowMockData.policyReading(id: id))
                case .themeDetail(let theme):
                    SignalThemeDetailView(theme: theme)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $isProposalSheetPresented) {
            PolSignalAdjustmentProposalSheetView(proposal: viewModel.adjustmentProposal)
                .presentationDetents([.fraction(0.92)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
                .presentationBackground(PSColor.surface)
        }
        .onAppear {
            consumeExternalRoute()
        }
        .onChange(of: externalRoute) { _, _ in
            consumeExternalRoute()
        }
        .task {
            await viewModel.load()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("이벤트 큐")
                    .font(.pretendard(13, weight: .regular))
                    .foregroundStyle(PSColor.textSecondary)

                Text("시그널")
                    .font(.pretendard(28, weight: .bold))
                    .foregroundStyle(PSColor.textPrimary)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 2) {
                Text("VIX")
                    .font(.pretendard(11, weight: .semibold))
                    .foregroundStyle(PSColor.textFaint)

                HStack(spacing: 4) {
                    Text(viewModel.vixText)
                        .font(.pretendard(18, weight: .bold))
                        .foregroundStyle(PSColor.textPrimary)
                        .monospacedDigit()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(PSColor.danger)
                }
            }
        }
    }

    private var feedTabs: some View {
        Picker("시그널 피드", selection: $viewModel.selectedFeedTab) {
            ForEach(PolSignalFeedTab.allCases) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    @ViewBuilder
    private var selectedFeedContent: some View {
        switch viewModel.selectedFeedTab {
        case .myImpact:
            impactContent
        case .learning:
            learningContent
        }
    }

    private var impactContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            let impactEvents = viewModel.events.filter { $0.feedTab == .myImpact }

            if let hero = impactEvents.first {
                impactHeroCard(hero)
            }

            VStack(alignment: .leading, spacing: 12) {
                let otherEvents = Array(impactEvents.dropFirst().prefix(3))
                PolSignalSectionHeader(title: "다른 시그널", meta: "\(otherEvents.count)건")

                VStack(spacing: 10) {
                    ForEach(otherEvents) { event in
                        signalMiniCard(event)
                    }
                }
            }
        }
    }

    private func impactHeroCard(_ event: PolSignalEvent) -> some View {
        PolSignalCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    PolSignalTag(text: event.category, style: .semi)
                    PolSignalTag(text: "정책", style: .policy)
                    Spacer(minLength: 0)
                    PolSignalBadge(text: event.dDay, style: .warn)
                }

                Text(event.title)
                    .font(.pretendard(19, weight: .bold))
                    .foregroundStyle(PSColor.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 7) {
                    Text("내 노출")
                        .font(.pretendard(12, weight: .semibold))
                        .foregroundStyle(PSColor.textFaint)
                    PolSignalFlowLayout(spacing: 6) {
                        ForEach(event.exposures) { exposure in
                            PolSignalChip(text: "\(exposure.ticker) \(exposure.weightText)", color: exposure.color)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("예상 영향")
                        .font(.pretendard(12, weight: .medium))
                        .foregroundStyle(PSColor.textFaint)
                    Text(event.expectedImpact)
                        .font(.pretendard(14, weight: .regular))
                        .foregroundStyle(PSColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                PolSignalAIBlock(
                    text: event.aiSummary,
                    isExpanded: expandedAIEventID == event.id,
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            expandedAIEventID = expandedAIEventID == event.id ? nil : event.id
                        }
                    }
                )

                VStack(spacing: 8) {
                    PolSignalButton("영향 분석 보기", iconName: "arrow.right", style: .primary) {
                        openDetail(event)
                    }

                    HStack(spacing: 8) {
                        PolSignalButton("시나리오 보기", style: .secondary, isSmall: true) {
                            openDetail(event)
                        }

                        PolSignalButton("조정 제안 보기", style: .secondary, isSmall: true) {
                            openProposalSheet()
                        }
                    }
                }
            }
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(PSColor.primary)
                    .frame(height: 3)
                    .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                    .offset(y: -16)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            openDetail(event)
        }
    }

    private var learningContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            continueLearningCard

            VStack(alignment: .leading, spacing: 12) {
                PolSignalSectionHeader(title: "지금 시그널과 연결된 개념")
                VStack(spacing: 10) {
                    ForEach(viewModel.events.filter { $0.feedTab == .learning || $0.feedTab == .myImpact }.prefix(3)) { event in
                        conceptCard(event)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                PolSignalSectionHeader(title: "개념 모아보기")
                PolSignalFlowLayout(spacing: 8) {
                    ForEach(["#반도체 12", "#금리 8", "#환율 6", "#ETF 5", "#정책 9"], id: \.self) { chip in
                        PolSignalTag(text: chip, style: .neutral)
                    }
                }
            }

            learningStatsCard
        }
    }

    private var continueLearningCard: some View {
        PolSignalCard(variant: .tinted) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    PolSignalTag(text: "이어보기", style: .primary)
                    Spacer()
                    Text("3/5")
                        .font(.pretendard(12, weight: .medium))
                        .foregroundStyle(PSColor.textSecondary)
                }

                Text("정책 신호가 ETF 비중으로 번역되는 방식")
                    .font(.pretendard(18, weight: .bold))
                    .foregroundStyle(PSColor.textPrimary)

                Text("정책 · 포트폴리오 영향")
                    .font(.pretendard(13, weight: .regular))
                    .foregroundStyle(PSColor.textSecondary)

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(hex: "DBEAFE"))
                        Capsule().fill(PSColor.primary).frame(width: proxy.size.width * 0.6)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text("남은 시간 4분")
                    Spacer()
                    Text("+2 학습 점수")
                }
                .font(.pretendard(12, weight: .medium))
                .foregroundStyle(PSColor.textSecondary)

                PolSignalButton("이어보기", iconName: "arrow.right", style: .primary) {}
            }
        }
    }

    private var learningStatsCard: some View {
        PolSignalCard(variant: .surfaceAlt) {
            HStack(spacing: 0) {
                statColumn(title: "이번 주 점수", value: "22", color: PSColor.primary)
                Divider().background(PSColor.rule)
                statColumn(title: "완료 콘텐츠", value: "7", color: PSColor.textPrimary)
                Divider().background(PSColor.rule)
                statColumn(title: "연속 학습", value: "4일", color: PSColor.textPrimary)
            }
        }
    }

    private func statColumn(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.pretendard(title == "이번 주 점수" ? 22 : 18, weight: .bold))
                .foregroundStyle(color)
                .monospacedDigit()
            Text(title)
                .font(.pretendard(11, weight: .medium))
                .foregroundStyle(PSColor.textFaint)
        }
        .frame(maxWidth: .infinity)
    }

    private func conceptCard(_ event: PolSignalEvent) -> some View {
        PolSignalCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(PSColor.primary)
                    .frame(width: 44, height: 44)
                    .background(PSColor.primarySoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        PolSignalTag(text: event.category, style: event.category == "반도체" ? .semi : .rate)
                        Text("4분")
                            .font(.pretendard(12, weight: .medium))
                            .foregroundStyle(PSColor.textFaint)
                    }

                    Text(event.title)
                        .font(.pretendard(15, weight: .semibold))
                        .foregroundStyle(PSColor.textPrimary)
                        .lineLimit(2)

                    Text("↳ \(event.reason)")
                        .font(.pretendard(12, weight: .regular))
                        .foregroundStyle(PSColor.primary)
                        .lineLimit(2)
                }
            }
        }
    }

    private func signalMiniCard(_ event: PolSignalEvent) -> some View {
        Button {
            openDetail(event)
        } label: {
            PolSignalCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        PolSignalTag(text: event.category, style: tagStyle(for: event))
                        Text(event.timeText)
                            .font(.pretendard(12, weight: .medium))
                        .foregroundStyle(PSColor.textSecondary)
                        Spacer()
                        PolSignalBadge(text: "확인", style: .primary)
                    }

                    Text(event.verdict)
                        .font(.pretendard(15, weight: .semibold))
                        .foregroundStyle(PSColor.textPrimary)
                        .lineLimit(2)

                    Text(event.reason)
                        .font(.pretendard(13, weight: .regular))
                        .foregroundStyle(PSColor.textSecondary)
                        .lineLimit(2)

                    Text("내 노출 · \(event.exposureSummary)")
                        .font(.pretendard(12, weight: .medium))
                        .foregroundStyle(PSColor.textFaint)
                }
            }
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    private func tagStyle(for event: PolSignalEvent) -> PolSignalTagStyle {
        switch event.category {
        case "반도체":
            return .semi
        case "정책", "학습":
            return .policy
        case "환율", "금리":
            return .rate
        default:
            return .primary
        }
    }

    private func openDetail(_ event: PolSignalEvent) {
        navigationPath.append(.detail(event.id))
    }

    private func openProposalSheet() {
        isProposalSheetPresented = true
    }

    private func consumeExternalRoute() {
        guard let route = externalRoute else { return }
        switch route {
        case .list:
            navigationPath = []
        case .detail:
            navigationPath = [route]
        case .adjustment:
            isProposalSheetPresented = true
        case .policyReader:
            navigationPath = [route]
        case .themeDetail:
            navigationPath = [route]
        }
        externalRoute = nil
    }
}

private struct PolSignalDetailView: View {
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

private struct PolSignalAdjustmentProposalSheetView: View {
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

#Preview {
    SignalView()
}
