import Combine
import SwiftUI

struct SignupEmailAuthView: View {
    @Binding var emailLocalPart: String
    @Binding var selectedDomain: SignupEmailDomainOption
    @Binding var customDomain: String
    @Binding var otpCode: String

    let availableDomains: [SignupEmailDomainOption]
    let emailAddress: String
    let hasSentCode: Bool
    let isVerified: Bool
    let secondsRemaining: Int
    let feedbackMessage: String?
    let feedbackTone: InlineFeedbackTone?
    let shakeTrigger: Int
    let onBack: () -> Void
    let onChangeEmail: () -> Void
    let onSendCode: () -> Void
    let onResendCode: () -> Void
    let onVerifyCode: (String) -> Void
    let onNext: () -> Void
    @State private var keyboardHeight: CGFloat = 0

    private var canSend: Bool {
        !emailAddress.isEmpty
    }

    private var isKeyboardVisible: Bool {
        keyboardHeight > 0
    }

    private var isCompactOTPLayout: Bool {
        hasSentCode && isKeyboardVisible
    }

    private var timeText: String {
        let minutes = max(secondsRemaining, 0) / 60
        let seconds = max(secondsRemaining, 0) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        PFContentScrollView(
            alignment: .leading,
            spacing: isCompactOTPLayout ? 16 : 24,
            horizontalPadding: MidnightLayout.horizontal,
            topPadding: isCompactOTPLayout ? 12 : 16,
            bottomPadding: isCompactOTPLayout ? 28 : 120
        ) {
            FlowProgressHeader(currentStep: 2, totalSteps: 4, onBack: onBack)

            VStack(alignment: .leading, spacing: 10) {
                Text("이메일을 인증해주세요")
                    .font(.pretendard(28, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.92))

                Text("로그인에 사용할 이메일이에요.")
                    .font(.pretendard(16, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.62))
            }

            if hasSentCode {
                verifiedEmailCard
                otpCard
            } else {
                emailComposer
                tipCard
            }

            if let feedbackMessage, let feedbackTone {
                InlineFeedbackText(message: feedbackMessage, tone: feedbackTone)
            }

            if hasSentCode && !isVerified {
                InlineFeedbackText(message: "인증을 완료하면 다음 단계로 이동할 수 있어요.", tone: .neutral)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !(hasSentCode && isKeyboardVisible) {
                FlowPrimaryButton(
                    title: hasSentCode ? "다음" : "인증번호 보내기",
                    isEnabled: hasSentCode ? isVerified : canSend,
                    action: hasSentCode ? onNext : onSendCode
                )
                .padding(.horizontal, MidnightLayout.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(PFGradientBackground())
        .toolbar(.hidden, for: .navigationBar)
        .animation(.easeInOut(duration: 0.2), value: isCompactOTPLayout)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                return
            }
            keyboardHeight = frame.height
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
    }

    private var emailComposer: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                emailLocalInput
                emailDomainMenu
            }

            if selectedDomain == .direct {
                domainInput
            }
        }
    }

    private var verifiedEmailCard: some View {
        FlowSurfaceCard {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("인증할 이메일")
                        .font(.pretendard(12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.52))

                    Text(emailAddress)
                        .font(.pretendard(15, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.92))
                }

                Spacer()

                Button("변경") {
                    onChangeEmail()
                }
                .font(.pretendard(13, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.62))
                .buttonStyle(.plain)
            }
        }
    }

    private var otpCard: some View {
        FlowSurfaceCard {
            VStack(alignment: .leading, spacing: isCompactOTPLayout ? 10 : 14) {
                Text("인증번호 6자리를 입력해주세요")
                    .font(.pretendard(15, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.9))

                OTPCodeFieldView(code: $otpCode, shakeTrigger: shakeTrigger, onCompleted: onVerifyCode)

                HStack {
                    Text(timeText)
                        .font(.pretendard(13, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.62))

                    Spacer()

                    Button("재전송") {
                        onResendCode()
                    }
                    .font(.pretendard(13, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.62))
                    .buttonStyle(.plain)
                }

                Text("인증번호가 오지 않으면 스팸함과 프로모션함도 함께 확인해주세요.")
                    .font(.pretendard(isCompactOTPLayout ? 12 : 13, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.46))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var tipCard: some View {
        FlowSurfaceCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("인증 팁")
                    .font(.pretendard(12, weight: .semibold))
                    .foregroundStyle(Color(hex: "5BBBFF"))

                Text("메일 주소를 정확히 입력하면 3분 동안 사용할 수 있는 인증번호를 보내드려요.")
                    .font(.pretendard(15, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)

                Text("회사 메일을 쓰는 경우 수신 보안 정책 때문에 조금 늦을 수 있어요.")
                    .font(.pretendard(13, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.56))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var emailLocalInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("이메일")
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.52))

            HStack(spacing: 8) {
                TextField(
                    "",
                    text: $emailLocalPart,
                    prompt: Text("example").foregroundStyle(Color.white.opacity(0.38))
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .keyboardType(.emailAddress)
                .font(.pretendard(16, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.92))

                Text("@")
                    .font(.pretendard(16, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.46))
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(Color.midnightSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var emailDomainMenu: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("도메인")
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.52))

            Menu {
                ForEach(availableDomains) { domain in
                    Button(domain.title) {
                        selectedDomain = domain
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(selectedDomain.title)
                        .font(.pretendard(15, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.92))
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.46))
                }
                .padding(.horizontal, 16)
                .frame(height: 54)
                .background(Color.midnightSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
        .frame(width: 150)
    }

    private var domainInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("직접 입력")
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.52))

            TextField(
                "",
                text: $customDomain,
                prompt: Text("domain.com").foregroundStyle(Color.white.opacity(0.38))
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .keyboardType(.emailAddress)
            .font(.pretendard(16, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.92))
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(Color.midnightSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            }
        }
    }
}

#Preview {
    PreviewSignupEmailAuth()
        .preferredColorScheme(.dark)
}

private struct PreviewSignupEmailAuth: View {
    @State private var emailLocalPart = "policy"
    @State private var selectedDomain: SignupEmailDomainOption = .naver
    @State private var customDomain = ""
    @State private var otp = ""

    var body: some View {
        SignupEmailAuthView(
            emailLocalPart: $emailLocalPart,
            selectedDomain: $selectedDomain,
            customDomain: $customDomain,
            otpCode: $otp,
            availableDomains: SignupEmailDomainOption.allCases,
            emailAddress: "policy@naver.com",
            hasSentCode: false,
            isVerified: false,
            secondsRemaining: 180,
            feedbackMessage: nil,
            feedbackTone: nil,
            shakeTrigger: 0,
            onBack: {},
            onChangeEmail: {},
            onSendCode: {},
            onResendCode: {},
            onVerifyCode: { _ in },
            onNext: {}
        )
    }
}
