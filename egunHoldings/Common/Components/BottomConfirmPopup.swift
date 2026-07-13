import SwiftUI

struct BottomConfirmPopup: Equatable {
    let message: String
    var primaryTitle = "이대로 진행할게요"
    var secondaryTitle = "다시 선택할게요"
}

private struct BottomConfirmPopupCard: View {
    let popup: BottomConfirmPopup
    let onPrimary: () -> Void
    let onSecondary: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(Color.warningBg)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.warning)
                    }

                Text(popup.message)
                    .font(.pretendard(14, weight: .medium))
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }

            HStack(spacing: 8) {
                Button(action: onSecondary) {
                    Text(popup.secondaryTitle)
                        .font(.pretendard(15, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.subtle, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: onPrimary) {
                    Text(popup.primaryTitle)
                        .font(.pretendard(15, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.brand, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
        .shadow(color: Color.cardShadow, radius: 28, x: 0, y: -6)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
}

private struct BottomConfirmPopupModifier: ViewModifier {
    @Binding var popup: BottomConfirmPopup?
    let onPrimary: () -> Void
    let onSecondary: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var animation: Animation? {
        reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.85)
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                if popup != nil {
                    Color.black.opacity(0.28)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture { dismiss(calling: onSecondary) }
                }
            }
            .overlay(alignment: .bottom) {
                if let popup {
                    BottomConfirmPopupCard(
                        popup: popup,
                        onPrimary: { dismiss(calling: onPrimary) },
                        onSecondary: { dismiss(calling: onSecondary) }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(animation, value: popup != nil)
    }

    private func dismiss(calling action: () -> Void) {
        popup = nil
        action()
    }
}

extension View {
    /// 화면 하단에서 올라오는 경고성 확인 팝업. 앱 전역 디자인 토큰(Color.brand/warning 등)을 사용하며,
    /// 네이티브 alert/actionSheet 대신 이 컴포넌트로 통일한다.
    func bottomConfirmPopup(
        _ popup: Binding<BottomConfirmPopup?>,
        onPrimary: @escaping () -> Void,
        onSecondary: @escaping () -> Void = {}
    ) -> some View {
        modifier(BottomConfirmPopupModifier(popup: popup, onPrimary: onPrimary, onSecondary: onSecondary))
    }
}
