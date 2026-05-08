import SwiftUI

@MainActor
struct AssetView: View {
    @ObservedObject var signalViewModel: SignalViewModel
    @StateObject private var viewModel: AssetViewModel

    init(
        signalViewModel: SignalViewModel,
        viewModel: AssetViewModel? = nil
    ) {
        self.signalViewModel = signalViewModel
        _viewModel = StateObject(wrappedValue: viewModel ?? AssetViewModel())
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
        PFContentScrollView(spacing: 20, topPadding: 4, scrollsToTopOnAppear: true) {
            AssetRebalanceSection(
                dashboard: viewModel.dashboard,
                semiconductorTarget: $viewModel.semiconductorTarget,
                bondTarget: $viewModel.bondTarget,
                energyTarget: $viewModel.energyTarget,
                cashTarget: $viewModel.cashTarget,
                expectedReturnText: signalViewModel.expectedReturnText,
                estimatedFeeAmountText: signalViewModel.estimatedFeeAmountText,
                exchangeRateText: signalViewModel.exchangeRateText,
                isExchangeRateLoading: signalViewModel.isExchangeRateLoading,
                onRefreshExchangeRate: signalViewModel.refreshExchangeRate,
                onCreateExecutionPlan: {}
            )
        }
    }
}

#Preview {
    NavigationStack {
        AssetView(signalViewModel: SignalViewModel())
    }
}
