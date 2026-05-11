import SwiftUI

struct OnboardingPage3View: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    let onBack: () -> Void
    let onNext: () -> Void
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    @State private var showsConnectionReviewSheet = false

    private var selectedInstitutionCount: Int {
        viewModel.connectedInstitutionID == nil ? 0 : 1
    }

    private var selectedInstitutionLabel: String {
        viewModel.connectedInstitution?.name ?? "한국투자증권을 선택하면 연결할 수 있어요"
    }

    var body: some View {
        PFContentScrollView(
            alignment: .leading,
            spacing: 20,
            horizontalPadding: MidnightLayout.horizontal,
            topPadding: 16,
            bottomPadding: 168
        ) {
            FlowProgressHeader(currentStep: 3, totalSteps: 5, stepTitle: "맞춤 설정 · 계좌 연결", onBack: onBack)

            VStack(alignment: .leading, spacing: 10) {
                Text("조회 전용 계좌를 연결해주세요")
                    .font(.pretendard(26, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text("보유 종목과 잔고만 불러와 정책 민감도를 계산합니다. 주문 권한은 요청하지 않아요.")
                    .font(.pretendard(15, weight: .regular))
                    .foregroundStyle(Color.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            connectionTrustCard

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.brand)

                    Text("지원 가능 증권사")
                        .font(.pretendard(18, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)

                    Text("\(selectedInstitutionCount)")
                        .font(.pretendard(18, weight: .bold))
                        .foregroundStyle(Color.brand)

                    Spacer()

                    Image(systemName: "chevron.up")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.brokerageInstitutions) { institution in
                        BrokerInstitutionCard(
                            institution: institution,
                            isSelected: viewModel.connectedInstitutionID == institution.id,
                            isConnectable: viewModel.canConnect(institution),
                            onTap: {
                                toggleInstitution(institution)
                            }
                        )
                    }
                }
            }

            Text("다른 증권사는 준비 중이며, 현재는 한국투자증권만 선택 가능합니다.")
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .safeAreaInset(edge: .bottom) {
            bottomActionBar
        }
        .sheet(isPresented: $showsConnectionReviewSheet) {
            if let institution = viewModel.connectedInstitution {
                BrokerageConnectionReviewSheet(
                    institution: institution,
                    onContinue: {
                        showsConnectionReviewSheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            onNext()
                        }
                    }
                )
                .presentationDetents([.height(520), .large])
                .presentationDragIndicator(.visible)
                .preferredColorScheme(.light)
            }
        }
        .background(PFGradientBackground())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var connectionTrustCard: some View {
        FlowSurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("연결 전 확인")
                    .font(.pretendard(13, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)

                ConnectionTrustRow(
                    icon: "eye",
                    title: "조회 전용",
                    description: "잔고와 보유 종목만 분석에 사용합니다."
                )

                ConnectionTrustRow(
                    icon: "lock.shield",
                    title: "주문 권한 없음",
                    description: "매수와 매도는 실행할 수 없습니다."
                )

                ConnectionTrustRow(
                    icon: "clock",
                    title: "나중에 연결 가능",
                    description: "건너뛰어도 홈에서 다시 설정할 수 있어요."
                )
            }
        }
    }

    private var bottomActionBar: some View {
        VStack(spacing: 12) {
            Text(selectedInstitutionLabel)
                .font(.pretendard(13, weight: .semibold))
                .foregroundStyle(selectedInstitutionCount > 0 ? Color.textPrimary : Color.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)

            FlowPrimaryButton(
                title: "조회 전용으로 연결하기",
                isEnabled: selectedInstitutionCount > 0,
                action: {
                    showsConnectionReviewSheet = true
                }
            )

            Button("나중에 설정하기") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.skipBrokerageConnection()
                }
                onNext()
            }
            .font(.pretendard(14, weight: .semibold))
            .foregroundStyle(Color.textTertiary)
            .buttonStyle(.plain)
        }
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

    private func toggleInstitution(_ institution: AccountInstitution) {
        guard viewModel.canConnect(institution) else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            if viewModel.connectedInstitutionID == institution.id {
                viewModel.skipBrokerageConnection()
            } else {
                viewModel.selectInstitution(institution)
            }
        }
    }
}

