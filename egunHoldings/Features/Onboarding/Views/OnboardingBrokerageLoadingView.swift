import SwiftUI

struct OnboardingBrokerageLoadingView: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var activeStep: BrokerageConnectionStep? = .account
    @State private var completedSteps: Set<BrokerageConnectionStep> = []
    @State private var showsCompletion = false
    @State private var showsCompletionContent = false
    @State private var showsCompletionShimmer = false
    @State private var showsStartButton = false
    @State private var didStart = false

    private var selectedInstitution: AccountInstitution {
        viewModel.connectedInstitution ?? viewModel.recommendedInstitution
    }

    var body: some View {
        ZStack {
            Color.canvas
                .ignoresSafeArea()

            if showsCompletion {
                BrokerageConnectionCompletePhase(
                    holdingsCount: nil,
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
                BrokerageConnectionProgressPhase(
                    institution: selectedInstitution,
                    activeStep: activeStep,
                    completedSteps: completedSteps,
                    reduceMotion: reduceMotion
                )
                .transition(.opacity)
            }
        }
        .task(id: reduceMotion) {
            await startSequenceIfNeeded(reduceMotion: reduceMotion)
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.light)
    }

    private func startSequenceIfNeeded(reduceMotion: Bool) async {
        guard !didStart else { return }
        didStart = true

        let stepDelay: UInt64 = reduceMotion ? 150_000_000 : 700_000_000
        let completionDelay: UInt64 = reduceMotion ? 100_000_000 : 400_000_000

        await MainActor.run {
            activeStep = .account
            completedSteps = []
            showsCompletion = false
            showsCompletionContent = false
            showsCompletionShimmer = false
            showsStartButton = false
        }

        for step in BrokerageConnectionStep.allCases {
            await MainActor.run {
                if reduceMotion {
                    activeStep = step
                } else {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        activeStep = step
                    }
                }
            }

            try? await Task.sleep(nanoseconds: stepDelay)

            await MainActor.run {
                if reduceMotion {
                    _ = completedSteps.insert(step)
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                        _ = completedSteps.insert(step)
                    }
                }
            }
        }

        try? await Task.sleep(nanoseconds: completionDelay)

        await MainActor.run {
            if reduceMotion {
                showsCompletion = true
                showsCompletionContent = true
                showsStartButton = true
            } else {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showsCompletion = true
                }
            }
        }

        guard !reduceMotion else { return }

        await MainActor.run {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showsCompletionContent = true
            }
        }

        try? await Task.sleep(nanoseconds: 100_000_000)
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.2)) {
                showsCompletionShimmer = true
            }
        }

        try? await Task.sleep(nanoseconds: 400_000_000)
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.2)) {
                showsCompletionShimmer = false
            }
        }

        try? await Task.sleep(nanoseconds: 100_000_000)
        await MainActor.run {
            withAnimation(.easeOut(duration: 0.25)) {
                showsStartButton = true
            }
        }
    }
}

private enum BrokerageConnectionStep: CaseIterable, Identifiable, Hashable {
    case account
    case balance
    case holdings

    var id: String {
        title
    }

    var title: String {
        switch self {
        case .account:
            return "계정 확인"
        case .balance:
            return "잔고 불러오기"
        case .holdings:
            return "종목 동기화"
        }
    }

    var icon: String {
        switch self {
        case .account:
            return "person.crop.circle"
        case .balance:
            return "banknote"
        case .holdings:
            return "chart.pie"
        }
    }
}

private struct BrokerageConnectionProgressPhase: View {
    let institution: AccountInstitution
    let activeStep: BrokerageConnectionStep?
    let completedSteps: Set<BrokerageConnectionStep>
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                BrokerageConnectionBridge(institution: institution, reduceMotion: reduceMotion)
                    .frame(height: proxy.size.height * 0.32)

                VStack(spacing: 16) {
                    ForEach(BrokerageConnectionStep.allCases) { step in
                        BrokerageConnectionStepRow(
                            step: step,
                            state: state(for: step),
                            reduceMotion: reduceMotion
                        )
                    }
                }
                .padding(.horizontal, OnboardingV3Layout.horizontalPadding)
                .frame(maxWidth: OnboardingV3Layout.maxWidth)
                .frame(maxWidth: .infinity)

