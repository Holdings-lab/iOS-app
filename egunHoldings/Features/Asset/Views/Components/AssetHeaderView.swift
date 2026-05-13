import SwiftUI

struct AssetHeaderView: View {
    let totalAmount: String
    let profitSummary: String
    let profitColor: Color

    init(
        totalAmount: String = "",
        profitSummary: String = "",
        profitColor: Color = .textTertiary
    ) {
        self.totalAmount = totalAmount
        self.profitSummary = profitSummary
        self.profitColor = profitColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("내 자산")
                .font(.pretendard(25, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            if !totalAmount.isEmpty {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(totalAmount)
                        .font(.pretendard(29, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    if !profitSummary.isEmpty {
                        Text(profitSummary)
                            .font(.pretendard(13, weight: .bold))
                            .foregroundStyle(profitColor)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                    }
                }
            }
        }
    }
}
