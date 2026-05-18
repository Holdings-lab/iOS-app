import SwiftUI

struct AssetHeaderView: View {
    let totalAmount: String
    let profitSummary: String
    let profitColor: Color
    let showsNotificationIcon: Bool

    init(
        totalAmount: String = "",
        profitSummary: String = "",
        profitColor: Color = .textTertiary,
        showsNotificationIcon: Bool = true
    ) {
        self.totalAmount = totalAmount
        self.profitSummary = profitSummary
        self.profitColor = profitColor
        self.showsNotificationIcon = showsNotificationIcon
    }

    var body: some View {
        PSGlassCard(padding: PSSpacing.cardPadding) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Portfolio Balance")
                        .font(PSFont.caption())
                        .foregroundStyle(Color.textSecondary)

                    BigAmountLabel(
                        prefix: amountParts.prefix,
                        integer: amountParts.integer,
                        decimal: amountParts.decimal
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                    if !profitSummary.isEmpty {
                        TrendBadge(
                            value: trendParts.value,
                            percent: trendParts.percent,
                            isUp: trendParts.isUp
                        )
                    }
                }
                .padding(.trailing, showsNotificationIcon ? 46 : 0)

                if showsNotificationIcon {
                    Image(systemName: "bell")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(Color.elevated, in: RoundedRectangle(cornerRadius: PSRadius.button, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: PSRadius.button, style: .continuous)
                                .stroke(Color.divider, lineWidth: 1)
                        }
                }
            }
        }
    }

    private var amountParts: (prefix: String, integer: String, decimal: String) {
        let trimmed = totalAmount.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ("₩", "0", "")
        }

        let prefix: String
        if let first = trimmed.first, !first.isNumber {
            prefix = String(first)
        } else {
            prefix = ""
        }

        let number = prefix.isEmpty ? trimmed : String(trimmed.dropFirst())
        let pieces = number.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)

        return (
            prefix,
            pieces.first.map(String.init) ?? "0",
            pieces.dropFirst().first.map(String.init) ?? ""
        )
    }

    private var trendParts: (value: String, percent: String?, isUp: Bool) {
        let trimmed = profitSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        let isUp = !trimmed.hasPrefix("-")
        let withoutSign = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "+- "))

        guard
            let open = withoutSign.firstIndex(of: "("),
            let close = withoutSign.firstIndex(of: ")"),
            open < close
        else {
            return (withoutSign, nil, isUp)
        }

        let value = withoutSign[..<open]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let percent = withoutSign[withoutSign.index(after: open)..<close]
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return (value, percent, isUp)
    }
}
