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


#Preview {
    SignalView()
}
