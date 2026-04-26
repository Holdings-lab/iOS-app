import SwiftUI

private enum AssetSegment: String, CaseIterable, Identifiable {
    case overview = "정책 노출도"
    case rebalance = "시나리오 리밸런싱"

    var id: String { rawValue }
}

struct AssetView: View {
    @ObservedObject var signalViewModel: SignalViewModel

    @State private var selectedSegment: AssetSegment = .overview
    @State private var showBrokerConnectionSheet = false

    private let exposureDashboard = AssetExposureMockData.dashboard

    var body: some View {
        VStack(spacing: 0) {
            Picker("내 자산", selection: $selectedSegment) {
                ForEach(AssetSegment.allCases) { segment in
                    Text(segment.rawValue).tag(segment)
                }
            }
            .pickerStyle(.segmented)
            .tint(Color.electricBlue)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 10)

            Group {
                switch selectedSegment {
                case .overview:
                    overviewContent
                case .rebalance:
                    rebalanceContent
                }
            }
        }
        .policyFinanceDarkTabChrome()
        .sheet(isPresented: $showBrokerConnectionSheet) {
            BrokerConnectionStubView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(.regularMaterial)
        }
    }

    private var overviewContent: some View {
        PFContentScrollView(spacing: 20) {
            AssetHeaderView(
                title: "정책 노출도 대시보드",
                subtitle: "보유 종목 목록보다 먼저, 지금 포트폴리오가 무엇에 베팅 중인지 보여줘요"
            )

            PolicyExposureSummaryCard(
                summaryItems: exposureDashboard.summaryItems,
                defenseReadiness: exposureDashboard.defenseReadiness
            )

            HoldingExposureMatrixCard(
                rows: exposureDashboard.holdingRows,
                hiddenBets: exposureDashboard.hiddenBets
            )

            brokerConnectionCard
        }
    }

    private var rebalanceContent: some View {
        PFContentScrollView(spacing: 20) {
            AssetHeaderView(
                title: "시나리오 리밸런싱 엔진",
                subtitle: "노트레이드 존과 정책 시나리오를 먼저 보고, 그 다음 슬라이더를 조절하세요"
            )

            RebalanceStrategySection(
                noTradeZone: exposureDashboard.noTradeZone,
                constraints: exposureDashboard.constraints,
                scenarioVariants: exposureDashboard.scenarioVariants,
                executionPlan: exposureDashboard.executionPlan,
                whyCard: exposureDashboard.whyCard
            )

            SimulatorCard(
                simulator: signalViewModel.simulator,
                allocations: signalViewModel.simulatorAllocations,
                targetWeight: signalViewModel.targetWeight(for:),
                onWeightChange: signalViewModel.updateTargetWeight(for:to:),
                onApplyRecommended: signalViewModel.applyRecommendedAllocation,
                onResetCurrent: signalViewModel.resetToCurrentAllocation,
                expectedReturnText: signalViewModel.expectedReturnText,
                netImprovementText: signalViewModel.netImprovementText,
                feeImpactText: signalViewModel.feeImpactText,
                turnoverText: signalViewModel.turnoverText,
                estimatedTradeAmountText: signalViewModel.estimatedTradeAmountText,
                estimatedFeeAmountText: signalViewModel.estimatedFeeAmountText,
                exchangeRateText: signalViewModel.exchangeRateText,
                exchangeRateUpdatedText: signalViewModel.exchangeRateUpdatedText,
                isExchangeRateLoading: signalViewModel.isExchangeRateLoading,
                onRefreshExchangeRate: signalViewModel.refreshExchangeRate,
                maxSingleWeightCapText: signalViewModel.maxSingleWeightCapText,
                totalETFWeightText: signalViewModel.totalETFWeightText,
                cashReserveWeightText: signalViewModel.cashReserveWeightText,
                minimumCashReserveText: signalViewModel.minimumCashReserveText,
                recommendedCashReserveRangeText: signalViewModel.recommendedCashReserveRangeText,
                currentCashHoldingAmountText: signalViewModel.currentCashHoldingAmountText,
                currentCashBreakdownText: signalViewModel.currentCashBreakdownText,
                targetCashHoldingAmountText: signalViewModel.targetCashHoldingAmountText,
                cashReserveStatusText: signalViewModel.cashReserveStatusText,
                cashReserveColor: signalViewModel.cashReserveColor,
                concentrationScoreText: signalViewModel.concentrationScoreText,
                concentrationGradeText: signalViewModel.concentrationGradeText,
                concentrationColor: signalViewModel.concentrationColor,
                pessimisticScenarioText: signalViewModel.pessimisticScenarioText,
                netEffectScoreText: signalViewModel.netEffectScoreText,
                netEffectGradeText: signalViewModel.netEffectGradeText,
                netEffectColor: signalViewModel.netEffectColor,
                beginnerActionHeadline: signalViewModel.beginnerActionHeadline,
                beginnerActionBullets: signalViewModel.beginnerActionBullets,
                isFeeCautionNeeded: signalViewModel.isFeeCautionNeeded,
                isTargetOverAllocated: signalViewModel.isTargetOverAllocated,
                riskLevelText: signalViewModel.riskLevelText,
                riskColor: signalViewModel.riskColor,
                holdingSharesText: signalViewModel.heldSharesText(for:),
                unitPriceText: signalViewModel.unitPriceText(for:),
                holdingValueText: signalViewModel.holdingValueText(for:)
            )
        }
    }

    private var brokerConnectionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("증권사앱 연결")
                .font(.pretendard(15, weight: .semibold))
                .foregroundStyle(Color.foreground)

            Text("실계좌 연결로 정책 노출도와 방어력을 자동으로 다시 계산할 수 있어요")
                .font(.pretendard(12, weight: .medium))
                .foregroundStyle(Color.mutedForeground)

            Button {
                showBrokerConnectionSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "link")
                    Text("증권사앱 연결 관리")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.pretendard(13, weight: .semibold))
                .foregroundStyle(Color.electricBlue)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .glassCard()
    }
}

private struct AssetHeaderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "wallet.pass.fill")
                    .foregroundStyle(Color.electricBlue)
                Text(title)
                    .font(.pretendard(28, weight: .bold))
                    .foregroundStyle(Color.foreground)
            }

            Text(subtitle)
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.mutedForeground)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BrokerConnectionStubView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.deepNavy.opacity(0.96).ignoresSafeArea()

            VStack(spacing: 14) {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Color.electricBlue)

                Text("증권사앱 연결")
                    .font(.pretendard(20, weight: .bold))
                    .foregroundStyle(Color.foreground)

                Text("현재는 목 데이터 단계입니다.\n추후 실제 계좌 연결 API를 이 화면에 붙일 예정이에요.")
                    .font(.pretendard(13, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)
                    .multilineTextAlignment(.center)

                Button("닫기") {
                    dismiss()
                }
                .font(.pretendard(14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color.electricBlue, in: Capsule())
            }
            .padding(24)
        }
    }
}

#Preview {
    NavigationStack {
        AssetView(signalViewModel: SignalViewModel())
    }
}
