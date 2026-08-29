import SwiftUI

struct SettingsPasswordModal: View {
    let isPresented: Bool
    let onClose: () -> Void
    let notify: (String) -> Void

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSuccess = false

    private var errorMessage: String? {
        if !newPassword.isEmpty, !confirmPassword.isEmpty, newPassword != confirmPassword {
            return "새 비밀번호가 일치하지 않아요"
        }
        if !newPassword.isEmpty, newPassword.count < 8 {
            return "8자 이상 입력해주세요"
        }
        return nil
    }

    private var isValid: Bool {
        !currentPassword.isEmpty && newPassword.count >= 8 && newPassword == confirmPassword
    }

    var body: some View {
        SettingsModalContainer(isPresented: isPresented, onDismiss: close) {
            if isSuccess {
                successContent
            } else {
                formContent
            }
        }
        .onChange(of: isPresented) { _, presented in
            if !presented { reset() }
        }
    }

    private var formContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("비밀번호 변경")
                .font(.pretendard(16, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            field(label: "현재 비밀번호", text: $currentPassword)
                .padding(.top, 12)
            field(label: "새 비밀번호", text: $newPassword)
                .padding(.top, 12)
            field(label: "새 비밀번호 확인", text: $confirmPassword)
                .padding(.top, 12)

            if let errorMessage {
                Text(errorMessage)
                    .font(.pretendard(12, weight: .semibold))
                    .foregroundStyle(Color.trendDown)
                    .padding(.top, 8)
            }

            HStack(spacing: 8) {
                Button(action: close) {
                    Text("취소")
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

                Button(action: submit) {
                    Text("변경하기")
                        .font(.pretendard(13.5, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(isValid ? Color.brand : Color.muted, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!isValid)
            }
            .padding(.top, 18)
        }
    }

    private var successContent: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color.successBg)
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.success)
                }

            Text("변경 완료")
                .font(.pretendard(14, weight: .bold))
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    private func field(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.pretendard(12, weight: .semibold))
                .foregroundStyle(Color.textSecondary)

            SecureField("", text: text)
                .font(.pretendard(14, weight: .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(Color.subtle, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.hairline, lineWidth: 1.5)
                }
        }
    }

    private func submit() {
        guard isValid else { return }
        isSuccess = true
        Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            onClose()
            notify("비밀번호를 변경했어요")
        }
    }

    private func close() {
        guard !isSuccess else { return }
        onClose()
    }

    private func reset() {
        currentPassword = ""
        newPassword = ""
        confirmPassword = ""
        isSuccess = false
    }
}
