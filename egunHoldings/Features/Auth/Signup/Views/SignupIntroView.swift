import SwiftUI

struct SignupIntroView: View {
    let onBack: () -> Void
    let onStart: () -> Void

    var body: some View {
        PFContentScrollView(
            alignment: .leading,
            spacing: 24,
            horizontalPadding: MidnightLayout.horizontal,
            topPadding: 44,
            bottomPadding: 140
        ) {
            Spacer(minLength: 8)

            VStack(alignment: .leading, spacing: 10) {
                Text(
                    """
                    정책 뉴스 하나로
                    내 ETF가 어떻게
                    움직일지 알 수 있어요
                    """
                )
                .font(.pretendard(32, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            }

            SignalDemoCard(
                label: "지금 막 분석된 시그널",
                title: "금리 인상 발표",
                impactText: "QQQ 하락 가능성",
                percentageText: "68%",
                subtitle: "변동성 확대 · 방어 자산 비중 검토 권장"
            )

            Text("가입하면 내 보유 ETF 기준으로 분석돼요")
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                FlowPrimaryButton(title: "1분 만에 가입하기 →", action: onStart)

                Button("이미 계정이 있어요") {
                    onBack()
                }
                .font(.pretendard(15, weight: .medium))
                .foregroundStyle(Color.textTertiary)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, MidnightLayout.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 12)
        }
        .background(PFGradientBackground())
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    SignupIntroView(onBack: {}, onStart: {})
        .preferredColorScheme(.light)
}
