import SwiftUI

struct SignupCompleteView: View {
    let onLogin: () -> Void

    var body: some View {
        PFContentScrollView(
            spacing: 28,
            horizontalPadding: MidnightLayout.horizontal,
            topPadding: 16,
            bottomPadding: 120
        ) {
            FlowProgressHeader(currentStep: 4, totalSteps: 4, showsBack: false, onBack: {})

            Spacer(minLength: 48)

            VStack(spacing: 20) {
                CompletionCheckAnimationView()

                VStack(spacing: 10) {
                    Text("회원가입이 완료됐어요")
                        .font(.pretendard(28, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.92))

                    Text("이제 로그인하면 맞춤 설정을 시작할 수 있어요.")
                        .font(.pretendard(15, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.62))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 0)
        }
        .safeAreaInset(edge: .bottom) {
            FlowPrimaryButton(title: "로그인하러 가기 →", action: onLogin)
                .padding(.horizontal, MidnightLayout.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 12)
        }
        .background(PFGradientBackground())
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    SignupCompleteView(onLogin: {})
        .preferredColorScheme(.dark)
}
