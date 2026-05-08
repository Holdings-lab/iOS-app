import SwiftUI

struct OnboardingBrokerageLoadingView: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    let onNext: () -> Void

    @State private var activeStageIndex = 0
    @State private var isCompleted = false
    @State private var hasStarted = false

    private let stages: [BrokerageSyncStage] = [
        .authentication,
        .balance,
        .holdings,
    ]

    var body: some View {
        PFContentScrollView(
            alignment: .leading,
            spacing: 24,
            horizontalPadding: MidnightLayout.horizontal,
            topPadding: 16,
            bottomPadding: 120
        ) {
            FlowProgressHeader(currentStep: 3, totalSteps: 4, showsBack: false, onBack: {})

            VStack(alignment: .leading, spacing: 10) {
                Text(isCompleted ? "계좌 정보 준비가 끝났어요" : "계좌 정보를 불러오고 있어요")
                    .font(.pretendard(28, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text(
                    isCompleted
                    ? "이제 실계좌 기준 잔고와 보유 종목을 분석에 반영할 수 있어요."
                    : "읽기 전용으로 인증을 확인하고, 잔고와 보유 종목을 순서대로 조회하는 중입니다."
                )
                .font(.pretendard(15, weight: .regular))
                .foregroundStyle(Color.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
            }

            institutionCard

            VStack(spacing: 12) {
                ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                    BrokerageSyncStageRow(
                        stage: stage,
                        state: stageState(for: index)
                    )
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            FlowPrimaryButton(
                title: isCompleted ? "다음" : "불러오는 중...",
                isEnabled: isCompleted,
                action: onNext
            )
            .padding(.horizontal, MidnightLayout.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 12)
        }
        .background(PFGradientBackground())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await runSequenceIfNeeded()
        }
    }

    private var institutionCard: some View {
        FlowSurfaceCard {
            HStack(spacing: 14) {
                SelectedInstitutionBadge(
                    institution: viewModel.connectedInstitution ?? viewModel.recommendedInstitution,
                    size: 60
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.connectedInstitutionSummary)
                        .font(.pretendard(17, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)

                    Text(isCompleted ? "조회 준비 완료" : "계좌 인증과 데이터 조회를 진행 중")
                        .font(.pretendard(13, weight: .medium))
                        .foregroundStyle(isCompleted ? Color.brand : Color.textTertiary)
                }

                Spacer()

                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.brand)
                } else {
                    ProgressView()
                        .tint(Color.brand)
                }
            }
        }
    }

    private func stageState(for index: Int) -> BrokerageSyncStageState {
        if isCompleted {
            return .done
        }

        if index < activeStageIndex {
            return .done
        }

        if index == activeStageIndex {
            return .active
        }

        return .waiting
    }

    private func runSequenceIfNeeded() async {
        guard !hasStarted else { return }
        hasStarted = true

        for index in stages.indices {
            await MainActor.run {
                activeStageIndex = index
            }

            try? await Task.sleep(nanoseconds: 900_000_000)
        }

        await MainActor.run {
            isCompleted = true
        }
    }
}

private enum BrokerageSyncStage {
    case authentication
    case balance
    case holdings

    var title: String {
        switch self {
        case .authentication:
            return "증권사 인증 확인"
        case .balance:
            return "계좌 잔고 조회"
        case .holdings:
            return "보유 종목 분석 준비"
        }
    }

    var subtitle: String {
        switch self {
        case .authentication:
            return "읽기 전용 연결 상태를 검증하고 있어요."
        case .balance:
            return "총 평가금액과 현금 비중을 불러오는 중입니다."
        case .holdings:
            return "보유 ETF와 종목을 분석 화면에 반영할 준비를 하고 있어요."
        }
    }

    var icon: String {
        switch self {
        case .authentication:
            return "lock.shield"
        case .balance:
            return "chart.bar.doc.horizontal"
        case .holdings:
            return "list.bullet.rectangle"
        }
    }
}

private enum BrokerageSyncStageState {
    case waiting
    case active
    case done
}

private struct BrokerageSyncStageRow: View {
    let stage: BrokerageSyncStage
    let state: BrokerageSyncStageState

    var body: some View {
        FlowSurfaceCard {
            HStack(alignment: .top, spacing: 14) {
                leadingIndicator

                VStack(alignment: .leading, spacing: 5) {
                    Text(stage.title)
                        .font(.pretendard(15, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)

                    Text(stage.subtitle)
                        .font(.pretendard(13, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                trailingLabel
            }
        }
    }

    @ViewBuilder
    private var leadingIndicator: some View {
        switch state {
        case .done:
            Circle()
                .fill(Color.brand.opacity(0.16))
                .frame(width: 34, height: 34)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.brand)
                }
        case .active:
            Circle()
                .stroke(Color.brand.opacity(0.28), lineWidth: 1.5)
                .frame(width: 34, height: 34)
                .overlay {
                    ProgressView()
                        .tint(Color.brand)
                }
        case .waiting:
            Circle()
                .fill(Color.subtle)
                .frame(width: 34, height: 34)
                .overlay {
                    Image(systemName: stage.icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.textDisabled)
                }
        }
    }

    @ViewBuilder
    private var trailingLabel: some View {
        switch state {
        case .done:
            Text("완료")
                .font(.pretendard(12, weight: .semibold))
                .foregroundStyle(Color.brand)
        case .active:
            Text("진행 중")
                .font(.pretendard(12, weight: .semibold))
                .foregroundStyle(Color.brand)
        case .waiting:
            Text("대기")
                .font(.pretendard(12, weight: .medium))
                .foregroundStyle(Color.textDisabled)
        }
    }
}

#Preview {
    OnboardingBrokerageLoadingView(
        viewModel: OnboardingFlowViewModel(),
        onNext: {}
    )
    .preferredColorScheme(.light)
}
