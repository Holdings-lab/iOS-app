import SwiftUI

struct AssetCompositionBar: View {
    let segments: [AssetCompositionSegment]

    private let segmentSpacing: CGFloat = 2

    var body: some View {
        GeometryReader { proxy in
            let totalSpacing = CGFloat(max(segments.count - 1, 0)) * segmentSpacing
            let availableWidth = max(0, proxy.size.width - totalSpacing)
            let totalPercent = max(1, segments.reduce(0) { $0 + $1.percent })

            HStack(spacing: segmentSpacing) {
                ForEach(segments) { segment in
                    Capsule(style: .continuous)
                        .fill(segment.color)
                        .frame(
                            width: availableWidth * CGFloat(segment.percent) / CGFloat(totalPercent),
                            height: 6
                        )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 6)
        .clipShape(Capsule(style: .continuous))
    }
}

struct AssetCompositionLegend: View {
    let segments: [AssetCompositionSegment]
    var foregroundStyle: Color = AssetTabPalette.textSecondary

    private let columns = [
        GridItem(.flexible(), spacing: 0),
        GridItem(.flexible(), spacing: 0)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 7) {
            ForEach(segments) { segment in
                HStack(spacing: 6) {
                    Circle()
                        .fill(segment.color)
                        .frame(width: 7, height: 7)

                    Text(segment.title)
                        .font(.pretendard(11, weight: .medium))
                        .foregroundStyle(foregroundStyle.opacity(0.78))

                    Text("\(segment.percent)%")
                        .font(.pretendard(11, weight: .bold))
                        .foregroundStyle(foregroundStyle)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct AssetHoldingDisplayRow: View {
    let holding: AssetPortfolioHoldingRow

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                if holding.isCash {
                    Text("💵")
                        .font(.system(size: 14))
                        .frame(width: 28, height: 28)
                        .background(
                            AssetTabPalette.subBackground,
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(AssetTabPalette.divider, lineWidth: 1)
                        }
                } else if let symbol = holding.symbol {
                    Text(symbol.uppercased())
                        .font(.pretendard(11, weight: .bold))
                        .foregroundStyle(AssetTabPalette.brand)
                        .tracking(0.44)
                        .padding(.horizontal, 9)
                        .frame(height: 22)
                        .background(
                            AssetTabPalette.brandSoft,
                            in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color(hex: "DBEAFE"), lineWidth: 1)
                        }
                }

                Text(holding.title)
                    .font(.pretendard(15, weight: .semibold))
                    .foregroundStyle(AssetTabPalette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(holding.subtitle)
                    .font(.pretendard(13, weight: .regular))
                    .foregroundStyle(AssetTabPalette.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 3) {
                Text(holding.amountText)
                    .font(.pretendard(15, weight: .semibold))
                    .foregroundStyle(AssetTabPalette.textPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(holding.profitText)
                    .font(.pretendard(13, weight: .semibold))
                    .foregroundStyle(holding.profitTone.color)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .frame(minWidth: 132, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct AssetSummaryRow: View {
    let title: String
    let value: String
    let valueColor: Color
    var isEmphasized = false

    var body: some View {
        HStack {
            Text(title)
                .font(.pretendard(13, weight: .regular))
                .foregroundStyle(AssetTabPalette.textSecondary)

            Spacer()

            Text(value)
                .font(.pretendard(isEmphasized ? 17 : 15, weight: isEmphasized ? .bold : .semibold))
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct AssetDivider: View {
    var body: some View {
        Divider()
            .background(AssetTabPalette.divider)
    }
}
