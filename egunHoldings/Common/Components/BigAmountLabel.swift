import SwiftUI

struct BigAmountLabel: View {
    let prefix: String
    let integer: String
    let decimal: String

    init(prefix: String = "$", integer: String, decimal: String = "") {
        self.prefix = prefix
        self.integer = integer
        self.decimal = decimal
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(prefix + integer)
                .font(PSFont.display())
                .foregroundStyle(Color.textPrimary)
                .tracking(PSFont.displayTracking)

            if !normalizedDecimal.isEmpty {
                Text(normalizedDecimal)
                    .font(.pretendard(26, weight: .bold))
                    .foregroundStyle(Color.brand)
                    .tracking(PSFont.displayTracking)
                    .baselineOffset(6)
            }
        }
            .monospacedDigit()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityText)
    }

    private var normalizedDecimal: String {
        guard !decimal.isEmpty else { return "" }
        return decimal.hasPrefix(".") ? decimal : ".\(decimal)"
    }

    private var accessibilityText: String {
        "\(prefix)\(integer)\(normalizedDecimal)"
    }
}

#Preview("BigAmountLabel") {
    VStack(alignment: .leading, spacing: 20) {
        BigAmountLabel(prefix: "$", integer: "97,326", decimal: "46")
        BigAmountLabel(prefix: "₩", integer: "12,480,000")
    }
    .padding(24)
    .background(Color.canvas)
}
