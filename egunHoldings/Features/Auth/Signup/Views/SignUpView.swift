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
        .onReceive(viewModel.verificationTimer) { _ in
            viewModel.tickVerificationTimer()
        }
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
