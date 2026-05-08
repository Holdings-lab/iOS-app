import SwiftUI

enum SocialLoginProvider: String, CaseIterable, Hashable {
    case apple
    case google
    case kakao = "kakao-talk"

    var assetName: String {
        rawValue
    }

    var title: String {
        switch self {
        case .apple:
            return "Sign With Apple"
        case .google:
            return "Sign with Google"
        case .kakao:
            return "카카오 로그인"
        }
    }

    var accessibilityLabel: String {
        title
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

struct LoginView: View {
    let errorMessage: String?
    let onLogin: (_ email: String, _ password: String) -> Void
    let onSocialLogin: (SocialLoginProvider) -> Void
    let onTapSignUp: () -> Void

    @State private var email: String = ""
    @State private var password: String = ""

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
                    text: $email,
                    keyboardType: .emailAddress
                )
                AuthInputField(placeholder: "비밀번호", icon: "lock", text: $password, secure: true)
            }

            if let errorMessage {
                PFInlineErrorText(message: errorMessage)
            }

            PrimaryGradientButton(title: "로그인") {
                onLogin(email, password)
            }

            socialDivider

            VStack(spacing: PFSpacing.item) {
                ForEach(SocialLoginProvider.allCases, id: \.self) { provider in
                    SocialButton(provider: provider) {
                        onSocialLogin(provider)
                    }
                }
            }

            HStack(spacing: 6) {
                Text("계정이 없으신가요?")
                    .foregroundStyle(Color.textTertiary)
                Button("회원가입") {
                    onTapSignUp()
                }
                .foregroundStyle(Color.brand)
                .buttonStyle(.plain)
            }
            .font(.pretendard(15, weight: .medium))

            VStack(spacing: 4) {
                Text("데모 기존 계정: investor@policyfinance.app / demo1234")
                Text("온보딩 테스트 계정: eom175@naver.com / 11111111")
            }
            .font(.pretendard(12, weight: .medium))
            .foregroundStyle(Color.textTertiary.opacity(0.8))
        }
        .background(PFGradientBackground())
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

                Text(provider.title)
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
        errorMessage: nil,
        onLogin: { _, _ in },
        onSocialLogin: { _ in },
        onTapSignUp: {}
    )
    .preferredColorScheme(.light)
}
