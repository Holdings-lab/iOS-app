import SwiftUI

struct OnboardingStep8CompletionView: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    let userId: Int64?
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var activeStep: CompletionStep?
    @State private var completedSteps: Set<CompletionStep> = []
    @State private var progressPercent: Int = 0
    @State private var showsCompletion = false
    @State private var showsCompletionContent = false
    @State private var showsCompletionShimmer = false
    @State private var showsStartButton = false
    @State private var isStartButtonInteractive = false
    @State private var didStart = false

    private var isAccountConnected: Bool {
        viewModel.connectedInstitutionID != nil
    }

    private var steps: [CompletionStep] {
        isAccountConnected ? [.settings, .watchAssets, .goal] : [.settings, .watchAssets]
    }

    var body: some View {
        ZStack {
            Color.canvas
                .ignoresSafeArea()

            if showsCompletion {
                CompletionPhase(
                    showsContent: showsCompletionContent,
                    showsShimmer: showsCompletionShimmer,
                    showsStartButton: showsStartButton,
                    isStartButtonInteractive: isStartButtonInteractive,
                    reduceMotion: reduceMotion,
                    userName: viewModel.userName,
                    onStart: onComplete
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                    removal: .opacity
                ))
            } else {
                ProgressPhase(
                    steps: steps,
                    activeStep: activeStep,
                    completedSteps: completedSteps,
                    reduceMotion: reduceMotion,
                    userName: viewModel.userName,
                    progressPercent: progressPercent
                )
                .transition(.opacity)
            }
        }
        .task {
            await runCompletionSequence()
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.light)
    }

    private func runCompletionSequence() async {
        guard !didStart else { return }
        didStart = true

        async let percentAnimation: Void = driveProgressPercent()

        for step in steps {
            await setActive(step)
            await perform(step)
            await markCompleted(step)
        }

        // 실제 네트워크 완료가 아무리 빨라도, 코스를 만드는 듯한 최소한의 체감 시간은 percentAnimation이 보장한다.
        await percentAnimation

        try? await Task.sleep(nanoseconds: 300_000_000)
        await revealCompletion()
    }

    /// 실제 요청 완료 여부와 무관하게 0→99%까지 감속 곡선으로 채워지는 연출용 카운터.
    /// 90%대 초반부터 속도를 늦춰, 서버 응답을 기다리는 동안 화면이 "거의 다 됐다"는 인상을 유지하게 한다.
    @MainActor
    private func driveProgressPercent() async {
        guard !reduceMotion else {
            progressPercent = 99
            return
        }

        withAnimation(.easeOut(duration: 2.4)) {
            progressPercent = 88
        }
        try? await Task.sleep(nanoseconds: 2_400_000_000)

        withAnimation(.easeInOut(duration: 1.1)) {
            progressPercent = 99
        }
        try? await Task.sleep(nanoseconds: 1_100_000_000)
    }

    /// 서버가 요청을 정상 수신했다는 응답이 오면 그 즉시 체크 표시로 넘어간다. 아직 서버가 응답하지
    /// 않거나(현재 백엔드 미구현) 실패하면, 로딩 아이콘을 일정 시간 더 보여준 뒤 목업으로 완료 처리한다.
    private func perform(_ step: CompletionStep) async {
        let succeeded: Bool

        switch step {
        case .settings:
            succeeded = await viewModel.submitSettings(userId: userId)
        case .watchAssets:
            succeeded = await viewModel.submitWatchAssets(userId: userId)
        case .goal:
            if !viewModel.isBrokerageConnected {
                await viewModel.connectBrokerage(userId: userId, reduceMotion: reduceMotion)
            }
            succeeded = await viewModel.submitGoal(userId: userId)
        }

        guard !succeeded else { return }
        try? await Task.sleep(nanoseconds: reduceMotion ? 150_000_000 : 700_000_000)
    }

    @MainActor
    private func setActive(_ step: CompletionStep) async {
        if reduceMotion {
            activeStep = step
        } else {
            withAnimation(.easeInOut(duration: 0.15)) {
                activeStep = step
            }
        }
    }

    @MainActor
    private func markCompleted(_ step: CompletionStep) async {
        if reduceMotion {
            _ = completedSteps.insert(step)
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                _ = completedSteps.insert(step)
            }
        }
    }

    @MainActor
    private func revealCompletion() async {
        if reduceMotion {
            // 애니메이션 커브는 생략하지만, 100%가 눈에 들어올 시간 없이 완료 화면·버튼까지
            // 한 프레임에 동시 등장하지 않도록 최소한의 페이싱은 유지한다.
            progressPercent = 100
            try? await Task.sleep(nanoseconds: 500_000_000)
            showsCompletion = true
            showsCompletionContent = true
            try? await Task.sleep(nanoseconds: 300_000_000)
            showsStartButton = true
            try? await Task.sleep(nanoseconds: 200_000_000)
            isStartButtonInteractive = true
            return
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
            progressPercent = 100
        }
        // 스프링이 실제로 안착해 "100%"가 또렷이 보일 시간을 확보한 뒤에 다음 화면으로 넘어간다.
        try? await Task.sleep(nanoseconds: 550_000_000)

        withAnimation(.easeInOut(duration: 0.25)) {
            showsCompletion = true
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showsCompletionContent = true
        }

        try? await Task.sleep(nanoseconds: 100_000_000)
        withAnimation(.easeInOut(duration: 0.2)) {
            showsCompletionShimmer = true
        }

        try? await Task.sleep(nanoseconds: 400_000_000)
        withAnimation(.easeInOut(duration: 0.2)) {
            showsCompletionShimmer = false
        }

        try? await Task.sleep(nanoseconds: 100_000_000)
        withAnimation(.easeOut(duration: 0.25)) {
            showsStartButton = true
        }

        // 버튼이 페이드인되는 동안은 탭이 되어도 반응하지 않게 해, 온보딩을 빠르게 넘기던
        // 습관적인 탭이 실수로 "시작하기"를 눌러버리는 것을 막는다.
        try? await Task.sleep(nanoseconds: 250_000_000)
        isStartButtonInteractive = true
    }
}

