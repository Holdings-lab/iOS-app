import SwiftUI

struct OnboardingPage2View: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    let onBack: () -> Void
    let onNext: () -> Void

    @State private var showsRecommendation = false
    @State private var expandedSetting: RiskSetting?
    @State private var isProgressCollapsed = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            OnboardingProgressScrollAnchor()

            VStack(alignment: .leading, spacing: 24) {
                OnboardingV3StepHeader(step: 2, onBack: onBack)

                OnboardingV3QuestionHeader(
                    title: "맞춤 리밸런싱을 위해 몇 가지를 알려주세요",
                    subtitle: "추천 민감도와 자산 비중의 기준을 먼저 정해요"
                )

                VStack(spacing: 12) {
                    ForEach(InvestmentProfile.allCases) { profile in
                        RiskProfileCard(
                            profile: profile,
                            isSelected: viewModel.rebalancingPreference.investmentProfile == profile
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectInvestmentProfile(profile)
                                showsRecommendation = true
                                expandedSetting = nil
                            }
                        }
                    }
                }

                if showsRecommendation {
                    RecommendedRiskSettingsBlock(
                        viewModel: viewModel,
                        expandedSetting: $expandedSetting
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, OnboardingV3Layout.horizontalPadding)
            .padding(.top, OnboardingV3Layout.progressContentTopPadding)
            .padding(.bottom, 154)
            .frame(maxWidth: OnboardingV3Layout.maxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .trackOnboardingProgressScroll(isCollapsed: $isProgressCollapsed)
        .onboardingProgressOverlay(step: 2, isCollapsed: isProgressCollapsed)
        .safeAreaInset(edge: .bottom) {
            OnboardingV3BottomBar {
                VStack(spacing: 10) {
                    OnboardingV3PrimaryButton(title: "권장값으로 진행", action: onNext)

                    OnboardingV3SecondaryButton(title: "세부 조정하기") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expandedSetting = expandedSetting == nil ? .drawdown : nil
                            showsRecommendation = true
                        }
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.2)) {
                showsRecommendation = true
            }
        }
        .onboardingV3Background()
    }
}

private enum RiskSetting: Hashable {
    case drawdown
    case downturn
}

private struct RiskProfileCard: View {
    let profile: InvestmentProfile
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Text(profile.onboardingEmoji)
                        .font(.system(size: 32))
                        .frame(width: 38, height: 38)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(profile.displayName)
                            .font(.pretendard(17, weight: .bold))
                            .foregroundStyle(Color.textPrimary)

                        Text(profile.rawValue.lowercased())
                            .font(.pretendard(11, weight: .medium))
                            .foregroundStyle(OnboardingV3Theme.muted)
                    }

                    Spacer(minLength: 8)

                    OnboardingV3Radio(isSelected: isSelected)
                }

                Text(profile.subtitle)
                    .font(.pretendard(13, weight: .regular))
                    .foregroundStyle(OnboardingV3Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
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

private struct RecommendedRiskSettingsBlock: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    @Binding var expandedSetting: RiskSetting?

    private let drawdownOptions: [MaxDrawdownTolerance] = [.withinTen, .withinTwenty, .overThirty]
    private let downturnOptions: [DownturnBehavior] = [.reduce, .hold, .buyMore]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("권장 설정으로 시작할게요")
                .font(.pretendard(16, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 12) {
                settingRow(
                    title: "손실 기준",
                    value: viewModel.rebalancingPreference.maxDrawdownTolerance.title,
                    setting: .drawdown
                )

                if expandedSetting == .drawdown {
                    VStack(spacing: 8) {
                        ForEach(drawdownOptions) { option in
                            InlineRadioRow(
                                title: option.title,
                                isSelected: viewModel.rebalancingPreference.maxDrawdownTolerance == option
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.selectMaxDrawdownTolerance(option)
                                }
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                settingRow(
                    title: "하락 대응",
                    value: viewModel.rebalancingPreference.downturnBehavior.title,
                    setting: .downturn
                )

                if expandedSetting == .downturn {
                    VStack(spacing: 8) {
                        ForEach(downturnOptions) { option in
                            InlineRadioRow(
                                title: option.title,
                                isSelected: viewModel.rebalancingPreference.downturnBehavior == option
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.selectDownturnBehavior(option)
                                }
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OnboardingV3Theme.panelBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(OnboardingV3Theme.border, lineWidth: 1)
        }
    }

    private func settingRow(title: String, value: String, setting: RiskSetting) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.pretendard(14, weight: .medium))
                .foregroundStyle(OnboardingV3Theme.muted)
                .frame(width: 72, alignment: .leading)

            Text(value)
                .font(.pretendard(15, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button("조정") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedSetting = expandedSetting == setting ? nil : setting
                }
            }
            .font(.pretendard(13, weight: .semibold))
            .foregroundStyle(OnboardingV3Theme.primary)
            .buttonStyle(.plain)
        }
    }
}

private struct InlineRadioRow: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                OnboardingV3Radio(isSelected: isSelected)
            }
            .padding(.horizontal, 12)
            .frame(height: 42)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private extension InvestmentProfile {
    var onboardingEmoji: String {
        switch self {
        case .conservative:
            return "🛡"
        case .balanced:
            return "⚖"
        case .aggressive:
            return "🚀"
        }
    }
}

#Preview {
    OnboardingPage2View(viewModel: OnboardingFlowViewModel(), onBack: {}, onNext: {})
        .preferredColorScheme(.light)
}
