import SwiftUI

struct OnboardingStep7BrokerageView: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    let userId: Int64?
    let onBack: () -> Void
    let onNext: () -> Void
    let onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isProgressCollapsed = false
    @State private var isSkipConfirmationPresented = false
    @State private var isLinking = false
    @State private var isLinkCompleted = false
    @State private var isRevealed = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var canSubmit: Bool {
        viewModel.connectedInstitutionID != nil
    }

    private var primaryButtonTitle: String {
        if viewModel.connectedInstitutionID == nil {
            return "증권사를 선택해주세요"
        }

        return "모의투자 계좌 연결하기"
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            OnboardingProgressScrollAnchor()

            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    LiquidGlassBackButton(accessibilityLabel: "뒤로", action: onBack)

                    Spacer()
                }

                OnboardingV3QuestionHeader(
                    title: "모의투자 계좌를 연결해주세요",
                    subtitle: "한국투자증권 모의투자 계좌로 실제와 동일한 분석을 체험할 수 있어요."
                )

                BrokerageTrustBlock()
                    .onboardingReveal(isRevealed: isRevealed)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.brokerageInstitutions) { institution in
                        BrokerInstitutionCard(
                            institution: institution,
                            isSelected: viewModel.connectedInstitutionID == institution.id,
                            isConnectable: viewModel.canConnect(institution),
                            hasActiveSelection: viewModel.connectedInstitutionID != nil
                        ) {
                            withAnimation(reduceMotion ? nil : .spring(response: 0.2, dampingFraction: 0.6)) {
                                viewModel.selectInstitution(institution)
                            }
                        }
                    }
                }
                .onboardingReveal(isRevealed: isRevealed, index: 1)

                if viewModel.connectedInstitutionID != nil {
                    DemoAccountNoticeCard()
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, OnboardingV3Layout.horizontalPadding)
            .padding(.top, OnboardingV3Layout.progressContentTopPadding)
            .padding(.bottom, 150)
            .frame(maxWidth: OnboardingV3Layout.maxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .trackOnboardingProgressScroll(isCollapsed: $isProgressCollapsed)
        .onboardingProgressOverlay(step: 7, totalSteps: 8, isCollapsed: isProgressCollapsed)
        .safeAreaInset(edge: .bottom) {
            OnboardingV3BottomBar {
                VStack(spacing: 10) {
                    OnboardingV3PrimaryButton(
                        title: primaryButtonTitle,
                        isEnabled: canSubmit && !isLinking
                    ) {
                        submit()
                    }

                    OnboardingV3SecondaryButton(title: "나중에 연결하기") {
                        isSkipConfirmationPresented = true
                    }
                }
            }
        }
        .confirmationDialog(
            "계좌 없이 시작할 수 있어요\n일부 기능은 연결 후 사용 가능해요",
            isPresented: $isSkipConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("지금은 건너뛸게요") {
                viewModel.skipBrokerageConnection()
                onSkip()
            }

            Button("계좌 연결하기", role: .cancel) {}
        }
        .onboardingV3Background()
        .onboardingRevealSequence(isRevealed: $isRevealed, reduceMotion: reduceMotion)
        .overlay {
            if isLinking {
                BrokerageLinkProgressOverlay(
                    activeStage: viewModel.activeLinkStage,
                    completedStages: viewModel.completedLinkStages,
                    linkedAccount: isLinkCompleted ? viewModel.linkedAccount : nil,
                    isCompleted: isLinkCompleted
                )
                .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: isLinking)
    }

    private func submit() {
        isLinking = true
        Task {
            await viewModel.connectBrokerage(userId: userId, reduceMotion: reduceMotion)

            withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.75)) {
                isLinkCompleted = true
            }

            // 완료 상태를 한 박자 보여준 뒤 다음 스텝으로 넘긴다.
            try? await Task.sleep(nanoseconds: reduceMotion ? 500_000_000 : 1_200_000_000)
            isLinking = false
            onNext()
        }
    }
}

