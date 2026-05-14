import SwiftUI

@MainActor
struct AssetView: View {
    @StateObject private var viewModel: AssetViewModel
    @ObservedObject private var exchangeRateViewModel: ExchangeRateViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTimeframe: AssetPortfolioTimeframe = .oneWeek

    init(
        userId: Int64? = nil,
        brokerBalanceSnapshot: BrokerBalanceSnapshot? = nil,
        viewModel: AssetViewModel? = nil,
        exchangeRateViewModel: ExchangeRateViewModel? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: viewModel ?? AssetViewModel(
                userId: userId,
                brokerBalanceSnapshot: brokerBalanceSnapshot
            )
        )
        self.exchangeRateViewModel = exchangeRateViewModel ?? ExchangeRateViewModel()
    }

    var body: some View {
        VStack(spacing: 0) {
            topChrome

            Group {
                switch viewModel.selectedSegment {
                case .overview:
                    overviewContent
                case .rebalance:
                    rebalanceContent
                }
            }
            .animation(pageTransitionAnimation, value: viewModel.selectedSegment)
        }
        .policyFinanceLightTabChrome()
        .navigationDestination(item: $viewModel.navigationDestination) { destination in
            AssetExposureDestinationView(
                destination: destination,
                dashboard: viewModel.dashboard
            )
        }
        .sheet(isPresented: $viewModel.isBrokerConnectionPresented) {
            BrokerConnectionStubView(onDismiss: viewModel.dismissBrokerConnection)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.elevated)
                .presentationCornerRadius(KDXRadius.bottomSheet)
        }
    }

    private var topChrome: some View {
        HStack {
            LiquidGlassBackButton(action: { dismiss() })

            Spacer()

            Text("내 자산")
                .font(PSFont.title())
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Image(systemName: "bell")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .frame(width: 34, height: 34)
                .background(Color.elevated, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.divider, lineWidth: 1)
                }
        }
        .frame(height: 56)
        .padding(.horizontal, PSSpacing.screenHorizontal)
    }

    private var overviewContent: some View {
        PFContentScrollView(
            alignment: .leading,
            spacing: PSSpacing.sectionGap,
            horizontalPadding: PSSpacing.screenHorizontal,
            topPadding: 8,
            bottomPadding: 16,
            scrollsToTopOnAppear: true,
            locksHorizontalOverflow: true
        ) {
            AssetPortfolioOverviewSection(
                dashboard: viewModel.dashboard,
                selectedTimeframe: $selectedTimeframe
            )
            .task {
                await viewModel.loadRebalancingIfNeeded()
            }
        }
    }

    private var rebalanceContent: some View {
        GeometryReader { proxy in
            PFContentScrollView(spacing: 20, topPadding: 4, scrollsToTopOnAppear: true) {
                AssetRebalanceSection(
                    dashboard: viewModel.rebalancingDashboard,
                    loadState: viewModel.rebalancingLoadState,
                    dataStatusText: viewModel.rebalancingDataStatusText,
                    dataFootnote: viewModel.rebalancingDataFootnote,
                    selectedFilter: viewModel.selectedRecommendationFilter,
                    filteredRecommendations: viewModel.filteredRebalancingRecommendations,
                    onSelectFilter: viewModel.selectRecommendationFilter,
                    onRefresh: {
                        Task {
                            await viewModel.refreshRebalancing()
                        }
                    }
                )
                .frame(
                    width: max(0, proxy.size.width - KDXSpacing.screenHorizontal * 2),
                    alignment: .leading
                )
                .clipped()
                .task {
                    await viewModel.loadRebalancingIfNeeded()
                }

                ExchangeRateSnapshotCard(
                    viewModel: exchangeRateViewModel,
                    title: "달러 노출 확인 기준",
                    caption: "USD/KRW"
                )
                .frame(
                    width: max(0, proxy.size.width - KDXSpacing.screenHorizontal * 2),
                    alignment: .leading
                )
            }
        }
    }

    private var pageTransitionAnimation: Animation {
        .easeInOut(duration: 0.28)
    }
}

#Preview {
    NavigationStack {
        AssetView()
    }
}

private enum AssetPortfolioTimeframe: String, CaseIterable, Identifiable {
    case oneDay = "1D"
    case oneWeek = "1W"
    case oneMonth = "1M"
    case oneYear = "1Y"
    case fiveYears = "5Y"
    case all = "All"

    var id: String { rawValue }
}