                Spacer(minLength: 24)

                BrokerageConnectionPermissionNote()
                    .padding(.horizontal, OnboardingV3Layout.horizontalPadding)
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom, 24))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func state(for step: BrokerageConnectionStep) -> BrokerageConnectionStepState {
        if completedSteps.contains(step) {
            return .completed
        }

        if activeStep == step {
            return .active
        }

        return .waiting
    }
}

private struct BrokerageConnectionBridge: View {
    let institution: AccountInstitution
    let reduceMotion: Bool

    var body: some View {
        HStack(spacing: 18) {
            BrokerageLogoCircle(institution: institution)

            BrokerageAnimatedDots(reduceMotion: reduceMotion)

            AppLogoCircle()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 18)
    }
}

private struct BrokerageLogoCircle: View {
    let institution: AccountInstitution

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)

            if institution.id == AccountInstitution.koreaInvestmentID {
                Image("hantoo")
                    .resizable()
                    .scaledToFit()
                    .padding(7)
            } else {
                Text(mark)
                    .font(.pretendard(15, weight: .bold))
                    .foregroundStyle(Color(hex: institution.accentHex))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 5)
            }
        }
        .frame(width: 40, height: 40)
        .overlay {
            Circle()
                .stroke(Color.hairline, lineWidth: 1)
        }
    }

    private var mark: String {
        let cleanedName = institution.name
            .replacingOccurrences(of: "투자증권", with: "")
            .replacingOccurrences(of: "증권", with: "")

        return String(cleanedName.prefix(2))
    }
}

private struct AppLogoCircle: View {
    var body: some View {
        Circle()
            .fill(Color.brand)
            .frame(width: 40, height: 40)
            .overlay {
                Text("P")
                    .font(.pretendard(19, weight: .bold))
                    .foregroundStyle(Color.white)
            }
    }
}

private struct BrokerageAnimatedDots: View {
    let reduceMotion: Bool
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.brand)
                    .frame(width: 6, height: 6)
                    .opacity(reduceMotion ? 0.7 : (isAnimating ? 1 : 0.2))
                    .animation(
                        reduceMotion
                            ? nil
                            : .easeInOut(duration: 0.45)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.15),
                        value: isAnimating
                    )
            }
        }
        .frame(width: 54)
        .onAppear {
            guard !reduceMotion else { return }
            isAnimating = true
        }
    }
}

private enum BrokerageConnectionStepState {
    case completed
    case active
    case waiting
}

private struct BrokerageConnectionStepRow: View {
    let step: BrokerageConnectionStep
    let state: BrokerageConnectionStepState
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

private struct BrokerageConnectionPermissionNote: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.system(size: 12, weight: .semibold))

            Text("주문 권한은 요청하지 않아요")
                .font(.pretendard(13, weight: .regular))
        }
        .foregroundStyle(Color.textTertiary)
        .frame(maxWidth: .infinity)
    }
}

private struct BrokerageConnectionCompletePhase: View {
    let holdingsCount: Int?
    let showsContent: Bool
    let showsShimmer: Bool
    let showsStartButton: Bool
    let reduceMotion: Bool
    let onStart: () -> Void

    private var subtitle: String {
        guard let holdingsCount, holdingsCount > 0 else {
            return "보유 종목을 불러왔어요"
        }

        return "\(holdingsCount)개 종목을 불러왔어요"
    }

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
                Text("연결 완료")
                    .font(.pretendard(24, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text(subtitle)
                    .font(.pretendard(15, weight: .regular))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(showsContent ? 1 : 0)

            if showsStartButton {
                OnboardingV3PrimaryButton(title: "시작하기", action: onStart)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, OnboardingV3Layout.horizontalPadding)
        .frame(maxWidth: OnboardingV3Layout.maxWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: showsStartButton)
    }
}

#Preview {
    OnboardingBrokerageLoadingView(
        viewModel: OnboardingFlowViewModel(),
        onComplete: {}
    )
    .preferredColorScheme(.light)
}