/// 연결 진행 오버레이. 단계별 체크는 실제 요청(연동 생성 + 모의투자 잔고 조회) 진행에 맞춰 채워진다.
private struct BrokerageLinkProgressOverlay: View {
    let activeStage: BrokerageLinkStage?
    let completedStages: Set<BrokerageLinkStage>
    let linkedAccount: LinkedDemoAccount?
    let isCompleted: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                header

                if isCompleted {
                    completionSummary
                } else {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(BrokerageLinkStage.allCases) { stage in
                            stageRow(stage)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(OnboardingV3Theme.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(OnboardingV3Theme.border, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.12), radius: 24, y: 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(OnboardingV3Theme.selectedBackground)
                    .frame(width: 56, height: 56)

                Image(systemName: isCompleted ? "checkmark" : "link")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(OnboardingV3Theme.primary)
            }

            Text(isCompleted ? "연결 완료" : "계좌를 연결하고 있어요")
                .font(.pretendard(18, weight: .bold))
                .foregroundStyle(Color.textPrimary)
        }
    }

    @ViewBuilder
    private var completionSummary: some View {
        VStack(spacing: 6) {
            Text("한국투자증권 모의투자")
                .font(.pretendard(14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            if let masked = linkedAccount?.maskedAccountNumber {
                Text(masked)
                    .font(.pretendard(13, weight: .regular))
                    .foregroundStyle(OnboardingV3Theme.muted)
            }

            if let holdingCount = linkedAccount?.holdingCount {
                Text("보유 종목 \(holdingCount)개를 불러왔어요")
                    .font(.pretendard(13, weight: .regular))
                    .foregroundStyle(OnboardingV3Theme.muted)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func stageRow(_ stage: BrokerageLinkStage) -> some View {
        let isDone = completedStages.contains(stage)
        let isActive = activeStage == stage

        return HStack(spacing: 10) {
            ZStack {
                if isDone {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(OnboardingV3Theme.primary)
                } else if isActive {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Circle()
                        .stroke(OnboardingV3Theme.border, lineWidth: 1.2)
                        .frame(width: 18, height: 18)
                }
            }
            .frame(width: 20, height: 20)

            Text(stage.title)
                .font(.pretendard(13, weight: isActive ? .semibold : .regular))
                .foregroundStyle(isDone || isActive ? Color.textPrimary : OnboardingV3Theme.muted)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isDone)
    }

    private var accessibilityText: String {
        guard !isCompleted else {
            return "모의투자 계좌 연결이 완료되었습니다"
        }

        return activeStage?.title ?? "계좌를 연결하고 있어요"
    }
}

/// 앱키·시크릿은 서버가 보유하므로 사용자가 입력할 정보가 없다는 사실을 명시한다.
/// 로그인 정보를 요구하지 않는다는 점 자체가 이 화면에서 가장 중요한 신뢰 신호라 카드로 띄운다.
private struct DemoAccountNoticeCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(OnboardingV3Theme.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text("입력할 정보가 없어요")
                    .font(.pretendard(15, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text("증권사 아이디나 비밀번호를 묻지 않습니다. 연결 버튼만 누르면 모의투자 계좌가 바로 연결돼요.")
                    .font(.pretendard(13, weight: .regular))
                    .foregroundStyle(OnboardingV3Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(OnboardingV3Theme.selectedBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(OnboardingV3Theme.primary.opacity(0.35), lineWidth: 1)
        }
    }
}

private struct BrokerageTrustBlock: View {
    var body: some View {
        VStack(spacing: 14) {
            BrokerageTrustRow(
                icon: "flask",
                title: "모의투자 계좌",
                description: "실제 자산이나 실계좌는 사용되지 않아요"
            )

            BrokerageTrustRow(
                icon: "eye",
                title: "잔고 조회만 사용",
                description: "보유 종목과 평가금액만 분석에 씁니다. 주문 API는 호출하지 않아요"
            )

            BrokerageTrustRow(
                icon: "clock",
                title: "나중에 연결 가능",
                description: "건너뛰어도 언제든 다시 설정할 수 있어요"
            )
        }
        .padding(16)
        .background(OnboardingV3Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(OnboardingV3Theme.border, lineWidth: 1)
        }
    }
}

private struct BrokerageTrustRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(OnboardingV3Theme.selectedBackground)
                .frame(width: 34, height: 34)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(OnboardingV3Theme.primary)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.pretendard(15, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text(description)
                    .font(.pretendard(13, weight: .regular))
                    .foregroundStyle(OnboardingV3Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BrokerInstitutionCard: View {
    let institution: AccountInstitution
    let isSelected: Bool
    let isConnectable: Bool
    let hasActiveSelection: Bool
    let onTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false

    var body: some View {
        Button {
            guard isConnectable else { return }
            onTap()
            playSelectionPulse()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    if isSelected {
                        OnboardingV3SelectionCheck(isSelected: true)
                    } else {
                        Circle()
                            .stroke(isConnectable ? OnboardingV3Theme.primary : OnboardingV3Theme.border, lineWidth: 1.2)
                            .frame(width: 22, height: 22)
                    }

                    Spacer()

                    if !isConnectable {
                        Text("준비 중")
                            .font(.pretendard(10, weight: .bold))
                            .foregroundStyle(OnboardingV3Theme.muted)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(Color(hex: "F1F5F9"), in: Capsule(style: .continuous))
                    }
                }

                Spacer(minLength: 4)

                brokerMark
                    .frame(maxWidth: .infinity)

                Text(institution.shortDisplayName)
                    .font(.pretendard(14, weight: .bold))
                    .foregroundStyle(isConnectable ? Color.textPrimary : Color.textDisabled)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .frame(height: 126)
            .background(cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(cardBorder, lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isConnectable)
        .scaleEffect(isPulsing ? 1.04 : 1)
        .opacity(cardOpacity)
        .animation(reduceMotion ? nil : .spring(response: 0.2, dampingFraction: 0.6), value: isPulsing)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: hasActiveSelection)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: isSelected)
    }

    private var cardBackground: Color {
        if isSelected {
            return OnboardingV3Theme.selectedBackground
        }

        if isConnectable {
            return OnboardingV3Theme.cardBackground
        }

        return Color(hex: "F8FAFC")
    }

    private var cardBorder: Color {
        if isSelected {
            return OnboardingV3Theme.primary
        }

        return OnboardingV3Theme.border
    }

    private var cardOpacity: Double {
        if hasActiveSelection, !isSelected {
            return 0.5
        }

        return isConnectable ? 1 : 0.62
    }

    private func playSelectionPulse() {
        guard !reduceMotion else { return }
        isPulsing = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            isPulsing = false
        }
    }

    @ViewBuilder
    private var brokerMark: some View {
        if institution.id == AccountInstitution.koreaInvestmentID {
            Image("hantoo")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
        } else {
            Text(brandMark)
                .font(.pretendard(24, weight: .bold))
                .foregroundStyle(Color(hex: institution.accentHex).opacity(isConnectable ? 0.95 : 0.45))
                .frame(width: 44, height: 44)
        }
    }

    private var brandMark: String {
        switch institution.id {
        case "kiwoom":
            return "키"
        case "samsung_securities":
            return "삼"
        case "mirae":
            return "M"
        case "nh_invest":
            return "NH"
        case "shinhan_invest":
            return "신"
        default:
            return institution.emoji
        }
    }
}

private extension AccountInstitution {
    var shortDisplayName: String {
        name
            .replacingOccurrences(of: "투자증권", with: "")
            .replacingOccurrences(of: "증권", with: "")
    }
}

#Preview {
    OnboardingStep7BrokerageView(viewModel: OnboardingFlowViewModel(), userId: nil, onBack: {}, onNext: {}, onSkip: {})
        .preferredColorScheme(.light)
}
