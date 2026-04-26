import SwiftUI

struct AuthInputField: View {
    let placeholder: String
    let icon: String
    @Binding var text: String
    var secure: Bool = false
    var disablePasswordAutofill: Bool = false
    var forceASCIIKeyboard: Bool = false
    var keyboardType: UIKeyboardType = .default

    @State private var isSecureEntry: Bool = true

    private var inputFont: Font {
        // SecureField와 일부 커스텀 폰트 조합에서 마스킹 글리프가 비정상 렌더링되는 현상 대응
        (secure && isSecureEntry) ? .system(size: 16, weight: .medium) : .pretendard(16, weight: .medium)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.midnightTextSecondary)
                .frame(width: 24)

            Group {
                if secure && isSecureEntry {
                    SecureField(
                        text: $text,
                        prompt: Text(placeholder).foregroundStyle(Color.midnightTextSecondary)
                    ) {
                    }
                } else {
                    TextField(
                        text: $text,
                        prompt: Text(placeholder).foregroundStyle(Color.midnightTextSecondary)
                    ) {
                    }
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .textContentType(disablePasswordAutofill ? .oneTimeCode : nil)
            .keyboardType(forceASCIIKeyboard ? .asciiCapable : keyboardType)
            .font(inputFont)
            .foregroundStyle(Color.midnightTextPrimary)

            if secure {
                Button {
                    isSecureEntry.toggle()
                } label: {
                    Image(systemName: isSecureEntry ? "eye" : "eye.slash")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.midnightTextSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 56)
        .background(Color.midnightSurface, in: RoundedRectangle(cornerRadius: PFRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PFRadius.card, style: .continuous)
                .stroke(Color.midnightBorder, lineWidth: 1)
        }
    }
}
