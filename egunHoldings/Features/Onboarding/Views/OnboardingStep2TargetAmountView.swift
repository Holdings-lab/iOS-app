import SwiftUI

struct OnboardingStep2TargetAmountView: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    let onNext: () -> Void
    let onBack: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isProgressCollapsed = false
    @State private var amountText = ""
    @State private var isRevealed = false

    private var goal: FinancialGoal {
        viewModel.financialGoal
    }

    private var enteredAmount: Int64? {
        guard let amount = Int64(amountText), amount > 0 else { return nil }
        return amount
    }

    private var sliderAmount: Binding<Double> {
        Binding(
            get: {
                min(max(Double(viewModel.targetAmount), goal.targetAmountSliderRange.lowerBound),
                    goal.targetAmountSliderRange.upperBound)
            },
            set: { setSliderAmount(Int64($0)) }
        )
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            OnboardingProgressScrollAnchor()

            VStack(alignment: .leading, spacing: 24) {
                OnboardingV3StepHeader(step: 2, onBack: onBack)

                OnboardingV3QuestionHeader(
                    title: "목표 금액을 알려주세요",
                    subtitle: "1천만원 단위로 선택하거나 금액을 직접 입력해요"
                )

                VStack(spacing: 20) {
                    Text(OnboardingCurrencyFormatter.wonText(viewModel.targetAmount))
                        .font(.pretendard(32, weight: .bold))
                        .foregroundStyle(OnboardingV3Theme.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)

                    Slider(
                        value: sliderAmount,
                        in: goal.targetAmountSliderRange,
                        step: goal.targetAmountSliderStep
                    )
                    .tint(OnboardingV3Theme.primary)

                    HStack {
                        Text(OnboardingCurrencyFormatter.wonText(Int64(goal.targetAmountSliderRange.lowerBound)))
                        Spacer()
                        Text(OnboardingCurrencyFormatter.wonText(Int64(goal.targetAmountSliderRange.upperBound)))
                    }
                    .font(.pretendard(12, weight: .medium))
                    .foregroundStyle(OnboardingV3Theme.muted)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("직접 입력")
                            .font(.pretendard(14, weight: .semibold))
                            .foregroundStyle(OnboardingV3Theme.primary)

                        HStack {
                            TextField("목표 금액", text: $amountText)
                                .keyboardType(.numberPad)
                                .accessibilityLabel("목표 금액 직접 입력")
                            Text("원")
                                .foregroundStyle(OnboardingV3Theme.muted)
                        }
                        .font(.pretendard(16, weight: .medium))
                        .padding(12)
                        .background(OnboardingV3Theme.cardBackground, in: RoundedRectangle(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(OnboardingV3Theme.border, lineWidth: 1)
                        }

                        if enteredAmount == nil {
                            Text("1원 이상의 금액을 숫자로 입력해 주세요.")
                                .font(.pretendard(12, weight: .medium))
                                .foregroundStyle(.red)
                        }
                    }
                }
                .padding(16)
                .background(OnboardingV3Theme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(OnboardingV3Theme.border, lineWidth: 1)
                }
                .onboardingReveal(isRevealed: isRevealed)
            }
            .padding(.horizontal, OnboardingV3Layout.horizontalPadding)
            .padding(.top, OnboardingV3Layout.progressContentTopPadding)
            .padding(.bottom, 140)
            .frame(maxWidth: OnboardingV3Layout.maxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .trackOnboardingProgressScroll(isCollapsed: $isProgressCollapsed)
        .onboardingProgressOverlay(step: 2, totalSteps: 8, isCollapsed: isProgressCollapsed)
        .safeAreaInset(edge: .bottom) {
            OnboardingV3BottomBar {
                OnboardingV3PrimaryButton(title: "다음") {
                    guard let enteredAmount else { return }
                    viewModel.updateTargetAmount(enteredAmount)
                    onNext()
                }
                .disabled(enteredAmount == nil)
            }
        }
        .onboardingV3Background()
        .onAppear {
            syncFromTargetAmount()
        }
        .onChange(of: goal) { _, _ in
            syncFromTargetAmount()
        }
        .onChange(of: amountText) { _, newValue in
            let digits = newValue.filter { $0.isASCII && $0.isNumber }
            if digits != newValue {
                amountText = digits
                return
            }
            if let enteredAmount {
                viewModel.updateTargetAmount(enteredAmount)
            }
        }
        .onboardingRevealSequence(isRevealed: $isRevealed, reduceMotion: reduceMotion)
    }

    private func syncFromTargetAmount() {
        amountText = String(viewModel.targetAmount)
    }

    private func setSliderAmount(_ amount: Int64) {
        viewModel.updateTargetAmount(amount)
        amountText = String(amount)
    }
}

#Preview {
    OnboardingStep2TargetAmountView(viewModel: OnboardingFlowViewModel(), onNext: {}, onBack: {})
        .preferredColorScheme(.light)
}
