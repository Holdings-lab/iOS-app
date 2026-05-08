import SwiftUI

struct AssetRebalanceSection: View {
    let dashboard: AssetDashboard
    @Binding var semiconductorTarget: Double
    @Binding var bondTarget: Double
    @Binding var energyTarget: Double
    @Binding var cashTarget: Double
    let expectedReturnText: String
    let estimatedFeeAmountText: String
    let exchangeRateText: String
    let isExchangeRateLoading: Bool
    let onRefreshExchangeRate: () -> Void
    let onCreateExecutionPlan: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            noTradeZoneCard
            rebalanceModeList
            constraintGrid
            scenarioChangeCard
            targetWeightSimulator
            executionPlanCTA
        }
    }

    private var noTradeZoneCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.policyAmber)

                Text("노트레이드 존 활성")
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(Color.policyAmber)
            }

            Text("이번 주 주요 정책 이벤트 3건 대기 중. 결과 확인 전 리밸런싱 불필요.")
                .font(.pretendard(13, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("해제 예정: 3/28 PCE 발표 이후")
                .font(.pretendard(12, weight: .medium))
                .foregroundStyle(Color.mutedForeground.opacity(0.6))
        }
        .padding(16)
        .background(Color.policyAmber.opacity(0.08), in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                .stroke(Color.policyAmber.opacity(0.15), lineWidth: 1)
        }
    }

    private var rebalanceModeList: some View {
        VStack(alignment: .leading, spacing: 12) {
            AssetSectionTitle("리밸런싱 모드")

            VStack(spacing: 10) {
                ForEach(dashboard.rebalanceModes) { mode in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(mode.color.opacity(0.12))
                            .frame(width: 40, height: 40)
                            .overlay {
                                Image(systemName: mode.symbol)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(mode.color)
                            }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(mode.title)
                                .font(.pretendard(14, weight: .semibold))
                                .foregroundStyle(Color.textPrimary)
                            Text(mode.description)
                                .font(.pretendard(12, weight: .medium))
                                .foregroundStyle(Color.mutedForeground)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.mutedForeground)
                    }
                    .padding(14)
                    .glassCard()
                }
            }
        }
    }

    private var constraintGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            AssetSectionTitle("제약 조건")

            LazyVGrid(columns: twoColumnGrid, spacing: 10) {
                ForEach(dashboard.constraints) { constraint in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(constraint.title)
                            .font(.pretendard(11, weight: .medium))
                            .foregroundStyle(Color.mutedForeground)
                        Text(constraint.value)
                            .font(.pretendard(17, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                            .monospacedDigit()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .glassCard()
                }
            }
        }
    }

    private var scenarioChangeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            AssetSectionTitle("시나리오별 추천 변화")

            ForEach(dashboard.scenarios) { scenario in
                HStack(spacing: 12) {
                    Text(scenario.title)
                        .font(.pretendard(12, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .frame(width: 34, alignment: .leading)

                    Text(scenario.change)
                        .font(.pretendard(14, weight: .bold))
                        .foregroundStyle(scenario.color)
                        .frame(width: 54, alignment: .trailing)
                        .monospacedDigit()

                    Text(scenario.detail)
                        .font(.pretendard(12, weight: .medium))
                        .foregroundStyle(Color.mutedForeground)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
                .background(Color.subtle, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(16)
        .glassCard()
    }

    private var targetWeightSimulator: some View {
        VStack(alignment: .leading, spacing: 16) {
            AssetSectionTitle("목표 비중 시뮬레이터")

            AssetWeightSlider(title: "반도체", color: .policyPurple, value: $semiconductorTarget)
            AssetWeightSlider(title: "채권", color: .electricBlue, value: $bondTarget)
            AssetWeightSlider(title: "에너지", color: .emerald, value: $energyTarget)
            AssetWeightSlider(title: "현금", color: .mutedForeground, value: $cashTarget)

            simulatorResultBox
        }
        .padding(16)
        .glassCard()
    }

    private var simulatorResultBox: some View {
        VStack(spacing: 10) {
            HStack {
                AssetResultMetric(title: "예상 수익률", value: "+\(expectedReturnText)%")
                AssetResultMetric(title: "예상 수수료", value: estimatedFeeAmountText)
            }

            HStack {
                AssetResultMetric(title: "현금 비중", value: "\(Int(cashTarget.rounded()))%")

                HStack(spacing: 6) {
                    AssetResultMetric(title: "환율", value: exchangeRateText)
                    Button(action: onRefreshExchangeRate) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.electricBlue)
                    }
                    .buttonStyle(.plain)
                    .disabled(isExchangeRateLoading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(Color.electricBlue.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.electricBlue.opacity(0.15), lineWidth: 1)
        }
    }

    private var executionPlanCTA: some View {
        Button(action: onCreateExecutionPlan) {
            HStack(spacing: 10) {
                Text("실행 계획서 생성하기")
                    .font(.pretendard(14, weight: .semibold))
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .assetGradientCTA()
        }
        .buttonStyle(.plain)
    }

    private var twoColumnGrid: [GridItem] {
        [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]
    }
}

private struct AssetWeightSlider: View {
    let title: String
    let color: Color
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.pretendard(13, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("\(Int(value.rounded()))%")
                    .font(.pretendard(13, weight: .bold))
                    .foregroundStyle(color)
                    .monospacedDigit()
            }

            Slider(value: $value, in: 0...50, step: 1)
                .tint(color)
        }
    }
}

private struct AssetResultMetric: View {
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
                .minimumScaleFactor(0.72)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
