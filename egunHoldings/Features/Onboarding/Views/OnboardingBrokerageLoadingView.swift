import SwiftUI

struct OnboardingBrokerageLoadingView: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    let onSkip: () -> Void
    let onComplete: () -> Void

    @State private var phase: BrokerageLoadingPhase = .connecting
    @State private var activeChecklistIndex = 1
    @State private var completedChecklistCount = 1
    @State private var animatedDotIndex = 0
    @State private var didStart = false

    var body: some View {
        ZStack {
            OnboardingV3Theme.background
                .ignoresSafeArea()

            Group {
                switch phase {
                case .connecting:
                    BrokerageConnectingPhase(dotIndex: animatedDotIndex)
                case .checking:
                    BrokerageChecklistPhase(
                        activeIndex: activeChecklistIndex,
                        completedCount: completedChecklistCount
                    )
                case .completed:
                    BrokerageCompletePhase()
                case .failed(let reason):
                    BrokerageFailurePhase(
                        reason: reason,
                        onRetry: restartSequence,
                        onSkip: onSkip
                    )
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: phase)
        }
        .contentShape(Rectangle())
        .allowsHitTesting(true)
        .task {
            await startSequenceIfNeeded()
        }
        .onboardingV3Background()
    }

    private func startSequenceIfNeeded() async {
        guard !didStart else { return }
        didStart = true
        await runSuccessSequence()
    }

    private func restartSequence() {
        Task {
            phase = .connecting
            activeChecklistIndex = 1
            completedChecklistCount = 1
            await runSuccessSequence()
        }
    }

    private func runSuccessSequence() async {
        await animateConnectionDots(for: 1_500_000_000)

        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                phase = .checking
                activeChecklistIndex = 1
                completedChecklistCount = 1
            }
        }

        for index in 1..<BrokerageChecklistItem.allCases.count {
            try? await Task.sleep(nanoseconds: 1_150_000_000)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    completedChecklistCount = index + 1
                    activeChecklistIndex = min(index + 1, BrokerageChecklistItem.allCases.count - 1)
                }
            }
        }

        try? await Task.sleep(nanoseconds: 350_000_000)
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                phase = .completed
            }
        }

        try? await Task.sleep(nanoseconds: 1_500_000_000)
        await MainActor.run {
            onComplete()
        }
    }

    private func animateConnectionDots(for duration: UInt64) async {
        let startedAt = Date()

        while Date().timeIntervalSince(startedAt) < Double(duration) / 1_000_000_000 {
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    animatedDotIndex = (animatedDotIndex + 1) % 5
                }
            }
            try? await Task.sleep(nanoseconds: 600_000_000)
        }
    }
}

private enum BrokerageLoadingPhase: Equatable {
    case connecting
    case checking
    case completed
    case failed(BrokerageConnectionFailureReason)
}

private enum BrokerageConnectionFailureReason: Equatable {
    case password
    case network
    case server

    var message: String {
        switch self {
        case .password:
            return "증권사 비밀번호를 확인해주세요"
        case .network:
            return "인터넷 연결을 확인하고 다시 시도해주세요"
        case .server:
            return "잠시 후 다시 시도해주세요 (오류코드: E403)"
        }
    }
}

private struct BrokerageConnectingPhase: View {
    let dotIndex: Int