private enum CompletionStep: CaseIterable, Identifiable, Hashable {
    case settings
    case watchAssets
    case goal

    var id: String { title }

    var title: String {
        switch self {
        case .settings: return "맞춤 설정 저장"
        case .watchAssets: return "관심 분야 저장"
        case .goal: return "투자 목표 저장"
        }
    }

    var icon: String {
        switch self {
        case .settings: return "slider.horizontal.3"
        case .watchAssets: return "star"
        case .goal: return "target"
        }
    }
}

private struct ProgressPhase: View {
    let steps: [CompletionStep]
    let activeStep: CompletionStep?
    let completedSteps: Set<CompletionStep>
    let reduceMotion: Bool
    let userName: String
    let progressPercent: Int

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text("\(progressPercent)%")
                    .font(.pretendard(52, weight: .bold))
                    .foregroundStyle(Color.brand)
                    .contentTransition(.numericText(value: Double(progressPercent)))
                    .monospacedDigit()

                Text("\(userName)님의 맞춤 포트폴리오 만드는 중")
                    .font(.pretendard(15, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
            }

            VStack(spacing: 16) {
                ForEach(steps) { step in
                    StepRow(
                        step: step,
                        state: state(for: step),
                        reduceMotion: reduceMotion
                    )
                }
            }
            .padding(.horizontal, OnboardingV3Layout.horizontalPadding)
            .frame(maxWidth: OnboardingV3Layout.maxWidth)
            .frame(maxWidth: .infinity)

            Spacer()
        }
    }

    private func state(for step: CompletionStep) -> StepState {
        if completedSteps.contains(step) {
            return .completed
        }

        if activeStep == step {
            return .active
        }

        return .waiting
    }
}

private enum StepState {
    case completed
    case active
    case waiting
}

private struct StepRow: View {
    let step: CompletionStep
    let state: StepState
    let reduceMotion: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: step.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 24)

            Text(step.title)
                .font(.pretendard(16, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            Spacer()

            statusView
                .frame(width: 26, height: 26)
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
        .opacity(state == .completed ? 0.5 : 1)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: state == .completed)
    }

    @ViewBuilder
    private var statusView: some View {
        switch state {
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color(hex: "10B981"))
                .transition(.scale(scale: 0.5).combined(with: .opacity))
                .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.65), value: state == .completed)
        case .active:
            ProgressView()
                .controlSize(.small)
                .tint(Color.brand)
        case .waiting:
            Circle()
                .stroke(Color.hairline, lineWidth: 1.4)
                .frame(width: 18, height: 18)
        }
    }

    private var iconColor: Color {
        switch state {
        case .completed:
            return Color.textTertiary
        case .active:
            return Color.brand
        case .waiting:
            return Color.textTertiary
        }
    }
}

private struct CompletionPhase: View {
    let showsContent: Bool
    let showsShimmer: Bool
    let showsStartButton: Bool
    let isStartButtonInteractive: Bool
    let reduceMotion: Bool
    let userName: String
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Circle()
                .fill(Color.brand.opacity(0.1))
                .frame(width: 72, height: 72)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 31, weight: .bold))
                        .foregroundStyle(Color.brand)
                }
                .brightness(showsShimmer ? 0.15 : 0)
                .scaleEffect(showsContent ? 1 : 0.01)
                .opacity(showsContent ? 1 : 0)
                .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.6), value: showsContent)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: showsShimmer)

            VStack(spacing: 8) {
                Text("설정 완료")
                    .font(.pretendard(24, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text("\(userName)님을 위한 맞춤 설정을 반영했어요")
                    .font(.pretendard(15, weight: .regular))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(showsContent ? 1 : 0)

            if showsStartButton {
                OnboardingV3PrimaryButton(title: "시작하기", action: onStart)
                    // 버튼이 막 나타난 직후, 습관적으로 이어지던 탭이 실수로 눌리지 않도록 짧게 막아둔다.
                    .allowsHitTesting(isStartButtonInteractive)
            }
        }
        .padding(.horizontal, OnboardingV3Layout.horizontalPadding)
        .frame(maxWidth: OnboardingV3Layout.maxWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: showsStartButton)
    }
}

#Preview {
    OnboardingStep8CompletionView(viewModel: OnboardingFlowViewModel(), userId: nil, onComplete: {})
        .preferredColorScheme(.light)
}
