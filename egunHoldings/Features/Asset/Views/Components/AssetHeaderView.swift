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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.electricBlue.opacity(0.12))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "wallet.pass.fill")
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundStyle(Color.electricBlue)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text("내 자산")
                        .font(.pretendard(26, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .tracking(-0.5)

                    Text("나는 지금 어디에 노출돼 있지?")
                        .font(.pretendard(13, weight: .medium))
                        .foregroundStyle(Color.mutedForeground)
                }

                Spacer()
            }

            if !totalAmount.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("내 총자산")
                        .font(.pretendard(12, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)

                    Text(totalAmount)
                        .font(.pretendard(31, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    if !profitSummary.isEmpty {
                        Text(profitSummary)
                            .font(.pretendard(13, weight: .bold))
                            .foregroundStyle(profitColor)
                            .monospacedDigit()
                    }
                }
            }
        }
    }
}
