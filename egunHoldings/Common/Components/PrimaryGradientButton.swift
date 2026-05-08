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
            .foregroundStyle(isEnabled ? Color.textOnAccent : Color.textDisabled)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                buttonBackground,
                in: RoundedRectangle(cornerRadius: KDXRadius.button, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: KDXRadius.button, style: .continuous)
                    .stroke(isEnabled ? Color.clear : Color.hairline, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private var buttonBackground: LinearGradient {
        if isEnabled {
            return LinearGradient(
                colors: [Color.brand, Color.brandDark],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        let disabled = Color.muted
        return LinearGradient(colors: [disabled, disabled], startPoint: .leading, endPoint: .trailing)
    }
}
