import SwiftUI

struct OnboardingStep8CompletionView: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    let userId: Int64?
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var activeStep: CompletionStep?
    @State private var completedSteps: Set<CompletionStep> = []
    @State private var showsCompletion = false
    @State private var showsCompletionContent = false
    @State private var showsCompletionShimmer = false
    @State private var showsStartButton = false
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
                    reduceMotion: reduceMotion,
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
                    reduceMotion: reduceMotion
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

        for step in steps {
            await setActive(step)
            await perform(step)
            await markCompleted(step)
        }

        try? await Task.sleep(nanoseconds: 300_000_000)
        await revealCompletion()
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
            if !viewModel.isBrokerageCredentialSubmitted {
                await viewModel.submitBrokerageConnectionIfNeeded(userId: userId)
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
            showsCompletion = true
            showsCompletionContent = true
            showsStartButton = true
            return
        }

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

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

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
    let reduceMotion: Bool
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

                Text("맞춤 설정을 반영했어요")
                    .font(.pretendard(15, weight: .regular))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(showsContent ? 1 : 0)

            if showsStartButton {
                OnboardingV3PrimaryButton(title: "시작하기", action: onStart)
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
