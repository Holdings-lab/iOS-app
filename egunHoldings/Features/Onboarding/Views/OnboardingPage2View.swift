import SwiftUI

struct OnboardingPage2View: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    let onBack: () -> Void
    let onNext: () -> Void

    var body: some View {
        PFContentScrollView(
            alignment: .leading,
            spacing: 22,
            horizontalPadding: MidnightLayout.horizontal,
            topPadding: 16,
            bottomPadding: 128
        ) {
            FlowProgressHeader(
                currentStep: 2,
                totalSteps: 5,
                stepTitle: "맞춤 설정 · \(viewModel.rebalancingStep.title)",
                onBack: handleBack
            )

            VStack(alignment: .leading, spacing: 10) {
                Text(headingTitle)
                    .font(.pretendard(28, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(headingSubtitle)
                    .font(.pretendard(16, weight: .regular))
                    .foregroundStyle(Color.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            stepContent
                .transition(.opacity.combined(with: .move(edge: .trailing)))

            RebalancingImpactPanel(preference: viewModel.rebalancingPreference)
        }
        .safeAreaInset(edge: .bottom) {
            FlowPrimaryButton(
                title: bottomButtonTitle,
                isEnabled: viewModel.canAdvanceFromStyleStep,
                action: handleNext
            )
            .padding(.horizontal, MidnightLayout.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(
                Color.elevated
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(Color.hairline)
                            .frame(height: 1)
                    }
                    .ignoresSafeArea()
            )
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.rebalancingStep)
        .background(PFGradientBackground())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var headingTitle: String {
        switch viewModel.rebalancingStep {
        case .profile:
            return "맞춤 리밸런싱을 위해 몇 가지를 알려주세요"
        case .goalAndHorizon:
            return "투자 목표와 기간을 선택해주세요"
        case .riskResponse:
            return "하락장에서 어떤 추천이 편한가요?"
        case .allocation:
            return "현금 비중과 선호 자산을 정해주세요"
        }
    }

    private var headingSubtitle: String {
        switch viewModel.rebalancingStep {
        case .profile:
            return "추천 민감도와 자산 비중의 기준을 먼저 정해요."
        case .goalAndHorizon:
            return "목표와 기간은 리밸런싱 추천의 속도와 방어 기준을 조절하는 데 사용해요."
        case .riskResponse:
            return "감내 가능한 손실과 하락장 행동을 함께 반영해 매수/매도 민감도를 맞춰요."
        case .allocation:
            return "현금 여력과 선호 자산 범위를 정해요."
        }
    }

    private var bottomButtonTitle: String {
        viewModel.rebalancingStep == .allocation ? "계좌 연결로 계속" : "다음"
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.rebalancingStep {
        case .profile:
            VStack(spacing: 12) {
                ForEach(InvestmentProfile.allCases) { profile in
                    InvestmentProfileSelectionCard(
                        profile: profile,
                        isSelected: viewModel.rebalancingPreference.investmentProfile == profile
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectInvestmentProfile(profile)
                        }
                    }
                }
            }
        case .goalAndHorizon:
            VStack(alignment: .leading, spacing: 20) {
                PreferenceSection(
                    title: "투자 목적",
                    options: InvestmentGoal.allCases,
                    selected: viewModel.rebalancingPreference.investmentGoal,
                    onSelect: viewModel.selectInvestmentGoal
                )

                PreferenceSection(
                    title: "투자 기간",
                    options: InvestmentHorizon.allCases,
                    selected: viewModel.rebalancingPreference.investmentHorizon,
                    onSelect: viewModel.selectInvestmentHorizon
                )
            }
        case .riskResponse:
            VStack(alignment: .leading, spacing: 20) {
                PreferenceSection(
                    title: "감내 가능한 손실 폭",
                    options: MaxDrawdownTolerance.allCases,
                    selected: viewModel.rebalancingPreference.maxDrawdownTolerance,
                    onSelect: viewModel.selectMaxDrawdownTolerance
                )

                PreferenceSection(
                    title: "하락장 대응 성향",
                    options: DownturnBehavior.allCases,
                    selected: viewModel.rebalancingPreference.downturnBehavior,
                    onSelect: viewModel.selectDownturnBehavior
                )
            }
        case .allocation:
            VStack(alignment: .leading, spacing: 20) {
                PreferenceSection(
                    title: AppVocabulary.Rebalancing.targetCashWeight,
                    options: TargetCashWeight.allCases,
                    selected: viewModel.rebalancingPreference.targetCashWeightOption,
                    onSelect: viewModel.selectTargetCashWeight
                )

                PreferenceSection(
                    title: "선호 투자 방식",
                    options: AssetPreference.allCases,
                    selected: viewModel.rebalancingPreference.assetPreference,
                    onSelect: viewModel.selectAssetPreference
                )
            }
        }
    }

    private func handleBack() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if viewModel.moveToPreviousRebalancingStep() {
                return
            }

            onBack()
        }
    }

    private func handleNext() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if viewModel.moveToNextRebalancingStep() {
                onNext()
            }
        }
    }
}

