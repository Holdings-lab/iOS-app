import SwiftUI

struct OnboardingStep5ProfileView: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    let onNext: () -> Void
    let onBack: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isProgressCollapsed = false
    @State private var pendingProfile: InvestmentProfile?
    @State private var confirmPopup: BottomConfirmPopup?
    @State private var isRevealed = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            OnboardingProgressScrollAnchor()

            VStack(alignment: .leading, spacing: 24) {
                OnboardingV3StepHeader(step: 5, onBack: onBack)

                OnboardingV3QuestionHeader(
                    title: "투자 성향을 알려주세요",
                    subtitle: "선택한 성향에 맞춰 자산 조합을 추천해요"
                )

                VStack(spacing: 12) {
                    ForEach(Array(InvestmentProfile.allCases.enumerated()), id: \.element.id) { index, profile in
                        OnboardingV3OptionCard(
                            symbol: profile.symbol,
                            title: profile.title,
                            subtitle: profile.subtitle,
                            isSelected: viewModel.investmentProfile == profile
                        ) {
                            selectProfile(profile)
                        }
                        .onboardingReveal(isRevealed: isRevealed, index: index)
                    }
                }
            }
            .padding(.horizontal, OnboardingV3Layout.horizontalPadding)
            .padding(.top, OnboardingV3Layout.progressContentTopPadding)
            .padding(.bottom, 140)
            .frame(maxWidth: OnboardingV3Layout.maxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .trackOnboardingProgressScroll(isCollapsed: $isProgressCollapsed)
        .onboardingProgressOverlay(step: 5, totalSteps: 8, isCollapsed: isProgressCollapsed)
        .safeAreaInset(edge: .bottom) {
            OnboardingV3BottomBar {
                OnboardingV3PrimaryButton(
                    title: "다음",
                    isEnabled: viewModel.investmentProfile != nil,
                    action: onNext
                )
            }
        }
        .onboardingV3Background()
        .bottomConfirmPopup($confirmPopup, onPrimary: {
            if let pendingProfile {
                viewModel.investmentProfile = pendingProfile
            }
            pendingProfile = nil
        }, onSecondary: {
            pendingProfile = nil
        })
        .onAppear(perform: revalidateExistingSelection)
        .onboardingRevealSequence(isRevealed: $isRevealed, reduceMotion: reduceMotion)
    }

    private func selectProfile(_ profile: InvestmentProfile) {
        guard viewModel.profileConflictsWithDrawdown(profile) else {
            viewModel.investmentProfile = profile
            return
        }

        presentConfirmPopup(for: profile)
    }

    /// Step 4로 돌아가 손실 허용 기준을 바꾼 뒤 다시 이 화면에 진입하는 경우, 이미 선택된 성향이
    /// 새 기준과 불일치할 수 있으므로 재검증한다.
    private func revalidateExistingSelection() {
        guard let currentProfile = viewModel.investmentProfile,
              viewModel.profileConflictsWithDrawdown(currentProfile) else { return }

        presentConfirmPopup(for: currentProfile)
    }

    private func presentConfirmPopup(for profile: InvestmentProfile) {
        pendingProfile = profile
        confirmPopup = BottomConfirmPopup(message: RiskProfileConsistency.buildConfirmMessage(profile: profile))
    }
}

#Preview {
    OnboardingStep5ProfileView(viewModel: OnboardingFlowViewModel(), onNext: {}, onBack: {})
        .preferredColorScheme(.light)
}
