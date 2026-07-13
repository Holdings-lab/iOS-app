import SwiftUI

struct SettingsInvestProfileView: View {
    @ObservedObject var viewModel: SettingsViewModel
    let onBack: () -> Void

    @State private var horizon: InvestmentHorizon
    @State private var tolerance: MaxDrawdownTolerance
    @State private var profile: InvestmentProfile
    @State private var dismissed = true

    private static let simulationAmount: Int64 = 10_000_000

    init(viewModel: SettingsViewModel, onBack: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onBack = onBack
        _horizon = State(initialValue: viewModel.investmentHorizon)
        _tolerance = State(initialValue: viewModel.maxDrawdownTolerance)
        _profile = State(initialValue: viewModel.investmentProfile)
    }

    private var isConsistent: Bool {
        RiskProfileConsistency.isConsistent(profile: profile, tolerance: tolerance)
    }

    private var showsWarning: Bool {
        !isConsistent && !dismissed
    }

    private var simulatedAmount: Int64 {
        Self.simulationAmount * Int64(100 - tolerance.percentValue) / 100
    }

    var body: some View {
        VStack(spacing: 0) {
            SettingsNavHeader(title: "투자 프로필", onBack: onBack)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("투자 기간")
                        .font(.pretendard(13, weight: .bold))
                        .foregroundStyle(Color.textSecondary)
                        .padding(.top, 14)

                    VStack(spacing: 8) {
                        ForEach(InvestmentHorizon.allCases) { option in
                            PeriodRow(isOn: horizon == option, title: option.title, subtitle: option.subtitle) {
                                horizon = option
                                dismissed = false
                            }
                        }
                    }
                    .padding(.top, 8)

                    Text("손실 허용 기준")
                        .font(.pretendard(13, weight: .bold))
                        .foregroundStyle(Color.textSecondary)
                        .padding(.top, 22)

                    drawdownSliderBlock
                        .padding(.top, 8)

                    Text("투자 성향")
                        .font(.pretendard(13, weight: .bold))
                        .foregroundStyle(Color.textSecondary)
                        .padding(.top, 22)

                    VStack(spacing: 10) {
                        ForEach(InvestmentProfile.allCases) { option in
                            ChoiceCard(
                                isOn: profile == option,
                                icon: profileEmoji(option),
                                title: option.title,
                                subtitle: option.subtitle
                            ) {
                                profile = option
                                dismissed = false
                            }
                        }
                    }
                    .padding(.top, 8)

                    if showsWarning {
                        CalloutView(tone: .warn, icon: "exclamationmark.triangle.fill") {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(RiskProfileConsistency.buildConfirmMessage(profile: profile))

                                Button(action: { dismissed = true }) {
                                    Text("이대로 진행할게요")
                                        .font(.pretendard(12.5, weight: .bold))
                                        .foregroundStyle(Color.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Color.brand, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 14)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 118)
            }
        }
        .background(Color.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            Button(action: save) {
                Text("저장")
                    .font(.pretendard(14.5, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(showsWarning ? Color.muted : Color.brand, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(showsWarning)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 22)
            .background(.ultraThinMaterial)
        }
    }

    private func profileEmoji(_ profile: InvestmentProfile) -> String {
        switch profile {
        case .conservative: return "🛡"
        case .balanced: return "⚖"
        case .aggressive: return "🚀"
        }
    }

    private var drawdownSliderBlock: some View {
        VStack(spacing: 8) {
            Text("\(OnboardingCurrencyFormatter.wonText(Self.simulationAmount))을 투자했다고 가정할게요")
                .font(.pretendard(12.5, weight: .semibold))
                .foregroundStyle(Color.textSecondary)

            Text(OnboardingCurrencyFormatter.wonText(simulatedAmount))
                .font(.pretendard(26, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .monospacedDigit()

            Text("\(tolerance.percentValue >= 30 ? "-30% 이하" : "-\(tolerance.percentValue)%")가 돼도 괜찮다 · \(tolerance.settingsHint)")
                .font(.pretendard(12.5, weight: .regular))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)

            Slider(
                value: Binding(
                    get: { Double(tolerance.percentValue) },
                    set: { newValue in
                        if let match = MaxDrawdownTolerance.onboardingOptions.first(where: { Double($0.percentValue) == newValue }) {
                            tolerance = match
                            dismissed = false
                        }
                    }
                ),
                in: 10...30,
                step: 10
            )
            .tint(Color.brand)
            .padding(.top, 8)
            .accessibilityValue("\(tolerance.percentValue >= 30 ? "-30% 이하" : "-\(tolerance.percentValue)%")가 돼도 괜찮다")

            HStack {
                Text("-10%")
                Spacer()
                Text("-20%")
                Spacer()
                Text("-30% 이하")
            }
            .font(.pretendard(11, weight: .semibold))
            .foregroundStyle(Color.textTertiary)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 2)
    }

    private func save() {
        viewModel.saveInvestProfile(horizon: horizon, tolerance: tolerance, profile: profile)
        onBack()
    }
}
