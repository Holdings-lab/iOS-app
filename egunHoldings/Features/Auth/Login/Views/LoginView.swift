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
            return Color.white.opacity(0.08)
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
                    .foregroundStyle(Color.foreground)

                Text("정책이 만드는 투자 기회를 잡으세요")
                    .font(.pretendard(15, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)
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
                    .foregroundStyle(Color.mutedForeground)
                Button("회원가입") {
                    onTapSignUp()
                }
                .foregroundStyle(Color.electricBlue)
                .buttonStyle(.plain)
            }
            .font(.pretendard(15, weight: .medium))

            VStack(spacing: 4) {
                Text("데모 기존 계정: investor@policyfinance.app / demo1234")
                Text("온보딩 테스트 계정: eom175@naver.com / 11111111")
            }
            .font(.pretendard(12, weight: .medium))
            .foregroundStyle(Color.mutedForeground.opacity(0.8))
        }
        .background(PFGradientBackground())
    }

    private var appIcon: some View {
        BrandWaveLogo()
            .frame(width: 92, height: 54)
    }

    private var socialDivider: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(Color.white.opacity(0.14))
                .frame(height: 1)

            Text("또는")
                .font(.pretendard(14, weight: .medium))
                .foregroundStyle(Color.mutedForeground)

            Rectangle()
                .fill(Color.white.opacity(0.14))
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
        ZStack {
            Circle()
                .fill(Color.midnightAccent.opacity(0.16))
                .frame(width: 56, height: 56)
                .blur(radius: 18)
                .offset(x: -16, y: -2)

            Circle()
                .fill(Color.policyCyan.opacity(0.16))
                .frame(width: 56, height: 56)
                .blur(radius: 18)
                .offset(x: 16, y: 2)

            PolicyWaveShape()
                .stroke(
                    LinearGradient(
                        colors: [Color.midnightAccent, Color.electricBlue, Color.policyCyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round)
                )
        }
    }
}

private struct PolicyWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width * 0.10, y: height * 0.42))
        path.addCurve(
            to: CGPoint(x: width * 0.28, y: height * 0.32),
            control1: CGPoint(x: width * 0.15, y: height * 0.50),
            control2: CGPoint(x: width * 0.20, y: height * 0.16)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.46, y: height * 0.86),
            control1: CGPoint(x: width * 0.34, y: height * 0.54),
            control2: CGPoint(x: width * 0.38, y: height * 0.92)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.61, y: height * 0.18),
            control1: CGPoint(x: width * 0.52, y: height * 0.76),
            control2: CGPoint(x: width * 0.56, y: height * 0.18)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.90, y: height * 0.44),
            control1: CGPoint(x: width * 0.67, y: height * 0.18),
            control2: CGPoint(x: width * 0.78, y: height * 0.62)
        )

        return path
    }
}

#Preview {
    LoginView(
        errorMessage: nil,
        onLogin: { _, _ in },
        onSocialLogin: { _ in },
        onTapSignUp: {}
    )
    .preferredColorScheme(.dark)
}