private struct AssetPortfolioOverviewSection: View {
    let dashboard: AssetDashboard
    @Binding var selectedTimeframe: AssetPortfolioTimeframe

    var body: some View {
        VStack(alignment: .leading, spacing: PSSpacing.sectionGap) {
            AssetHeaderView(
                totalAmount: dashboard.totalAssetAmount,
                profitSummary: dashboard.totalProfitSummary,
                profitColor: dashboard.totalProfitColor
            )

            timeframePills

            chartPlaceholder

            VStack(alignment: .leading, spacing: PSSpacing.itemGap) {
                Text("List Stocks")
                    .font(PSFont.title())
                    .foregroundStyle(Color.textPrimary)

                VStack(spacing: PSSpacing.itemGap) {
                    ForEach(dashboard.holdingRows) { row in
                        AssetPortfolioHoldingRow(row: row)
                    }
                }
            }
        }
    }

    private var timeframePills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PSSpacing.pillGap) {
                ForEach(AssetPortfolioTimeframe.allCases) { timeframe in
                    Button {
                        selectedTimeframe = timeframe
                    } label: {
                        PSStatusChip(
                            label: timeframe.rawValue,
                            color: Color.brand,
                            isSelected: selectedTimeframe == timeframe
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var chartPlaceholder: some View {
        PSGlassCard {
            VStack(spacing: 10) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.brand)

                Text("Chart coming soon")
                    .font(PSFont.body())
                    .foregroundStyle(Color.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 160)
        }
        .frame(height: 200)
    }
}

private struct AssetPortfolioHoldingRow: View {
    let row: AssetHoldingRow

    var body: some View {
        HStack(spacing: PSSpacing.itemGap) {
            logoView

            VStack(alignment: .leading, spacing: 3) {
                Text(ticker)
                    .font(PSFont.tickerLabel())
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                Text(companyName)
                    .font(.pretendard(13, weight: .regular))
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Sparkline(
                points: sparklinePoints,
                isUp: isTrendUp,
                width: 68,
                height: 32
            )
            .frame(width: 68)

            VStack(alignment: .trailing, spacing: 4) {
                Text(row.amount)
                    .font(PSFont.semibold(16))
                    .foregroundStyle(Color.textPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                TrendBadge(
                    value: trendPercentText,
                    suffix: "",
                    isUp: isTrendUp
                )
            }
            .frame(width: 98, alignment: .trailing)
        }
        .frame(height: 64)
    }

    @ViewBuilder
    private var logoView: some View {
        if let logoURL = row.logoURL, let url = URL(string: logoURL) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                fallbackLogo
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
        } else {
            fallbackLogo
        }
    }

    private var fallbackLogo: some View {
        Text(String(ticker.prefix(1)))
            .font(.pretendard(16, weight: .semibold))
            .foregroundStyle(Color.brand)
            .frame(width: 40, height: 40)
            .background(Color.brand.opacity(0.12), in: Circle())
    }

    private var ticker: String {
        let uppercasedName = row.name.uppercased()

        if uppercasedName.contains("QQQ") { return "QQQ" }
        if uppercasedName.contains("GLD") { return "GLD" }
        if row.name.contains("엔비디아") { return "NVDA" }
        if row.name.contains("마이크로소프트") { return "MSFT" }
        if row.name.contains("TIGER") { return "TIGER" }

        return row.name
            .split(separator: " ")
            .first
            .map(String.init) ?? row.name
    }

    private var companyName: String {
        switch ticker {
        case "QQQ": return "Invesco QQQ Trust"
        case "NVDA": return "NVIDIA Corp."
        case "MSFT": return "Microsoft Corp."
        case "TIGER": return "TIGER 국채3년"
        case "GLD": return "SPDR Gold Shares"
        default: return row.name
        }
    }

    private var sparklinePoints: [Double] {
        if !row.sparklinePoints.isEmpty {
            return row.sparklinePoints
        }

        let base = Double(max(row.id, 1))
        return [base, base + 0.4, base + 0.2, base + 0.8, base + 0.65, base + 1.0]
    }

    private var isTrendUp: Bool {
        guard
            let first = sparklinePoints.first,
            let last = sparklinePoints.last
        else {
            return true
        }

        return last >= first
    }

    private var trendPercentText: String {
        guard
            let first = sparklinePoints.first,
            let last = sparklinePoints.last,
            first != 0
        else {
            return "0.00%"
        }

        let percent = abs((last - first) / first * 100)
        return String(format: "%.2f%%", percent)
    }
}
