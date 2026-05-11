import SwiftUI

@MainActor
struct AssetView: View {
    @StateObject private var viewModel: AssetViewModel

    init(
        userId: Int64? = nil,
        brokerBalanceSnapshot: BrokerBalanceSnapshot? = nil,
        viewModel: AssetViewModel? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: viewModel ?? AssetViewModel(
                userId: userId,
                brokerBalanceSnapshot: brokerBalanceSnapshot
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            AssetHeaderView()
                .padding(.horizontal, KDXSpacing.screenHorizontal)
                .padding(.top, 14)
                .padding(.bottom, 14)

            AssetSegmentControl(
                selectedSegment: $viewModel.selectedSegment,
                onSelect: viewModel.selectSegment
            )
            .padding(.horizontal, KDXSpacing.screenHorizontal)
            .padding(.bottom, 12)

            Group {
                switch viewModel.selectedSegment {
                case .overview:
                    overviewContent
                case .rebalance:
                    rebalanceContent
                }
            }
        }
        .policyFinanceLightTabChrome()
        .sheet(isPresented: $viewModel.isBrokerConnectionPresented) {
            BrokerConnectionStubView(onDismiss: viewModel.dismissBrokerConnection)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.elevated)
                .presentationCornerRadius(KDXRadius.bottomSheet)
        }
    }

    private var overviewContent: some View {
        PFContentScrollView(spacing: 20, topPadding: 4, scrollsToTopOnAppear: true) {
            AssetExposureOverviewSection(
                dashboard: viewModel.dashboard,
                onBrokerConnectionTap: viewModel.presentBrokerConnection
            )
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
            }
        }
    }
}

#Preview {
    NavigationStack {
        AssetView()
    }
}
