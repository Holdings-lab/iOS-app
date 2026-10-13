import SwiftUI

// MARK: - Modal shell

struct SettingsModalContainer<Content: View>: View {
    let isPresented: Bool
    let onDismiss: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.42)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture(perform: onDismiss)

                VStack(alignment: .leading, spacing: 0) {
                    content()
                }
                .padding(20)
                .frame(maxWidth: 300)
                .background(Color.elevated, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.black.opacity(0.28), radius: 40, x: 0, y: 16)
                .transition(.scale(scale: 0.94).combined(with: .opacity))
                .accessibilityAddTraits(.isModal)
            }
            .transition(.opacity)
        }
    }
}

struct SettingsConfirmModal: View {
    let isPresented: Bool
    let title: String
    var desc: String?
    var confirmLabel = "확인"
    var cancelLabel: String? = "취소"
    var danger = false
    var isProcessing = false
    var errorMessage: String?
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        SettingsModalContainer(isPresented: isPresented, onDismiss: onCancel) {
            Text(title)
                .font(.pretendard(16, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            if let desc {
                Text(desc)
                    .font(.pretendard(13, weight: .regular))
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.pretendard(12, weight: .medium))
                    .foregroundStyle(Color.trendDown)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
            }

            HStack(spacing: 8) {
                if let cancelLabel {
                    Button(action: onCancel) {
                        Text(cancelLabel)
                            .font(.pretendard(13.5, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.subtle, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.hairline, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessing)
                }

                Button(action: onConfirm) {
                    Group {
                        if isProcessing {
                            ProgressView().tint(.white)
                        } else {
                            Text(confirmLabel)
                                .font(.pretendard(13.5, weight: .bold))
                        }
                    }
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(danger ? Color.trendDown : Color.brand, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isProcessing)
            }
            .padding(.top, 18)
        }
    }
}
