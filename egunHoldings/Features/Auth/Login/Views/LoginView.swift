import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel

    let onLoginSuccess: (LoginSession) -> Void
    let onTapSignUp: () -> Void

    @FocusState private var focusedField: LoginField?

    private enum LoginField {
        case email
        case password
    }

    var body: some View {
        PFContentScrollView(spacing: PFSpacing.section, topPadding: 16, bottomPadding: 16) {
            Spacer(minLength: 8)

            appIcon

            VStack(spacing: 8) {
                Text("폴리시 파이낸스")
                    .font(.pretendard(32, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text("정책이 만드는 투자 기회를 잡으세요")
                    .font(.pretendard(15, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }

            VStack(spacing: PFSpacing.item) {
                AuthInputField(
                    placeholder: "이메일 주소",
                    icon: "envelope",
                    text: $viewModel.email,
                    keyboardType: .emailAddress,
                    textContentType: .username,
                    submitLabel: .next,
                    onSubmit: {
                        focusedField = .password
                    }
                )
                .focused($focusedField, equals: .email)

                AuthInputField(
                    placeholder: "비밀번호",
                    icon: "lock",
                    text: $viewModel.password,
                    secure: true,
                    textContentType: .password,
                    submitLabel: .go,
                    onSubmit: submitLogin
                )
                .focused($focusedField, equals: .password)
            }

            if let errorMessage = viewModel.errorMessage {
                PFInlineErrorText(message: errorMessage)
            }

            PrimaryGradientButton(
                title: viewModel.isLoading ? "로그인 중..." : "로그인",
                isEnabled: viewModel.canSubmit,
                isLoading: viewModel.isLoading,
                action: submitLogin
            )

            socialDivider

            VStack(spacing: PFSpacing.item) {
                ForEach(viewModel.socialProviders, id: \.self) { provider in
                    SocialButton(provider: provider) {
                        viewModel.login(with: provider)
                    }
                    .disabled(viewModel.isLoading)
                    .opacity(viewModel.isLoading ? 0.55 : 1)
                }
            }

            HStack(spacing: 6) {
                Text("계정이 없으신가요?")
                    .foregroundStyle(Color.textTertiary)
                Button("회원가입") {
                    onTapSignUp()
                }
                .disabled(viewModel.isLoading)
                .foregroundStyle(Color.brand)
                .buttonStyle(.plain)
            }
            .font(.pretendard(15, weight: .medium))
        }
        .background(PFGradientBackground())
    }

    private func submitLogin() {
        guard viewModel.canSubmit else { return }
        focusedField = nil

        Task {
            if let session = await viewModel.submitLogin() {
                onLoginSuccess(session)
            }
        }
    }

    private var appIcon: some View {
        BrandWaveLogo()
            .frame(width: 148, height: 54)
    }

    private var socialDivider: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(Color.divider)
                .frame(height: 1)

            Text("또는")
                .font(.pretendard(14, weight: .medium))
                .foregroundStyle(Color.textTertiary)

            Rectangle()
                .fill(Color.divider)
                .frame(height: 1)
        }
    }
}

private struct SocialButton: View {
    let provider: SocialLoginProvider
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                socialIcon

                Text(provider.displayTitle)
                    .font(.pretendard(16, weight: .semibold))
                    .foregroundStyle(provider.foregroundColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                provider.backgroundColor,
                in: RoundedRectangle(cornerRadius: PFRadius.card, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: PFRadius.card, style: .continuous)
                    .stroke(provider.borderColor, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: PFRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(provider.accessibilityLabel)
    }

    @ViewBuilder
    private var socialIcon: some View {
        switch provider.iconRenderingMode {
        case .template:
            Image(provider.assetName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(provider.foregroundColor)
        default:
            Image(provider.assetName)
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
        }
    }
}

private extension SocialLoginProvider {
    var accessibilityLabel: String {
        displayTitle
    }

    var backgroundColor: Color {
        switch self {
        case .apple:
            return Color.black.opacity(0.92)
        case .google:
            return .white
        case .kakao:
            return Color(hex: "FEE500")
        }
    }

    var foregroundColor: Color {
        switch self {
        case .apple:
            return .white
        case .google, .kakao:
            return Color(hex: "191919")
        }
    }

    var borderColor: Color {
        switch self {
        case .apple:
            return Color.divider
        case .google:
            return Color.black.opacity(0.08)
        case .kakao:
            return Color.clear
        }
    }

    var iconRenderingMode: Image.TemplateRenderingMode? {
        switch self {
        case .apple:
            return .template
        case .google, .kakao:
            return .original
        }
    }
}

struct BrandWaveLogo: View {
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.brand, Color.brandDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("P")
                    .font(.pretendard(22, weight: .bold))
                    .foregroundStyle(Color.textOnAccent)
            }
            .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 2) {
                Text("POLSIGNAL")
                    .font(.pretendard(10, weight: .semibold))
                    .foregroundStyle(Color.textQuaternary)

                Text("로그인")
                    .font(.pretendard(14, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
            }
        }
    }
}

#Preview {
    LoginView(
        viewModel: LoginViewModel(),
        onLoginSuccess: { _ in },
        onTapSignUp: {}
    )
    .preferredColorScheme(.light)
}
