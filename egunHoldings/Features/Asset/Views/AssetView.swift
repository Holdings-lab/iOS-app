import SwiftUI

@MainActor
struct AssetView: View {
    @StateObject private var viewModel: AssetViewModel
    @State private var isConnectionPresented = false
    private let brokerBalanceSnapshot: BrokerBalanceSnapshot?
    private let onBrokerBalanceUpdated: (BrokerBalanceSnapshot) -> Void

    init(
        brokerBalanceSnapshot: BrokerBalanceSnapshot? = nil,
        viewModel: AssetViewModel? = nil,
        onBrokerBalanceUpdated: @escaping (BrokerBalanceSnapshot) -> Void = { _ in }
    ) {
        self.brokerBalanceSnapshot = brokerBalanceSnapshot
        self.onBrokerBalanceUpdated = onBrokerBalanceUpdated
        _viewModel = StateObject(
            wrappedValue: viewModel ?? AssetViewModel(
                brokerBalanceSnapshot: brokerBalanceSnapshot
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            topChrome
            content
        }
        .background(AssetTabPalette.screen.ignoresSafeArea())
        .onChange(of: brokerBalanceSnapshot) { _, newSnapshot in
            viewModel.updateBrokerBalance(newSnapshot)
        }
        .task {
            if let snapshot = await viewModel.loadIfNeeded() {
                onBrokerBalanceUpdated(snapshot)
            }
        }
        .sheet(isPresented: $isConnectionPresented) {
            AssetConnectionSheet(
                isConnecting: viewModel.isConnecting,
                errorMessage: connectionErrorMessage,
                onConnect: connectKISDemoAccount
            )
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            AssetLoadingState()
        case .loaded:
            portfolioContent
        case .empty:
            AssetEmptyState(onConnect: { isConnectionPresented = true })
        case .failed(let message):
            AssetErrorState(
                message: message,
                onRetry: reloadPortfolio,
                onConnect: { isConnectionPresented = true }
            )
        }
    }

    private var portfolioContent: some View {
        PFContentScrollView(
            alignment: .leading,
            spacing: 20,
            horizontalPadding: PSSpacing.screenHorizontal,
            topPadding: 8,
            bottomPadding: 112,
            scrollsToTopOnAppear: true,
            locksHorizontalOverflow: true
        ) {
            heroCard
            holdingsSection
            profitSummaryCard
        }
        .refreshable {
            if let snapshot = await viewModel.reload() {
                onBrokerBalanceUpdated(snapshot)
            }
        }
    }

    private var topChrome: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("포트폴리오")
                        .font(.pretendard(13, weight: .regular))
                        .foregroundStyle(AssetTabPalette.textSecondary)

                    Text("내 자산")
                        .font(.pretendard(28, weight: .bold))
                        .foregroundStyle(AssetTabPalette.textPrimary)
                }

                Spacer()

                Button {
                    isConnectionPresented = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AssetTabPalette.textSecondary)
                        .frame(width: 38, height: 38)
                        .background(AssetTabPalette.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AssetTabPalette.divider, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }
            .frame(height: 72)
            .padding(.horizontal, PSSpacing.screenHorizontal)
        }
    }

    private var heroCard: some View {
        Group {
            if let display = viewModel.portfolioDisplay {
                VStack(alignment: .leading, spacing: 0) {
                    Text("원화 환산 총 평가금액")
                        .font(.pretendard(13, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.72))
                        .padding(.bottom, 8)

                    Text(display.totalEvaluationText)
                        .font(.pretendard(34, weight: .bold))
                        .foregroundStyle(Color.white)
                        .monospacedDigit()
                        .minimumScaleFactor(0.72)
                        .lineLimit(1)

                    Text(display.heroProfitText)
                        .font(.pretendard(13, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.9))
                        .padding(.top, 7)

                    AssetCompositionBar(segments: display.compositionSegments)
                        .padding(.top, 20)

                    AssetCompositionLegend(segments: display.compositionSegments, foregroundStyle: .white)
                        .padding(.top, 13)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 18)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "254EDB"), Color(hex: "527CFF")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .assetHeroShadow()
            }
        }
    }

    private var holdingsSection: some View {
        let holdings = viewModel.portfolioDisplay?.holdings ?? []

        return VStack(alignment: .leading, spacing: 12) {
            Text("보유 종목")
                .font(.pretendard(17, weight: .bold))
                .foregroundStyle(AssetTabPalette.textPrimary)

            VStack(spacing: 0) {
                ForEach(holdings) { holding in
                    AssetHoldingDisplayRow(holding: holding)

                    if holding.id != holdings.last?.id {
                        Divider()
                            .background(AssetTabPalette.divider)
                    }
                }
            }
            .background(
                AssetTabPalette.card,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .assetCardShadow()
        }
    }

    private var profitSummaryCard: some View {
        let display = viewModel.portfolioDisplay
        return VStack(spacing: 0) {
            AssetSummaryRow(
                title: "총 수익",
                value: display?.totalProfitText ?? "₩0",
                valueColor: display?.heroProfitTone.color ?? AssetTabPalette.neutral,
                isEmphasized: true
            )
            AssetDivider()
            AssetSummaryRow(
                title: "총 수익률",
                value: display?.totalProfitRateText ?? "0.0%",
                valueColor: display?.heroProfitTone.color ?? AssetTabPalette.neutral,
                isEmphasized: true
            )
            AssetDivider()
            AssetSummaryRow(
                title: "투자 원금",
                value: display?.principalText ?? "₩0",
                valueColor: AssetTabPalette.textPrimary
            )
        }
        .background(
            AssetTabPalette.card,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .assetCardShadow()
    }

    private var connectionErrorMessage: String? {
        if case .failed(let message) = viewModel.loadState {
            return message
        }
        return nil
    }

    private func reloadPortfolio() {
        Task {
            if let snapshot = await viewModel.reload() {
                onBrokerBalanceUpdated(snapshot)
            }
        }
    }

    private func connectKISDemoAccount() {
        Task {
            if let snapshot = await viewModel.connectKISDemoAccount() {
                onBrokerBalanceUpdated(snapshot)
                isConnectionPresented = false
            }
        }
    }
}


#Preview {
    NavigationStack {
        AssetView()
    }
}
