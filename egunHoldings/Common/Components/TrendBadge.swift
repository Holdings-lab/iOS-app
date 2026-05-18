import SwiftUI

struct TrendBadge: View {
    let value: String
    let percent: String?
    let suffix: String
    let isUp: Bool

    init(
        value: String,
        percent: String? = nil,
        suffix: String = "Today",
        isUp: Bool = true
    ) {
        self.value = value
        self.percent = percent
        self.suffix = suffix
        self.isUp = isUp
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: isUp ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                .font(.system(size: 8, weight: .bold))

            Text(mainText)
                .font(PSFont.caption())
                .monospacedDigit()

            if !suffix.isEmpty {
                Text(suffix)
                    .font(.pretendard(13, weight: .regular))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .foregroundStyle(tint)
        .lineLimit(1)
        .accessibilityLabel(accessibilityText)
    }

    private var tint: Color {
        isUp ? Color.trendUp : Color.trendDown
    }

    private var mainText: String {
        guard let percent, !percent.isEmpty else { return value }
        let normalizedPercent = percent.hasPrefix("(") ? percent : "(\(percent))"
        return "\(value) \(normalizedPercent)"
    }

    private var accessibilityText: String {
        "\(isUp ? "up" : "down") \(mainText) \(suffix)"
    }
}

#Preview("TrendBadge") {
    VStack(alignment: .leading, spacing: 16) {
        TrendBadge(value: "65.63", percent: "76.23%", isUp: true)
        TrendBadge(value: "2.02", percent: "2.02%", isUp: false)
    }
    .padding(24)
    .background(Color.canvas)
}
