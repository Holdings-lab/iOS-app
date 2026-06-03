import SwiftUI

struct PrimaryGradientButton: View {
    let title: String
    let symbol: String?
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void

    init(
        title: String,
        symbol: String? = nil,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.symbol = symbol
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(Color.textOnAccent)
                        .controlSize(.small)
                }
                Text(title)
                if let symbol {
                    Image(systemName: symbol)
                }
            }
            .font(.pretendard(17, weight: .semibold))
            .foregroundStyle(usesActiveStyle ? Color.textOnAccent : Color.textDisabled)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                buttonBackground,
                in: RoundedRectangle(cornerRadius: KDXRadius.button, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: KDXRadius.button, style: .continuous)
                    .stroke(usesActiveStyle ? Color.clear : Color.hairline, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
    }

    private var usesActiveStyle: Bool {
        isEnabled || isLoading
    }

    private var buttonBackground: LinearGradient {
        if usesActiveStyle {
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
