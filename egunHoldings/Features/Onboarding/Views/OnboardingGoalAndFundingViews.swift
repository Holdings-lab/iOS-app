import SwiftUI

struct OnboardingGoalView: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    let onBack: () -> Void
    let onNext: () -> Void

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                OnboardingV3StepHeader(step: 3, onBack: onBack)

                OnboardingV3QuestionHeader(
                    title: "투자 목표와 기간을 알려주세요",
                    subtitle: "조정 제안의 빈도와 방향이 달라져요"
                )

                VStack(spacing: 10) {
                    ForEach(InvestmentGoal.allCases) { goal in
                        InvestmentGoalCard(
                            goal: goal,
                            isSelected: viewModel.rebalancingPreference.investmentGoal == goal
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectInvestmentGoal(goal)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("투자 기간")
                        .font(.pretendard(15, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    VStack(spacing: 0) {
                        ForEach(InvestmentHorizon.allCases) { horizon in
                            InvestmentHorizonRow(
                                horizon: horizon,
                                isSelected: viewModel.rebalancingPreference.investmentHorizon == horizon,
                                isRecommended: viewModel.recommendedHorizon(for: viewModel.rebalancingPreference.investmentGoal) == horizon
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.selectInvestmentHorizon(horizon)
                                }
                            }

                            if horizon != InvestmentHorizon.allCases.last {
                                Rectangle()
                                    .fill(OnboardingV3Theme.border)
                                    .frame(height: 1)
                                    .padding(.leading, 12)
                            }
                        }
                    }
                    .background(OnboardingV3Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(OnboardingV3Theme.border, lineWidth: 1)
                    }
                }
            }
            .padding(.horizontal, OnboardingV3Layout.horizontalPadding)
            .padding(.top, 16)
            .padding(.bottom, 120)
            .frame(maxWidth: OnboardingV3Layout.maxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            OnboardingV3BottomBar {
                OnboardingV3PrimaryButton(title: "다음", action: onNext)
            }
        }
        .onboardingV3Background()
    }
}

struct OnboardingFundsView: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    let onBack: () -> Void
    let onNext: () -> Void

    private let assetOptions: [AssetPreference] = [.etfFocused, .etfAndStocks]

    private var cashBinding: Binding<Double> {
        Binding(
            get: { Double(viewModel.cashWeightPercent) },
            set: { viewModel.setTargetCashWeight(percent: Int($0.rounded())) }
        )
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                OnboardingV3StepHeader(step: 4, onBack: onBack)

                OnboardingV3QuestionHeader(
                    title: "현금 비중과 선호 자산을 정해주세요",
                    subtitle: "현금 여력과 선호 자산 범위를 정해요"
                )

                CashWeightSliderBlock(viewModel: viewModel, cashValue: cashBinding)

                VStack(alignment: .leading, spacing: 12) {
                    Text("선호 투자 방식")
                        .font(.pretendard(15, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    VStack(spacing: 10) {
                        ForEach(assetOptions) { preference in
                            AssetPreferenceCard(
                                preference: preference,
                                isSelected: viewModel.rebalancingPreference.assetPreference == preference
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.selectAssetPreference(preference)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, OnboardingV3Layout.horizontalPadding)
            .padding(.top, 16)
            .padding(.bottom, 144)
            .frame(maxWidth: OnboardingV3Layout.maxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            OnboardingV3BottomBar {
                VStack(spacing: 10) {
                    Button("기본값으로 시작하기") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.resetFundingDefaults()
                        }
                        onNext()
                    }
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(OnboardingV3Theme.primary)
                    .buttonStyle(.plain)

                    OnboardingV3PrimaryButton(title: "다음", action: onNext)
                }
            }
        }
        .onboardingV3Background()
    }
}

private struct InvestmentGoalCard: View {
    let goal: InvestmentGoal
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                Text(goal.onboardingEmoji)
                    .font(.system(size: 26))
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 5) {
                    Text(goal.title)
                        .font(.pretendard(16, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    Text(goal.subtitle)
                        .font(.pretendard(13, weight: .regular))
                        .foregroundStyle(OnboardingV3Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                OnboardingV3Radio(isSelected: isSelected)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? OnboardingV3Theme.selectedBackground : OnboardingV3Theme.cardBackground,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? OnboardingV3Theme.primary : OnboardingV3Theme.border, lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct InvestmentHorizonRow: View {
    let horizon: InvestmentHorizon
    let isSelected: Bool
    let isRecommended: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(horizon.title)
                        .font(.pretendard(15, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    Text(horizon.subtitle)
                        .font(.pretendard(13, weight: .regular))
                        .foregroundStyle(OnboardingV3Theme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                Spacer(minLength: 6)

                if isRecommended {
                    Text("권장")
                        .font(.pretendard(11, weight: .bold))
                        .foregroundStyle(OnboardingV3Theme.primary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(OnboardingV3Theme.selectedBackground, in: Capsule(style: .continuous))
                        .transition(.opacity)
                }

                OnboardingV3Radio(isSelected: isSelected)
            }
            .padding(.horizontal, 12)
            .frame(height: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isRecommended)
    }
}

private struct CashWeightSliderBlock: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    let cashValue: Binding<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("유지할 현금 비중")
                .font(.pretendard(15, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(viewModel.cashWeightPercent)%")
                    .font(.pretendard(32, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .monospacedDigit()

                Text(viewModel.cashWeightDescription)
                    .font(.pretendard(13, weight: .regular))
                    .foregroundStyle(OnboardingV3Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Slider(value: cashValue, in: 0...30, step: 1)
                .tint(OnboardingV3Theme.primary)

            HStack {
                Text("0%")
                Spacer()
                Text("30%")
            }
            .font(.pretendard(12, weight: .medium))
            .foregroundStyle(OnboardingV3Theme.muted)
        }
        .padding(16)
        .background(OnboardingV3Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(OnboardingV3Theme.border, lineWidth: 1)
        }
    }
}

private struct AssetPreferenceCard: View {
    let preference: AssetPreference
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                Text(preference.onboardingEmoji)
                    .font(.system(size: 26))
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 5) {
                    Text(preference.title)
                        .font(.pretendard(16, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    Text(preference.subtitle)
                        .font(.pretendard(13, weight: .regular))
                        .foregroundStyle(OnboardingV3Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                OnboardingV3Radio(isSelected: isSelected)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? OnboardingV3Theme.selectedBackground : OnboardingV3Theme.cardBackground,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? OnboardingV3Theme.primary : OnboardingV3Theme.border, lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private extension InvestmentGoal {
    var onboardingEmoji: String {
        switch self {
        case .preserve:
            return "🛡"
        case .steadyGrowth:
            return "🌱"
        case .activeReturn:
            return "⚡"
        }
    }
}

private extension AssetPreference {
    var onboardingEmoji: String {
        switch self {
        case .etfFocused:
            return "📦"
        case .etfAndStocks:
            return "📊"
        case .highVolatilityAllowed:
            return "🚀"
        }
    }
}

#Preview("Goal") {
    OnboardingGoalView(viewModel: OnboardingFlowViewModel(), onBack: {}, onNext: {})
        .preferredColorScheme(.light)
}

#Preview("Funds") {
    OnboardingFundsView(viewModel: OnboardingFlowViewModel(), onBack: {}, onNext: {})
        .preferredColorScheme(.light)
}