private struct ConnectionTrustRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.brandTintBg)
                .frame(width: 32, height: 32)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.brand)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                Text(description)
                    .font(.pretendard(13, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct BrokerInstitutionCard: View {
    let institution: AccountInstitution
    let isSelected: Bool
    let isConnectable: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.brand)
                    } else if isConnectable {
                        Circle()
                            .stroke(Color.textDisabled, lineWidth: 1)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.textDisabled)
                    }

                    Spacer()
                }

                Spacer(minLength: 10)

                brokerMark
                    .frame(maxWidth: .infinity)

                Spacer(minLength: 12)

                Text(institution.name)
                    .font(.pretendard(13, weight: .semibold))
                    .foregroundStyle(isConnectable ? Color.textPrimary : Color.textDisabled)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .frame(height: 116)
            .background(cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(cardBorder, lineWidth: isSelected ? 1.6 : 1)
            }
        }
        .buttonStyle(.plain)
        .allowsHitTesting(isConnectable)
    }

    private var cardBackground: Color {
        if isSelected {
            return Color.brand.opacity(0.10)
        }

        return isConnectable ? Color.elevated : Color.muted
    }

    private var cardBorder: Color {
        if isSelected {
            return Color.brand.opacity(0.82)
        }

        return isConnectable ? Color.hairline : Color.divider
    }

    @ViewBuilder
    private var brokerMark: some View {
        if institution.id == AccountInstitution.koreaInvestmentID {
            Image("hantoo")
                .resizable()
                .scaledToFit()
                .frame(width: 42, height: 42)
        } else {
            Text(brandMark)
                .font(.pretendard(23, weight: .bold))
                .foregroundStyle(Color(hex: institution.accentHex).opacity(isConnectable ? 0.96 : 0.72))
                .frame(width: 46, height: 46)
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
        case "kb_securities":
            return "KB"
        case "hana_securities":
            return "하"
        case "shinhan_invest":
            return "신"
        case "toss_securities":
            return "토"
        default:
            return institution.emoji
        }
    }
}

private struct BrokerageConnectionReviewSheet: View {
    let institution: AccountInstitution
    let onContinue: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                PFGradientBackground()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("조회 전용으로 연결할게요")
                                .font(.pretendard(24, weight: .bold))
                                .foregroundStyle(Color.textPrimary)

                            Text("매수나 매도 기능 없이, 계좌 잔고와 보유 종목만 불러옵니다.")
                                .font(.pretendard(15, weight: .regular))
                                .foregroundStyle(Color.textTertiary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        FlowSurfaceCard {
                            HStack(spacing: 14) {
                                SelectedInstitutionBadge(institution: institution, size: 54)

                                VStack(alignment: .leading, spacing: 5) {
                                    Text(institution.name)
                                        .font(.pretendard(17, weight: .semibold))
                                        .foregroundStyle(Color.textPrimary)

                                    Text("연결 후 홈과 내 자산 화면에 실계좌 기준 분석이 반영돼요.")
                                        .font(.pretendard(13, weight: .medium))
                                        .foregroundStyle(Color.textTertiary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            ReviewBulletRow(
                                icon: "chart.bar.doc.horizontal",
                                title: "잔고 조회",
                                description: "총 평가금액과 현금 비중을 불러옵니다."
                            )
                            ReviewBulletRow(
                                icon: "list.bullet.rectangle",
                                title: "보유 종목 조회",
                                description: "보유 ETF와 종목 목록을 분석에 활용합니다."
                            )
                            ReviewBulletRow(
                                icon: "lock.shield",
                                title: "주문 권한 없음",
                                description: "매수·매도는 실행하지 않고 읽기 전용으로만 연결합니다."
                            )
                        }

                        FlowPrimaryButton(title: "계속", action: onContinue)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, MidnightLayout.horizontal)
                    .padding(.top, 24)
                    .padding(.bottom, 28)
                }

            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
                }
            }
        }
    }
}

private struct ReviewBulletRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.brand.opacity(0.14))
                .frame(width: 34, height: 34)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.brand)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                Text(description)
                    .font(.pretendard(13, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct SelectedInstitutionBadge: View {
    let institution: AccountInstitution
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.subtle)

            if institution.id == AccountInstitution.koreaInvestmentID {
                Image("hantoo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.56, height: size * 0.56)
            } else {
                Text(institution.emoji)
                    .font(.system(size: size * 0.38))
            }
        }
        .frame(width: size, height: size)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.divider, lineWidth: 1)
        }
    }
}

#Preview {
    OnboardingPage3View(viewModel: OnboardingFlowViewModel(), onBack: {}, onNext: {})
        .preferredColorScheme(.light)
}
