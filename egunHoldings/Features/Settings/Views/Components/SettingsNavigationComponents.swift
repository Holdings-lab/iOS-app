import SwiftUI

// MARK: - Large header (설정 루트 전용)

/// 피그마 `설정 / 기본`(7:2012) 헤더. 루트는 fullScreenCover로 뜨므로 뒤로가기가 아니라 닫기(X)를 쓴다.
/// 하위 상세 화면은 push라서 계속 `SettingsNavHeader`(뒤로가기)를 쓴다.
struct SettingsLargeHeader: View {
    let eyebrow: String
    let title: String
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(eyebrow)
                    .font(.pretendard(12, weight: .bold))
                    .foregroundStyle(Color.textTertiary)

                Text(title)
                    .font(.pretendard(27, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .tracking(-0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 38, height: 38)
                    .background(Color.elevated, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.hairline, lineWidth: 1)
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("설정 닫기")
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 14)
    }
}
// MARK: - Nav header

struct SettingsNavHeader: View {
    let title: String
    let onBack: () -> Void
    var action: AnyView?

    var body: some View {
        HStack(spacing: 10) {
            LiquidGlassBackButton(accessibilityLabel: "뒤로 가기", action: onBack)

            Spacer()

            Text(title)
                .font(.pretendard(16, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            Spacer()

            if let action {
                action
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.canvas)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.hairline).frame(height: 1)
        }
    }
}
