import SwiftUI

struct SettingsGoalView: View {
    @ObservedObject var viewModel: SettingsViewModel
    let onBack: () -> Void

    @State private var goal: FinancialGoal
    @State private var amount: Double
    @State private var showsChangeConfirm = false

    private let initialGoal: FinancialGoal
    private let initialAmount: Int64

    init(viewModel: SettingsViewModel, onBack: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onBack = onBack
        initialGoal = viewModel.financialGoal
        initialAmount = viewModel.targetAmount
        _goal = State(initialValue: viewModel.financialGoal)
        _amount = State(initialValue: Double(viewModel.targetAmount))
    }

    private var preset: SettingsGoalPreset {
        goal.settingsPreset
    }

    private var hasChanges: Bool {
        goal != initialGoal || Int64(amount) != initialAmount
    }

    var body: some View {
        VStack(spacing: 0) {
            SettingsNavHeader(title: "목표 설정", onBack: onBack)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    if viewModel.accounts.isEmpty {
                        CalloutView(tone: .info, icon: "info.circle.fill") {
                            Text("계좌를 연결하지 않아도 목표는 저장돼요. 연결하면 목표 대비 진행률을 보여드려요.")
                        }
                        .padding(.top, 14)
                    }

                    Text("투자 목적")
                        .font(.pretendard(13, weight: .bold))
                        .foregroundStyle(Color.textSecondary)
                        .padding(.top, 14)

                    VStack(spacing: 10) {
                        ForEach(FinancialGoal.allCases) { option in
                            ChoiceCard(
                                isOn: goal == option,
                                icon: option.settingsEmoji,
                                title: option.title,
                                subtitle: goalSubtitle(option)
                            ) {
                                chooseGoal(option)
                            }
                        }
                    }
                    .padding(.top, 8)

                    Text("목표 금액")
                        .font(.pretendard(13, weight: .bold))
                        .foregroundStyle(Color.textSecondary)
                        .padding(.top, 22)

                    amountSliderBlock
                        .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 118)
            }
        }
        .background(Color.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            Button(action: handleSaveTap) {
                Text("저장")
                    .font(.pretendard(14.5, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.brand, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 22)
            .background(.ultraThinMaterial)
        }
        .overlay {
            SettingsConfirmModal(
                isPresented: showsChangeConfirm,
                title: "목표를 변경할까요?",
                desc: "목표를 변경하면 진행 속도 추적이 처음부터 다시 시작돼요.",
                confirmLabel: "변경 저장",
                onConfirm: {
                    showsChangeConfirm = false
                    save()
                },
                onCancel: { showsChangeConfirm = false }
            )
        }
    }

    private func goalSubtitle(_ goal: FinancialGoal) -> String {
        switch goal {
        case .retirement: return "긴 호흡으로 은퇴 후 생활 자금을 쌓아가요"
        case .seedMoney: return "결혼, 창업 등 앞으로의 시작 자금을 준비해요"
        case .surplusFunds: return "당장 쓸 일 없는 자금을 편하게 굴려봐요"
        case .homePurchase: return "주택 구입 시점에 맞춰 자금을 준비해요"
        }
    }

    private func chooseGoal(_ newGoal: FinancialGoal) {
        guard newGoal != goal else { return }
        goal = newGoal
        amount = Double(newGoal.settingsPreset.amount)
    }

    private var amountSliderBlock: some View {
        VStack(spacing: 8) {
            Text(OnboardingCurrencyFormatter.wonText(Int64(amount)))
                .font(.pretendard(26, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .monospacedDigit()

            Text(Int64(amount) == preset.amount ? "제안 금액 그대로" : "직접 조정한 금액")
                .font(.pretendard(12.5, weight: .regular))
                .foregroundStyle(Color.textSecondary)

            Slider(
                value: $amount,
                in: Double(preset.min)...Double(preset.max),
                step: Double(preset.step)
            )
            .tint(Color.brand)
            .padding(.top, 8)
            .accessibilityValue(OnboardingCurrencyFormatter.wonText(Int64(amount)))

            HStack {
                Text(OnboardingCurrencyFormatter.wonText(preset.min))
                Spacer()
                Text(OnboardingCurrencyFormatter.wonText(preset.max))
            }
            .font(.pretendard(11, weight: .semibold))
            .foregroundStyle(Color.textTertiary)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 2)
    }

    private func handleSaveTap() {
        if hasChanges {
            showsChangeConfirm = true
        } else {
            onBack()
        }
    }

    private func save() {
        viewModel.saveGoal(goal: goal, amount: Int64(amount))
        onBack()
    }
}
