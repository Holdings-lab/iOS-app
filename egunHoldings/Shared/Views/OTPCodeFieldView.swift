import SwiftUI

struct OTPCodeFieldView: View {
    @Binding var code: String
    var shakeTrigger: Int
    let onCompleted: (String) -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { index in
                    otpBox(at: index)
                }
            }

            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .foregroundStyle(.clear)
                .accentColor(.clear)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .focused($isFocused)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isFocused = true
            }
        }
        .onChange(of: code) { _, newValue in
            let filtered = String(newValue.filter(\.isNumber).prefix(6))
            if filtered != newValue {
                code = filtered
            }

            if filtered.count == 6 {
                isFocused = false
                onCompleted(filtered)
            }
        }
        .modifier(ShakeEffect(animatableData: CGFloat(shakeTrigger)))
    }

    private func otpBox(at index: Int) -> some View {
        let characters = Array(code)
        let isFilled = index < characters.count
        let isActive = isFocused && index == min(characters.count, 5)

        return RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.midnightSurface)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isActive ? Color.midnightAccent : Color.midnightBorder, lineWidth: 1)

                Text(isFilled ? String(characters[index]) : "")
                    .font(.pretendard(22, weight: .semibold))
                    .foregroundStyle(Color.midnightTextPrimary)
            }
    }
}

private struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(
            translationX: amount * sin(animatableData * .pi * shakesPerUnit),
            y: 0
        ))
    }
}

#Preview {
    PreviewOTPField()
        .padding(24)
        .background(PFGradientBackground())
}

private struct PreviewOTPField: View {
    @State private var code = ""
    @State private var trigger = 0

    var body: some View {
        VStack(spacing: 16) {
            OTPCodeFieldView(code: $code, shakeTrigger: trigger) { _ in }
            Button("Shake") { trigger += 1 }
        }
    }
}
