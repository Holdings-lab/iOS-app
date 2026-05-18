import SwiftUI

struct OnboardingPage3View: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    let onBack: () -> Void
    let onNext: () -> Void
    @State private var isProgressCollapsed = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            OnboardingProgressScrollAnchor()

            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    OnboardingV3BackButton(action: onBack)

                    Spacer()
                }

                OnboardingV3QuestionHeader(
                    title: "조회 전용 계좌를 연결해주세요",
                    subtitle: "보유 종목과 잔고만 분석에 사용합니다. 주문 권한은 요청하지 않아요."
                )

                BrokerageTrustBlock()

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.brokerageInstitutions) { institution in
                        BrokerInstitutionCard(
                            institution: institution,
                            isSelected: viewModel.connectedInstitutionID == institution.id,
                            isConnectable: viewModel.canConnect(institution)
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectInstitution(institution)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, OnboardingV3Layout.horizontalPadding)
            .padding(.top, OnboardingV3Layout.progressContentTopPadding)
            .padding(.bottom, 150)
            .frame(maxWidth: OnboardingV3Layout.maxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .trackOnboardingProgressScroll(isCollapsed: $isProgressCollapsed)
        .onboardingProgressOverlay(step: 4, isCollapsed: isProgressCollapsed)
        .safeAreaInset(edge: .bottom) {
            OnboardingV3BottomBar {
                VStack(spacing: 10) {
                    OnboardingV3PrimaryButton(title: "조회 전용으로 연결하기") {
                        if viewModel.connectedInstitutionID == nil {
                            viewModel.connectRecommendedBroker()
                        }
                        onNext()
                    }

                    OnboardingV3SecondaryButton(title: "나중에 설정하기") {
                        viewModel.skipBrokerageConnection()
                        onNext()
                    }
                }
            }
        }
        .onboardingV3Background()
    }
}

private struct BrokerageTrustBlock: View {
    var body: some View {
        VStack(spacing: 14) {
            BrokerageTrustRow(
                icon: "eye",
                title: "조회 전용",
                description: "잔고와 보유 종목만 분석에 사용합니다"
            )

            BrokerageTrustRow(
                icon: "lock.shield",
                title: "주문 권한 없음",
                description: "매수/매도는 실행할 수 없습니다"
            )

            BrokerageTrustRow(
                icon: "clock",
                title: "나중에 연결 가능",
                description: "건너뛰어도 언제든 다시 설정할 수 있어요"
            )
        }
        .padding(16)
        .background(OnboardingV3Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(OnboardingV3Theme.border, lineWidth: 1)
        }
    }
}

private struct BrokerageTrustRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(OnboardingV3Theme.selectedBackground)
                .frame(width: 34, height: 34)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(OnboardingV3Theme.primary)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.pretendard(15, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text(description)
                    .font(.pretendard(13, weight: .regular))
                    .foregroundStyle(OnboardingV3Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BrokerInstitutionCard: View {
    let institution: AccountInstitution
    let isSelected: Bool
    let isConnectable: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    if isSelected {
                        OnboardingV3SelectionCheck(isSelected: true)
                    } else {
                        Circle()
                            .stroke(isConnectable ? OnboardingV3Theme.primary : OnboardingV3Theme.border, lineWidth: 1.2)
                            .frame(width: 22, height: 22)
                    }

                    Spacer()

                    if !isConnectable {
                        Text("준비 중")
                            .font(.pretendard(10, weight: .bold))
                            .foregroundStyle(OnboardingV3Theme.muted)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(Color(hex: "F1F5F9"), in: Capsule(style: .continuous))
                    }
                }

                Spacer(minLength: 4)

                brokerMark
                    .frame(maxWidth: .infinity)

                Text(institution.shortDisplayName)
                    .font(.pretendard(14, weight: .bold))
                    .foregroundStyle(isConnectable ? Color.textPrimary : Color.textDisabled)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .frame(height: 126)
            .background(cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(cardBorder, lineWidth: isSelected || isConnectable ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isConnectable)
    }

    private var cardBackground: Color {
        if isSelected || isConnectable {
            return isSelected ? OnboardingV3Theme.selectedBackground : OnboardingV3Theme.cardBackground
        }

        return Color(hex: "F8FAFC")
    }

    private var cardBorder: Color {
        if isSelected || isConnectable {
            return OnboardingV3Theme.primary
        }

        return OnboardingV3Theme.border
    }

    @ViewBuilder
    private var brokerMark: some View {
        if institution.id == AccountInstitution.koreaInvestmentID {
            Image("hantoo")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
        } else {
            Text(brandMark)
                .font(.pretendard(24, weight: .bold))
                .foregroundStyle(Color(hex: institution.accentHex).opacity(isConnectable ? 0.95 : 0.45))
                .frame(width: 44, height: 44)
        }
    }

    private var brandMark: String {
        switch institution.id {
        case "kiwoom":
            return "키"
        case "samsung_securities":
            return "삼"
        case "mirae":
            return "M"
        case "nh_invest":
            return "NH"
        case "shinhan_invest":
            return "신"
        default:
            return institution.emoji
        }
    }
}

private extension AccountInstitution {
    var shortDisplayName: String {
        name
            .replacingOccurrences(of: "투자증권", with: "")
            .replacingOccurrences(of: "증권", with: "")
    }
}

#Preview {
    OnboardingPage3View(viewModel: OnboardingFlowViewModel(), onBack: {}, onNext: {})
        .preferredColorScheme(.light)
}
