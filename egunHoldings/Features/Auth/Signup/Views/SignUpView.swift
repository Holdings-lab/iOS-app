import SwiftUI

struct SignUpView: View {
    let onBackToLogin: () -> Void
    let onCompleted: (String) -> Void

    @StateObject private var viewModel: SignUpFlowViewModel

    init(
        onBackToLogin: @escaping () -> Void,
        onCompleted: @escaping (String) -> Void
    ) {
        self.onBackToLogin = onBackToLogin
        self.onCompleted = onCompleted
        _viewModel = StateObject(wrappedValue: SignUpFlowViewModel())
    }

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            SignupIntroView(
                onBack: onBackToLogin,
                onStart: viewModel.startSignup
            )
            .navigationDestination(for: SignupRoute.self) { route in
                switch route {
                case .terms:
                    SignupTermsView(
                        items: viewModel.consentDefinitions,
                        selectedIDs: viewModel.selectedConsentIDs,
                        onBack: navigateBack,
                        onToggleAll: viewModel.toggleAllConsents,
                        onToggleItem: viewModel.toggleConsent(id:),
                        onNext: viewModel.moveToEmailVerification
                    )
                case .emailVerification:
                    SignupEmailAuthView(
                        emailLocalPart: Binding(
                            get: { viewModel.emailLocalPart },
                            set: { viewModel.updateEmailLocalPart($0) }
                        ),
                        selectedDomain: Binding(
                            get: { viewModel.selectedDomain },
                            set: { viewModel.updateSelectedDomain($0) }
                        ),
                        customDomain: Binding(
                            get: { viewModel.customDomain },
                            set: { viewModel.updateCustomDomain($0) }
                        ),
                        otpCode: Binding(
                            get: { viewModel.otpCode },
                            set: { viewModel.updateOTP($0) }
                        ),
                        availableDomains: viewModel.availableDomains,
                        emailAddress: viewModel.emailAddress,
                        hasSentCode: viewModel.hasSentCode,
                        isVerified: viewModel.isEmailVerified,
                        secondsRemaining: viewModel.secondsRemaining,
                        feedbackMessage: viewModel.emailFeedbackMessage,
                        feedbackTone: viewModel.emailFeedbackTone,
                        shakeTrigger: viewModel.otpShakeTrigger,
                        onBack: navigateBack,
                        onChangeEmail: viewModel.resetEmailVerification,
                        onSendCode: viewModel.sendVerificationCode,
                        onResendCode: viewModel.resendVerificationCode,
                        onVerifyCode: viewModel.attemptVerification(with:),
                        onNext: viewModel.moveToPasswordSetup
                    )
                    // 인증 카운트다운 틱은 이 단계에 머무는 동안에만 필요하다. 예전에는 SignUpView
                    // 전체(NavigationStack 루트)에 걸려 있어서, 약관/비밀번호/완료 단계로 넘어간 뒤에도
                    // 매초 구독이 살아 있었다. 라우트 콘텐츠에 붙여 이 화면이 스택에서 사라지면
                    // 함께 취소되도록 한다.
                    .onReceive(viewModel.verificationTimer) { _ in
                        viewModel.tickVerificationTimer()
                    }
                case .passwordSetup:
                    SignupPasswordView(
                        email: viewModel.emailAddress,
                        password: Binding(
                            get: { viewModel.password },
                            set: { viewModel.updatePassword($0) }
                        ),
                        confirmPassword: Binding(
                            get: { viewModel.confirmPassword },
                            set: { viewModel.updateConfirmPassword($0) }
                        ),
                        errorMessage: viewModel.errorMessage,
                        onBack: navigateBack,
                        onComplete: finishSignup
                    )
                case .complete:
                    SignupCompleteView {
                        onCompleted(viewModel.emailAddress)
                    }
                }
            }
        }
        .background(PFGradientBackground())
        .preferredColorScheme(.light)
    }

    private func navigateBack() {
        viewModel.navigateBack()
    }

    private func finishSignup() {
        Task {
            guard await viewModel.submitSignup() else { return }
            viewModel.moveToComplete()
        }
    }
}

#Preview {
    SignUpView(
        onBackToLogin: {},
        onCompleted: { _ in }
    )
}
