import SwiftUI

struct PrimaryGradientButton: View {
    let title: String
    let symbol: String?
    let isEnabled: Bool
    let action: () -> Void

    init(title: String, symbol: String? = nil, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.symbol = symbol
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                if let symbol {
                    Image(systemName: symbol)
                }
            }
            .font(.pretendard(17, weight: .semibold))
            .foregroundStyle(isEnabled ? Color.white : Color.white.opacity(0.35))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                buttonBackground,
                in: RoundedRectangle(cornerRadius: PFRadius.button, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: PFRadius.button, style: .continuous)
                    .stroke(Color.white.opacity(isEnabled ? 0.08 : 0.04), lineWidth: 1)
            }
            .shadow(color: isEnabled ? Color.midnightAccent.opacity(0.14) : .clear, radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private var buttonBackground: LinearGradient {
        if isEnabled {
            return LinearGradient(
                colors: [Color.midnightAccent, Color(hex: "6E7BFA")],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        let disabled = Color.white.opacity(0.12)
        return LinearGradient(colors: [disabled, disabled], startPoint: .leading, endPoint: .trailing)
    }
}