private struct InvestmentProfileSelectionCard: View {
    let profile: InvestmentProfile
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                Circle()
                    .fill(Color(hex: profile.tintHex, alpha: 0.16))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: profile.symbol)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color(hex: profile.tintHex))
                    }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(profile.title)
                            .font(.pretendard(17, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)

                        Text(profile.rawValue)
                            .font(.pretendard(10, weight: .bold))
                            .foregroundStyle(Color(hex: profile.tintHex))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(Color(hex: profile.tintHex, alpha: 0.10), in: Capsule(style: .continuous))
                    }

                    Text(profile.subtitle)
                        .font(.pretendard(14, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(profile.impactSummary)
                        .font(.pretendard(13, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                SelectionIndicator(isSelected: isSelected)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(cardBorder, lineWidth: isSelected ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var cardBackground: Color {
        isSelected ? Color.brand.opacity(0.12) : Color.elevated
    }

    private var cardBorder: Color {
        isSelected ? Color.brand.opacity(0.58) : Color.hairline
    }
}

private protocol RebalancingSelectableOption: Identifiable, Equatable {
    var title: String { get }
    var subtitle: String { get }
    var symbol: String { get }
}

extension InvestmentGoal: RebalancingSelectableOption {}
extension InvestmentHorizon: RebalancingSelectableOption {}
extension MaxDrawdownTolerance: RebalancingSelectableOption {}
extension DownturnBehavior: RebalancingSelectableOption {}
extension TargetCashWeight: RebalancingSelectableOption {}
extension AssetPreference: RebalancingSelectableOption {}

private struct PreferenceSection<Option: RebalancingSelectableOption>: View {
    let title: String
    let options: [Option]
    let selected: Option
    let onSelect: (Option) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.pretendard(18, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 10) {
                ForEach(options) { option in
                    PreferenceOptionCard(
                        title: option.title,
                        subtitle: option.subtitle,
                        symbol: option.symbol,
                        isSelected: selected == option
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            onSelect(option)
                        }
                    }
                }
            }
        }
    }
}

private struct PreferenceOptionCard: View {
    let title: String
    let subtitle: String
    let symbol: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.brandTintBg : Color.subtle)
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: symbol)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(isSelected ? Color.brand : Color.textTertiary)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.pretendard(15, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitle)
                        .font(.pretendard(13, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                SelectionIndicator(isSelected: isSelected)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? Color.brand.opacity(0.10) : Color.elevated,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.brand.opacity(0.52) : Color.hairline, lineWidth: isSelected ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct RebalancingImpactPanel: View {
    let preference: OnboardingRebalancingPreference

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("리밸런싱 추천에 반영되는 기준")
                .font(.pretendard(15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 10) {
                RebalancingImpactRow(title: "투자성향", value: preference.investmentProfile.displayName)
                RebalancingImpactRow(title: "현금 비중", value: preference.targetCashWeightOption.title)
                RebalancingImpactRow(title: "손실 기준", value: preference.maxDrawdownTolerance.title)
            }

        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.subtle, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }
}

private struct RebalancingImpactRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.textTertiary)
                .frame(width: 68, alignment: .leading)

            Text(value)
                .font(.pretendard(14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct SelectionIndicator: View {
    let isSelected: Bool

    var body: some View {
        Circle()
            .fill(isSelected ? Color.brand : Color.subtle)
            .frame(width: 22, height: 22)
            .overlay {
                Circle()
                    .stroke(isSelected ? Color.brand : Color.divider, lineWidth: 1)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    OnboardingPage2View(viewModel: OnboardingFlowViewModel(), onBack: {}, onNext: {})
        .preferredColorScheme(.light)
}
