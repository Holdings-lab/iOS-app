import SwiftUI

enum InlineFeedbackTone {
    case neutral
    case success
    case error

    var color: Color {
        switch self {
        case .neutral:
            return Color.midnightTextSecondary
        case .success:
            return Color.midnightSuccess
        case .error:
            return Color.midnightError
        }
    }
}

struct InlineFeedbackText: View {
    let message: String
    let tone: InlineFeedbackTone
    var asBanner: Bool = false

    var body: some View {
        Text(message)
            .font(.pretendard(asBanner ? 14 : 13, weight: .medium))
            .foregroundStyle(tone.color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, asBanner ? 14 : 0)
            .padding(.vertical, asBanner ? 12 : 0)
            .background(
                Group {
                    if asBanner {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(tone.color.opacity(0.08))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(tone.color.opacity(0.16), lineWidth: 1)
                            }
                    }
                }
            )
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    VStack(spacing: 16) {
        InlineFeedbackText(message: "가입이 완료됐어요. 로그인해서 시작해보세요.", tone: .success, asBanner: true)
        InlineFeedbackText(message: "필수 항목에 동의하면 계속할 수 있어요.", tone: .neutral)
        InlineFeedbackText(message: "인증번호가 올바르지 않아요.", tone: .error)
    }
    .padding(24)
    .background(PFGradientBackground())
}