    var body: some View {
        VStack(spacing: 24) {
            BrokerageConnectionBridge(dotIndex: dotIndex)

            VStack(spacing: 9) {
                Text("안전하게 연결하고 있어요")
                    .font(.pretendard(20, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text("🔒 조회 전용 연결이라 거래·이체는 절대 되지 않아요")
                    .font(.pretendard(13, weight: .regular))
                    .foregroundStyle(OnboardingV3Theme.muted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: OnboardingV3Layout.maxWidth)
        .padding(.horizontal, OnboardingV3Layout.horizontalPadding)
    }
}

private struct BrokerageConnectionBridge: View {
    let dotIndex: Int

    var body: some View {
        HStack(spacing: 13) {
            Image("hantoo")
                .resizable()
                .scaledToFit()
                .frame(width: 46, height: 46)
                .padding(10)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(OnboardingV3Theme.border, lineWidth: 1)
                }

            HStack(spacing: 5) {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(index == dotIndex ? OnboardingV3Theme.primary : OnboardingV3Theme.border)
                        .frame(width: index == dotIndex ? 8 : 5, height: index == dotIndex ? 8 : 5)
                        .scaleEffect(index == dotIndex ? 1.18 : 1)
                }

                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(OnboardingV3Theme.primary)
                    .padding(.leading, 2)
            }
            .frame(width: 86)

            Text("P")
                .font(.pretendard(24, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: 58, height: 58)
                .background(OnboardingV3Theme.primary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

private enum BrokerageChecklistItem: String, CaseIterable, Identifiable {
    case authentication = "계좌 인증 완료"
    case holdings = "보유 종목 불러오는 중"
    case balance = "잔고 확인"
    case analysis = "분석 준비"

    var id: String { rawValue }
}

private struct BrokerageChecklistPhase: View {
    let activeIndex: Int
    let completedCount: Int

    var body: some View {
        VStack(spacing: 34) {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(Array(BrokerageChecklistItem.allCases.enumerated()), id: \.element.id) { index, item in
                    BrokerageChecklistRow(
                        title: item.rawValue,
                        state: state(for: index)
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("잠깐이면 돼요. 앱을 닫아도 괜찮아요")
                .font(.pretendard(13, weight: .regular))
                .foregroundStyle(OnboardingV3Theme.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, OnboardingV3Layout.horizontalPadding)
        .frame(maxWidth: OnboardingV3Layout.maxWidth)
    }

    private func state(for index: Int) -> BrokerageChecklistState {
        if index < completedCount {
            return .completed
        }

        if index == activeIndex {
            return .active
        }

        return .waiting
    }
}

private enum BrokerageChecklistState {
    case completed
    case active
    case waiting
}

private struct BrokerageChecklistRow: View {
    let title: String
    let state: BrokerageChecklistState

    var body: some View {
        HStack(spacing: 14) {
            icon
                .frame(width: 28, height: 28)

            Text(title)
                .font(.pretendard(16, weight: .bold))
                .foregroundStyle(textColor)

            Spacer()
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch state {
        case .completed:
            Circle()
                .fill(Color(hex: "10B981"))
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.white)
                }
                .scaleEffect(1)
                .transition(.scale.combined(with: .opacity))
        case .active:
            ProgressView()
                .tint(OnboardingV3Theme.primary)
        case .waiting:
            Circle()
                .stroke(OnboardingV3Theme.border, lineWidth: 1.5)
                .frame(width: 20, height: 20)
        }
    }

    private var textColor: Color {
        switch state {
        case .completed, .active:
            return Color.textPrimary
        case .waiting:
            return OnboardingV3Theme.muted
        }
    }
}

private struct BrokerageCompletePhase: View {
    var body: some View {
        VStack(spacing: 22) {
            Circle()
                .fill(OnboardingV3Theme.primary)
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.white)
                }
                .transition(.scale(scale: 0.78).combined(with: .opacity))

            VStack(spacing: 8) {
                Text("연결됐어요!")
                    .font(.pretendard(24, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text("SOXX, SMH 외 3개 종목을 확인했어요")
                    .font(.pretendard(15, weight: .regular))
                    .foregroundStyle(OnboardingV3Theme.muted)
                    .multilineTextAlignment(.center)
            }

            BrokerageConnectedDataCard()
                .padding(.top, 8)
        }
        .padding(.horizontal, OnboardingV3Layout.horizontalPadding)
        .frame(maxWidth: OnboardingV3Layout.maxWidth)
    }
}

private struct BrokerageConnectedDataCard: View {
    var body: some View {
        HStack(spacing: 0) {
            BrokerageConnectedMetric(title: "총 계좌", value: "1개")
            Divider().frame(height: 34)
            BrokerageConnectedMetric(title: "보유 종목", value: "5개")
            Divider().frame(height: 34)
            BrokerageConnectedMetric(title: "포트폴리오", value: "₩134,829,500")
        }
        .padding(.vertical, 16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(OnboardingV3Theme.border, lineWidth: 1)
        }
    }
}

private struct BrokerageConnectedMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.pretendard(11, weight: .medium))
                .foregroundStyle(OnboardingV3Theme.muted)

            Text(value)
                .font(.pretendard(14, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct BrokerageFailurePhase: View {
    let reason: BrokerageConnectionFailureReason
    let onRetry: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Circle()
                .fill(Color(hex: "F59E0B").opacity(0.16))
                .frame(width: 54, height: 54)
                .overlay {
                    Image(systemName: "exclamationmark")
                        .font(.system(size: 23, weight: .bold))
                        .foregroundStyle(Color(hex: "F59E0B"))
                }

            VStack(spacing: 8) {
                Text("연결에 실패했어요")
                    .font(.pretendard(24, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text(reason.message)
                    .font(.pretendard(15, weight: .regular))
                    .foregroundStyle(OnboardingV3Theme.muted)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                OnboardingV3PrimaryButton(title: "다시 시도", action: onRetry)

                Button("나중에 설정하기", action: onSkip)
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(OnboardingV3Theme.primary)
                    .buttonStyle(.plain)
            }
            .padding(.top, 10)
        }
        .padding(.horizontal, OnboardingV3Layout.horizontalPadding)
        .frame(maxWidth: OnboardingV3Layout.maxWidth)
    }
}

#Preview {
    OnboardingBrokerageLoadingView(
        viewModel: OnboardingFlowViewModel(),
        onSkip: {},
        onComplete: {}
    )
    .preferredColorScheme(.light)
}
