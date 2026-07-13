import SwiftUI

struct RebalancingMetricCard: View {
    let title: String
    let value: String
    let iconName: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.1), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.pretendard(11, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)

                Text(value)
                    .font(.pretendard(15, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassCard()
    }
}

struct RebalancingCompactMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.pretendard(11, weight: .medium))
                .foregroundStyle(Color.mutedForeground)

            Text(value)
                .font(.pretendard(16, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.subtle, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct RebalancingRecommendationCard: View {
    let recommendation: RebalancingRecommendation
    let policy: RebalancingPolicy
    let profileName: String
    let currencyText: (Double) -> String
    let percentText: (Double) -> String
    let percentagePointText: (Double) -> String

    var body: some View {
        DisclosureGroup {
            details
                .padding(.top, 12)
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    actionBadge

                    VStack(alignment: .leading, spacing: 4) {
                        Text(recommendation.assetName)
                            .font(.pretendard(16, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)

                        Text("\(recommendation.symbol) · \(recommendation.assetClass)")
                            .font(.pretendard(12, weight: .medium))
                            .foregroundStyle(Color.mutedForeground)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text(actionSummaryText)
                            .font(.pretendard(15, weight: .bold))
                            .foregroundStyle(recommendation.action.tintColor)
                            .monospacedDigit()

                        Text(currencyText(recommendation.tradeAmount))
                            .font(.pretendard(12, weight: .semibold))
                            .foregroundStyle(Color.textSecondary)
                            .monospacedDigit()
                    }
                }

                HStack(spacing: 8) {
                    RebalancingWeightPill(
                        title: AppVocabulary.Rebalancing.currentWeight,
                        value: percentText(recommendation.currentWeight)
                    )

                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.mutedForeground)

                    RebalancingWeightPill(
                        title: AppVocabulary.Rebalancing.targetWeight,
                        value: percentText(recommendation.targetWeight)
                    )
                }

                Text(recommendation.reasonText)
                    .font(.pretendard(12, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accentColor(Color.mutedForeground)
        .padding(16)
        .glassCard()
    }

    private var actionBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: recommendation.action.symbolName)
                .font(.system(size: 12, weight: .semibold))

            Text(recommendation.action.displayTitle)
                .font(.pretendard(12, weight: .bold))
        }
        .foregroundStyle(recommendation.action.tintColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(recommendation.action.tintColor.opacity(0.1), in: Capsule())
    }

    private var actionSummaryText: String {
        switch recommendation.action {
        case .buy:
            return "\(recommendation.shares)주 매수"
        case .sell:
            return "\(recommendation.shares)주 매도"
        case .hold:
            return "유지"
        }
    }

    private var details: some View {
        VStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text(
                    AppVocabulary.Rebalancing.differenceText(
                        diff: weightDiffText,
                        isOverTarget: recommendation.currentWeight > recommendation.targetWeight
                    )
                )
                .font(.pretendard(12, weight: .bold))
                .foregroundStyle(Color.textPrimary)

                Text(
                    AppVocabulary.Rebalancing.actionProposalText(
                        actionSummary: actionSummaryText,
                        tradeAmount: currencyText(recommendation.tradeAmount)
                    )
                )
                .font(.pretendard(12, weight: .semibold))
                .foregroundStyle(recommendation.action.tintColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                RebalancingDetailMetric(title: AppVocabulary.Rebalancing.currentPrice, value: currencyText(recommendation.currentPrice))
                RebalancingDetailMetric(title: AppVocabulary.Rebalancing.currentValue, value: currencyText(recommendation.currentValue))
                RebalancingDetailMetric(title: AppVocabulary.Rebalancing.drift, value: weightDiffText)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(AppVocabulary.Rebalancing.explanationTitle)
                    .font(.pretendard(11, weight: .semibold))
                    .foregroundStyle(Color.mutedForeground)

                FlowLayout(spacing: 6) {
                    ForEach(reasonRows, id: \.self) { reason in
                        Text(reason)
                            .font(.pretendard(10, weight: .bold))
                            .foregroundStyle(Color.electricBlue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.electricBlue.opacity(0.08), in: Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color.subtle, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var weightDiffText: String {
        percentagePointText(recommendation.targetWeight - recommendation.currentWeight)
    }

    private var reasonRows: [String] {
        recommendation.reasonCodes.map { code in
            AppVocabulary.Rebalancing.reasonText(
                for: code,
                profile: profileName,
                targetWeight: percentText(recommendation.targetWeight),
                diff: weightDiffText,
                limit: percentText(policy.maxSingleAssetWeight),
                cashRatio: percentText(policy.targetCashWeight),
                amount: currencyText(policy.minTradeAmount),
                threshold: percentText(policy.rebalanceThreshold)
            )
        }
    }
}

private struct RebalancingWeightPill: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 5) {
            Text(title)
                .font(.pretendard(10, weight: .medium))
                .foregroundStyle(Color.mutedForeground)

            Text(value)
                .font(.pretendard(12, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.subtle, in: Capsule())
    }
}

private struct RebalancingDetailMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.pretendard(10, weight: .medium))
                .foregroundStyle(Color.mutedForeground)

            Text(value)
                .font(.pretendard(12, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let rows = makeRows(width: width, subviews: subviews)
        return CGSize(
            width: width,
            height: rows.reduce(0) { $0 + $1.height } + CGFloat(max(0, rows.count - 1)) * spacing
        )
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        let rows = makeRows(width: bounds.width, subviews: subviews)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX
            for item in row.items {
                item.subview.place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private func makeRows(width: CGFloat, subviews: Subviews) -> [Row] {
        guard width > 0 else {
            return [
                Row(
                    items: subviews.map { RowItem(subview: $0, size: $0.sizeThatFits(.unspecified)) },
                    height: subviews.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
                )
            ]
        }

        var rows: [Row] = []
        var currentItems: [RowItem] = []
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0

        for subview in subviews {
            let measuredSize = subview.sizeThatFits(
                ProposedViewSize(width: width, height: nil)
            )
            let size = CGSize(
                width: min(measuredSize.width, width),
                height: measuredSize.height
            )
            let nextWidth = currentItems.isEmpty ? size.width : currentWidth + spacing + size.width

            if nextWidth > width, currentItems.isEmpty == false {
                rows.append(Row(items: currentItems, height: currentHeight))
                currentItems = [RowItem(subview: subview, size: size)]
                currentWidth = size.width
                currentHeight = size.height
            } else {
                currentItems.append(RowItem(subview: subview, size: size))
                currentWidth = nextWidth
                currentHeight = max(currentHeight, size.height)
            }
        }

        if currentItems.isEmpty == false {
            rows.append(Row(items: currentItems, height: currentHeight))
        }

        return rows
    }

    private struct Row {
        let items: [RowItem]
        let height: CGFloat
    }

    private struct RowItem {
        let subview: LayoutSubviews.Element
        let size: CGSize
    }
}
