import SwiftUI

struct AssetRebalanceSection: View {
    let dashboard: RebalancingDashboard
    let loadState: RebalancingLoadState
    let dataStatusText: String
    let dataFootnote: String
    let selectedFilter: RebalancingRecommendationFilter
    let filteredRecommendations: [RebalancingRecommendation]
    let onSelectFilter: (RebalancingRecommendationFilter) -> Void
    let onRefresh: () -> Void

    @State private var refreshRotation: Double = 0

    var body: some View {
        VStack(spacing: 20) {
            summaryHeader
            summaryGrid
            policyGrid
            recommendationFilter
            recommendationList
            notesSection
        }
        .onChange(of: loadState == .loading) { _, isLoading in
            if isLoading {
                refreshRotation = 0
                withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                    refreshRotation = 360
                }
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    refreshRotation = 0
                }
            }
        }
    }

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(AppVocabulary.Rebalancing.weeklyTitle)
                        .font(.pretendard(22, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    Text(dataFootnote)
                        .font(.pretendard(12, weight: .medium))
                        .foregroundStyle(Color.mutedForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.electricBlue)
                        .rotationEffect(.degrees(refreshRotation))
                        .frame(width: 34, height: 34)
                        .background(Color.electricBlue.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(loadState == .loading)
            }

            HStack(spacing: 8) {
                profileBadge
                statusBadge
            }
        }
        .padding(18)
        .glassCard()
    }

    private var profileBadge: some View {
        HStack(spacing: 7) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 13, weight: .semibold))
            Text(dashboard.investmentProfileDisplayName)
                .font(.pretendard(12, weight: .bold))
        }
        .foregroundStyle(Color.brand)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.brand.opacity(0.09), in: Capsule())
    }

    private var statusBadge: some View {
        HStack(spacing: 7) {
            if loadState == .loading {
                ProgressView()
                    .controlSize(.mini)
                    .tint(Color.electricBlue)
            } else {
                Image(systemName: dashboard.dataSource == "REQUEST" ? "checkmark.seal.fill" : "tray.full.fill")
                    .font(.system(size: 12, weight: .semibold))
            }

            Text(dataStatusText)
                .font(.pretendard(12, weight: .bold))
        }
        .foregroundStyle(Color.electricBlue)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.electricBlue.opacity(0.08), in: Capsule())
    }

    private var summaryGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            AssetSectionTitle("요약")

            LazyVGrid(columns: twoColumnGrid, spacing: 10) {
                RebalancingMetricCard(
                    title: "총자산",
                    value: currencyText(dashboard.summary.totalAssetValue),
                    iconName: "chart.pie.fill",
                    color: .brand
                )
                RebalancingMetricCard(
                    title: "현금",
                    value: currencyText(dashboard.summary.cash),
                    iconName: "banknote.fill",
                    color: .electricBlue
                )
                RebalancingMetricCard(
                    title: "현금 비중",
                    value: "\(percentText(dashboard.summary.currentCashWeight)) -> \(percentText(dashboard.summary.targetCashWeight))",
                    iconName: "arrow.left.arrow.right",
                    color: .policyAmber
                )
                RebalancingMetricCard(
                    title: AppVocabulary.Rebalancing.recommendedAdjustment,
                    value: "\(dashboard.summary.tradeCount)건",
                    iconName: "list.bullet.rectangle.fill",
                    color: .emerald
                )
                RebalancingMetricCard(
                    title: "예상 매수",
                    value: currencyText(dashboard.summary.estimatedBuyAmount),
                    iconName: "cart.badge.plus",
                    color: .emerald
                )
                RebalancingMetricCard(
                    title: "예상 매도",
                    value: currencyText(dashboard.summary.estimatedSellAmount),
                    iconName: "arrow.down.circle.fill",
                    color: .policyCoral
                )
            }
        }
    }

    private var policyGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            AssetSectionTitle(AppVocabulary.Rebalancing.appliedCriteria)

            LazyVGrid(columns: twoColumnGrid, spacing: 10) {
                RebalancingCompactMetric(
                    title: AppVocabulary.Rebalancing.targetCashWeight,
                    value: percentText(dashboard.policy.targetCashWeight)
                )
                RebalancingCompactMetric(
                    title: AppVocabulary.Rebalancing.rebalanceThreshold,
                    value: percentText(dashboard.policy.rebalanceThreshold)
                )
                RebalancingCompactMetric(
                    title: AppVocabulary.Rebalancing.maxSingleAssetWeight,
                    value: percentText(dashboard.policy.maxSingleAssetWeight)
                )
                RebalancingCompactMetric(
                    title: AppVocabulary.Rebalancing.minTradeAmount,
                    value: currencyText(dashboard.policy.minTradeAmount)
                )
            }
        }
    }

    private var recommendationFilter: some View {
        VStack(alignment: .leading, spacing: 12) {
            AssetSectionTitle(AppVocabulary.Rebalancing.adjustmentSuggestions)

            HStack(spacing: 8) {
                ForEach(RebalancingRecommendationFilter.allCases) { filter in
                    Button {
                        onSelectFilter(filter)
                    } label: {
                        Text(filter.displayTitle)
                            .font(.pretendard(12, weight: .bold))
                            .foregroundStyle(selectedFilter == filter ? Color.white : Color.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                selectedFilter == filter ? Color.brand : Color.subtle,
                                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var recommendationList: some View {
        VStack(spacing: 12) {
            if filteredRecommendations.isEmpty {
                emptyRecommendationView
            } else {
                ForEach(filteredRecommendations) { recommendation in
                    RebalancingRecommendationCard(
                        recommendation: recommendation,
                        policy: dashboard.policy,
                        profileName: dashboard.investmentProfileDisplayName,
                        currencyText: currencyText,
                        percentText: percentText,
                        percentagePointText: percentagePointText
                    )
                }
            }
        }
    }

    private var emptyRecommendationView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.emerald)

            Text("지금은 조정할 필요가 없어요.")
                .font(.pretendard(16, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            Text("모든 자산이 목표 비중의 허용 범위 안에 있어요.")
                .font(.pretendard(12, weight: .medium))
                .foregroundStyle(Color.mutedForeground)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onRefresh) {
                HStack(spacing: 6) {
                    Text("이번 주 정책 신호 다시 확인")
                        .font(.pretendard(12, weight: .bold))
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(Color.electricBlue)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.electricBlue.opacity(0.09), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .glassCard()
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            AssetSectionTitle("계산 참고")

            ForEach(Array(dashboard.notes.enumerated()), id: \.offset) { _, note in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.electricBlue)
                        .padding(.top, 2)

                    Text(note)
                        .font(.pretendard(12, weight: .medium))
                        .foregroundStyle(Color.mutedForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    private var twoColumnGrid: [GridItem] {
        [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]
    }

    private func currencyText(_ value: Double) -> String {
        Self.currencyFormatter.string(from: NSNumber(value: value)) ?? "0원"
    }

    private func percentText(_ value: Double) -> String {
        let normalized = abs(value) <= 1 ? value * 100 : value
        return String(format: "%.1f%%", normalized)
    }

    private func percentagePointText(_ value: Double) -> String {
        let normalized = abs(value) <= 1 ? value * 100 : value
        return String(format: "%.1f%%p", abs(normalized))
    }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.maximumFractionDigits = 0
        formatter.positiveSuffix = "원"
        formatter.negativeSuffix = "원"
        return formatter
    }()
}

private struct RebalancingMetricCard: View {
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

private struct RebalancingCompactMetric: View {
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

private struct RebalancingRecommendationCard: View {
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
