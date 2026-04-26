import SwiftUI

struct SignupPasswordView: View {
    let email: String
    @Binding var password: String
    @Binding var confirmPassword: String
    let errorMessage: String?
    let onBack: () -> Void
    let onComplete: () -> Void

    private var hasLetter: Bool {
        password.range(of: "[A-Za-z]", options: .regularExpression) != nil
    }

    private var hasNumber: Bool {
        password.range(of: "[0-9]", options: .regularExpression) != nil
    }

    private var hasSpecial: Bool {
        password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
    }

    private var isPasswordValid: Bool {
        password.count >= 8 && password.count <= 16 && hasLetter && hasNumber && hasSpecial
    }

    private var isConfirmationValid: Bool {
        !confirmPassword.isEmpty && confirmPassword == password
    }

    private var validations: [(String, Bool)] {
        [
            ("8자 이상 16자 이하", password.count >= 8 && password.count <= 16),
            ("영문 포함", hasLetter),
            ("숫자 포함", hasNumber),
            ("특수문자 포함", hasSpecial),
            ("비밀번호 확인 일치", isConfirmationValid),
        ]
    }

    var body: some View {
        PFContentScrollView(
            alignment: .leading,
            spacing: MidnightLayout.majorGap,
            horizontalPadding: MidnightLayout.horizontal,
            topPadding: 16,
            bottomPadding: 120
        ) {
            FlowProgressHeader(currentStep: 3, totalSteps: 4, onBack: onBack)

            VStack(alignment: .leading, spacing: 10) {
                Text("비밀번호를 설정해주세요")
                    .font(.pretendard(28, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.92))

                Text("로그인에 사용할 비밀번호예요.")
                    .font(.pretendard(16, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.62))
            }

            Text("✓ \(email)")
                .font(.pretendard(14, weight: .semibold))
                .foregroundStyle(Color.midnightSuccess)

            VStack(alignment: .leading, spacing: 12) {
                AuthInputField(
                    placeholder: "비밀번호",
                    icon: "lock",
                    text: $password,
                    secure: true,
                    disablePasswordAutofill: true,
                    forceASCIIKeyboard: true
                )

                AuthInputField(
                    placeholder: "비밀번호 확인",
                    icon: "lock",
                    text: $confirmPassword,
                    secure: true,
                    disablePasswordAutofill: true,
                    forceASCIIKeyboard: true
                )

                if !confirmPassword.isEmpty {
                    InlineFeedbackText(
                        message: isConfirmationValid ? "비밀번호가 일치합니다." : "비밀번호가 일치하지 않아요.",
                        tone: isConfirmationValid ? .success : .error
                    )
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(validations.enumerated()), id: \.offset) { _, item in
                    validationRow(text: item.0, isValid: item.1)
                }
            }

            if let errorMessage {
                InlineFeedbackText(message: errorMessage, tone: .error)
            }
        }
        .safeAreaInset(edge: .bottom) {
            FlowPrimaryButton(
                title: "다음",
                isEnabled: isPasswordValid && isConfirmationValid,
                action: onComplete
            )
            .padding(.horizontal, MidnightLayout.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 12)
        }
        .background(PFGradientBackground())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func validationRow(text: String, isValid: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isValid ? Color.electricBlue : Color.white.opacity(0.28))

            Text(text)
                .font(.pretendard(14, weight: .medium))
                .foregroundStyle(isValid ? Color.electricBlue : Color.white.opacity(0.52))
        }
    }
}

#Preview {
    PreviewSignupPassword()
        .preferredColorScheme(.dark)
}

private struct PreviewSignupPassword: View {
    @State private var password = ""
    @State private var confirm = ""

    var body: some View {
        SignupPasswordView(
            email: "eom175@daum.net",
            password: $password,
            confirmPassword: $confirm,
            errorMessage: nil,
            onBack: {},
            onComplete: {}
        )
    }
}
