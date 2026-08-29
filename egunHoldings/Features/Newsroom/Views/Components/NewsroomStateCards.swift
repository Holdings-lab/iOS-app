import SwiftUI

struct NewsroomErrorCard: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        NewsroomStatusCard(
            iconName: "wifi.exclamationmark",
            title: "불러오지 못했어요",
            message: message,
            actionTitle: "다시 불러오기",
            action: onRetry
        )
    }
}

struct NewsroomNoHoldingsCard: View {
    let onRegister: () -> Void

    var body: some View {
        NewsroomStatusCard(
            iconName: "tray",
            title: "아직 등록된 자산이 없어요",
            message: "보유 자산을 등록하면 내 포트폴리오 기준으로 소식을 정리해드려요.",
            actionTitle: "자산 등록하기",
            action: onRegister
        )
    }
}

struct NewsroomNoRelatedNewsCard: View {
    var body: some View {
        NewsroomStatusCard(
            iconName: "newspaper",
            title: "관련 뉴스가 아직 없어요",
            message: "관련 소식을 찾는 대로 알려드릴게요."
        )
    }
}

private struct NewsroomStatusCard: View {
    let iconName: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.brand)
                .frame(width: 46, height: 46)
                .background(Color.brandTintBg, in: Circle())

            Text(title)
                .font(.pretendard(17, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.pretendard(13.5, weight: .medium))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.pretendard(13.5, weight: .bold))
                    .foregroundStyle(Color.textOnAccent)
                    .padding(.horizontal, 18)
                    .frame(minHeight: 44)
                    .background(Color.brand, in: Capsule(style: .continuous))
                    .buttonStyle(PressScaleButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 22)
        .padding(.vertical, 28)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }
}
