import SwiftUI

@MainActor
struct AssetView: View {
    @StateObject private var viewModel: AssetViewModel
    @ObservedObject private var exchangeRateViewModel: ExchangeRateViewModel
    @Environment(\.dismiss) private var dismiss
    private let onAdjustmentRequested: () -> Void

    init(
        userId: Int64? = nil,
        brokerBalanceSnapshot: BrokerBalanceSnapshot? = nil,
        viewModel: AssetViewModel? = nil,
        exchangeRateViewModel: ExchangeRateViewModel? = nil,
        onAdjustmentRequested: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(
            wrappedValue: viewModel ?? AssetViewModel(
                userId: userId,
                brokerBalanceSnapshot: brokerBalanceSnapshot
            )
        )
        self.exchangeRateViewModel = exchangeRateViewModel ?? ExchangeRateViewModel()
        self.onAdjustmentRequested = onAdjustmentRequested
    }

    var body: some View {
        VStack(spacing: 0) {
            topChrome

            PFContentScrollView(
                alignment: .leading,
                spacing: 20,
                horizontalPadding: PSSpacing.screenHorizontal,
                topPadding: 8,
                bottomPadding: 112,
                scrollsToTopOnAppear: true,
                locksHorizontalOverflow: true
            ) {
                PolSignalAssetSnapshotView(
                    summary: PolSignalFlowMockData.assetSummary,
                    proposal: PolSignalFlowMockData.adjustmentProposal,
                    onProposalTap: onAdjustmentRequested
                )
            }
        }
        .background(PSColor.background.ignoresSafeArea())
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
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("포트폴리오")
                        .font(.pretendard(13, weight: .regular))
                        .foregroundStyle(PSColor.textSecondary)

                    Text("내 자산")
                        .font(.pretendard(28, weight: .bold))
                        .foregroundStyle(PSColor.textPrimary)
                }

                Spacer()
            }
            .frame(height: 72)
            .padding(.horizontal, PSSpacing.screenHorizontal)
        }
    }

    private var overviewContent: some View {
        PFContentScrollView(
            alignment: .leading,
            spacing: 20,
            horizontalPadding: PSSpacing.screenHorizontal,
            topPadding: 8,
            bottomPadding: 16,
            scrollsToTopOnAppear: true,
            locksHorizontalOverflow: true
        ) {
            AssetHeaderView(
                totalAmount: viewModel.dashboard.totalAssetAmount,
                profitSummary: viewModel.dashboard.totalProfitSummary,
                profitColor: viewModel.dashboard.totalProfitColor
            )

            AssetExposureOverviewSection(
                dashboard: viewModel.dashboard,
                weeklyAdjustmentNotice: viewModel.weeklyAdjustmentNotice,
                selectedAccount: nil,
                isOverallPolicyDetailPresented: false,
                onShowOverallPolicyDetail: viewModel.showOverallPolicyDetail,
                onSelectAccount: viewModel.selectAssetAccount,
                onBackToAccounts: viewModel.closeAssetDrilldown,
                onShowRebalancing: { viewModel.selectSegment(.rebalance) },
                onBrokerConnectionTap: viewModel.presentBrokerConnection
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
