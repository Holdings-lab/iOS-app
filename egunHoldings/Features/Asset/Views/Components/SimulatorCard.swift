import SwiftUI

struct SimulatorCard: View {
    let simulator: SimulatorContent
    let allocations: [SimulatorETFAllocation]
    let targetWeight: (Int) -> Double
    let onWeightChange: (Int, Double) -> Void
    let onApplyRecommended: () -> Void
    let onResetCurrent: () -> Void
    let expectedReturnText: String
    let netImprovementText: String
    let feeImpactText: String
    let turnoverText: String
    let estimatedTradeAmountText: String
    let estimatedFeeAmountText: String
    let exchangeRateText: String
    let exchangeRateUpdatedText: String
    let isExchangeRateLoading: Bool
    let onRefreshExchangeRate: () -> Void
    let maxSingleWeightCapText: String
    let totalETFWeightText: String
    let cashReserveWeightText: String
    let minimumCashReserveText: String
    let recommendedCashReserveRangeText: String
    let currentCashHoldingAmountText: String
    let currentCashBreakdownText: String
    let targetCashHoldingAmountText: String
    let cashReserveStatusText: String
    let cashReserveColor: Color
    let concentrationScoreText: String
    let concentrationGradeText: String
    let concentrationColor: Color
    let pessimisticScenarioText: String
    let netEffectScoreText: String
    let netEffectGradeText: String
    let netEffectColor: Color
    let beginnerActionHeadline: String
    let beginnerActionBullets: [String]
    let isFeeCautionNeeded: Bool
    let isTargetOverAllocated: Bool
    let riskLevelText: String
    let riskColor: Color
    let holdingSharesText: (Int) -> String
    let unitPriceText: (Int) -> String
    let holdingValueText: (Int) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerSection
            quickActionButtons
            decisionMetricsRow
            reserveGuideCard
            allocationEditor
            netEffectCard
            resultCard
            beginnerActionCard
            feeInfoCard

            if isFeeCautionNeeded {
                feeCautionCard
            }

            disclaimerRow
            ctaButton
        }
        .padding(16)
        .glassCard()
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "briefcase.fill")
                    .foregroundStyle(Color.electricBlue)

                Text(simulator.title)
                    .font(.pretendard(15, weight: .semibold))
                    .foregroundStyle(Color.foreground)
            }

            Text(simulator.subtitle)
                .font(.pretendard(12, weight: .medium))
                .foregroundStyle(Color.mutedForeground)

            HStack(spacing: 8) {
                Image(systemName: "dollarsign.arrow.trianglehead.counterclockwise.rotate.90")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.policyCyan)
                Text(exchangeRateText)
                    .font(.pretendard(11, weight: .semibold))
                    .foregroundStyle(Color.foreground)
                Text(exchangeRateUpdatedText)
                    .font(.pretendard(10, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)
                Spacer()
                Button(action: onRefreshExchangeRate) {
                    Image(systemName: isExchangeRateLoading ? "arrow.triangle.2.circlepath.circle.fill" : "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.electricBlue)
                }
                .buttonStyle(.plain)
                .disabled(isExchangeRateLoading)
            }

            HStack(spacing: 8) {
                Text("리밸런싱 강도")
                    .font(.pretendard(11, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)

                Text(riskLevelText)
                    .font(.pretendard(11, weight: .semibold))
                    .foregroundStyle(riskColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(riskColor.opacity(0.16), in: Capsule())

                Spacer()

                Text(cashReserveStatusText)
                    .font(.pretendard(10, weight: .semibold))
                    .foregroundStyle(cashReserveColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(cashReserveColor.opacity(0.15), in: Capsule())
            }

            HStack(spacing: 6) {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.policyCyan)
                Text("현재 목표 비중: ETF \(totalETFWeightText)% · 현금/달러 \(cashReserveWeightText)%")
                    .font(.pretendard(11, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)
            }

            HStack(spacing: 6) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.policyAmber)
                Text("단일 ETF 최대 \(maxSingleWeightCapText)% · 최소 현금/달러 \(minimumCashReserveText)% 권장")
                    .font(.pretendard(11, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)
            }

            if isTargetOverAllocated {
                Text("ETF 비중 합계가 100%를 초과했어요. 일부 ETF를 낮추면 자동으로 현금/달러 대기 비중이 생깁니다.")
                    .font(.pretendard(10, weight: .semibold))
                    .foregroundStyle(Color.policyCoral)
            }
        }
    }

    private var quickActionButtons: some View {
        HStack(spacing: 8) {
            Button(action: onApplyRecommended) {
                Text("추천 비중 적용")
                    .font(.pretendard(11, weight: .semibold))
                    .foregroundStyle(Color.electricBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .glassEffect(.regular.tint(Color.electricBlue.opacity(0.2)), in: Capsule())
            }
            .buttonStyle(.plain)

            Button(action: onResetCurrent) {
                Text("현재 비중으로 되돌리기")
                    .font(.pretendard(11, weight: .semibold))
                    .foregroundStyle(Color.mutedForeground)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.06), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var decisionMetricsRow: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ETF 분산 점수")
                    .font(.pretendard(10, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)
                HStack(spacing: 6) {
                    Text(concentrationScoreText)
                        .font(.pretendard(14, weight: .bold))
                        .foregroundStyle(Color.foreground)
                    Text(concentrationGradeText)
                        .font(.pretendard(10, weight: .semibold))
                        .foregroundStyle(concentrationColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(concentrationColor.opacity(0.14), in: Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("비관 시나리오")
                    .font(.pretendard(10, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)
                Text("\(pessimisticScenarioText)%")
                    .font(.pretendard(14, weight: .bold))
                    .foregroundStyle(pessimisticScenarioText.hasPrefix("+") ? Color.emeraldLight : Color.policyCoral)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var reserveGuideCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "dollarsign.circle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.policyCyan)
                    .padding(.top, 1)

                Text("남은 비중은 자동으로 현금/달러 대기로 계산됩니다. 권장 대기 비중은 \(recommendedCashReserveRangeText)%입니다.")
                    .font(.pretendard(11, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Text("현금 보유금액")
                    .font(.pretendard(10, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)
                Spacer()
                Text(currentCashHoldingAmountText)
                    .font(.pretendard(11, weight: .semibold))
                    .foregroundStyle(Color.foreground)
            }

            Text(currentCashBreakdownText)
                .font(.pretendard(10, weight: .medium))
                .foregroundStyle(Color.mutedForeground)

            HStack {
                Text("목표 현금/달러(현재 슬라이더 기준)")
                    .font(.pretendard(10, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)
                Spacer()
                Text(targetCashHoldingAmountText)
                    .font(.pretendard(11, weight: .semibold))
                    .foregroundStyle(cashReserveColor)
            }
        }
        .padding(10)
        .background(Color.policyCyan.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.policyCyan.opacity(0.2), lineWidth: 1)
        }
    }

    private var allocationEditor: some View {
        VStack(spacing: 12) {
            ForEach(allocations) { allocation in
                ETFAllocationEditorRow(
                    allocation: allocation,
                    maxWeightCap: Double(maxSingleWeightCapText) ?? 45,
                    sharesText: holdingSharesText(allocation.id),
                    unitPriceText: unitPriceText(allocation.id),
                    holdingValueText: holdingValueText(allocation.id),
                    value: Binding(
                        get: { targetWeight(allocation.id) },
                        set: { onWeightChange(allocation.id, $0) }
                    )
                )
            }
        }
    }

    private var netEffectCard: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text("순효과 점수")
                    .font(.pretendard(11, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)
                Text(netEffectScoreText)
                    .font(.pretendard(20, weight: .bold))
                    .foregroundStyle(Color.foreground)
            }

            Spacer()

            Text(netEffectGradeText)
                .font(.pretendard(12, weight: .semibold))
                .foregroundStyle(netEffectColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .glassEffect(.regular.tint(netEffectColor.opacity(0.2)), in: Capsule())
        }
        .padding(12)
        .background(netEffectColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(netEffectColor.opacity(0.22), lineWidth: 1)
        }
    }

    private var resultCard: some View {
        Text("📊 목표 비중 기준 예상 월 수익률은 \(expectedReturnText)%이고, 수수료 반영 후 순효과는 \(netImprovementText)%p 입니다.")
            .font(.pretendard(13, weight: .medium))
            .foregroundStyle(Color.foreground)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.electricBlue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.electricBlue.opacity(0.2), lineWidth: 1)
            }
    }

    private var beginnerActionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("왜 이 조정이 타당한가요?")
                .font(.pretendard(12, weight: .semibold))
                .foregroundStyle(Color.foreground)

            Text(beginnerActionHeadline)
                .font(.pretendard(13, weight: .semibold))
                .foregroundStyle(Color.emeraldSoft)

            ForEach(beginnerActionBullets, id: \.self) { message in
                HStack(alignment: .top, spacing: 6) {
                    Text("•")
                        .font(.pretendard(12, weight: .bold))
                        .foregroundStyle(Color.mutedForeground)
                        .padding(.top, 1)
                    Text(message)
                        .font(.pretendard(11, weight: .medium))
                        .foregroundStyle(Color.mutedForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .background(Color.emerald.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.emerald.opacity(0.2), lineWidth: 1)
        }
    }

    private var feeInfoCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("예상 매매금액")
                    .font(.pretendard(11, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)
                Spacer()
                Text(estimatedTradeAmountText)
                    .font(.pretendard(12, weight: .semibold))
                    .foregroundStyle(Color.foreground)
            }

            HStack {
                Text("예상 수수료(\(simulator.feeRatePercent, specifier: "%.2f")%)")
                    .font(.pretendard(11, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)
                Spacer()
                Text("\(estimatedFeeAmountText) · -\(feeImpactText)%p")
                    .font(.pretendard(12, weight: .semibold))
                    .foregroundStyle(Color.policyCoral)
            }

            HStack {
                Text("총 조정 비중")
                    .font(.pretendard(11, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)
                Spacer()
                Text("\(turnoverText)%")
                    .font(.pretendard(12, weight: .semibold))
                    .foregroundStyle(riskColor)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var feeCautionCard: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.policyAmber)
                .padding(.top, 1)
            Text("조정 비중이 커서 예상 수수료 부담이 증가하고 있어요. 추천 비중에 가까운 소폭 조정을 우선 고려해보세요.")
                .font(.pretendard(11, weight: .medium))
                .foregroundStyle(Color.mutedForeground)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(Color.policyAmber.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.policyAmber.opacity(0.24), lineWidth: 1)
        }
    }

    private var disclaimerRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .font(.system(size: 12))
            Text(simulator.disclaimer)
                .font(.pretendard(11, weight: .medium))
        }
        .foregroundStyle(Color.mutedForeground)
    }

    private var ctaButton: some View {
        Button(action: {}) {
            HStack(spacing: 8) {
                Text(simulator.ctaTitle)
                Image(systemName: "arrow.up.forward.square")
            }
            .font(.pretendard(14, weight: .medium))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [.electricBlue, .policyPurple],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct ETFAllocationEditorRow: View {
    let allocation: SimulatorETFAllocation
    let maxWeightCap: Double
    let sharesText: String
    let unitPriceText: String
    let holdingValueText: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(allocation.ticker)
                        .font(.pretendard(14, weight: .semibold))
                        .foregroundStyle(Color.foreground)
                    Text(allocation.name)
                        .font(.pretendard(11, weight: .medium))
                        .foregroundStyle(Color.mutedForeground)
                }

                Spacer()

                Text("추천 \(Int(allocation.recommendedWeight))%")
                    .font(.pretendard(10, weight: .semibold))
                    .foregroundStyle(allocation.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .glassEffect(.regular.tint(allocation.color.opacity(0.22)), in: Capsule())

                Text("\(Int(value.rounded()))%")
                    .font(.pretendard(13, weight: .bold))
                    .foregroundStyle(Color.electricBlue)
            }

            Slider(value: $value, in: 0...maxWeightCap, step: 1)
                .tint(allocation.color)

            HStack {
                Text("현재 \(Int(allocation.currentWeight))%")
                    .font(.pretendard(10, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)
                Spacer()
                Text("최대 \(Int(maxWeightCap))%")
                    .font(.pretendard(10, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)
                Spacer()
                Text("예상 \(allocation.expectedMonthlyReturn, specifier: "%.1f")%/월")
                    .font(.pretendard(10, weight: .semibold))
                    .foregroundStyle(Color.emeraldLight)
            }

            HStack {
                Text("보유 \(sharesText)")
                    .font(.pretendard(10, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)
                Spacer()
                Text(unitPriceText)
                    .font(.pretendard(10, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)
            }

            HStack {
                Text("종목 평가금액")
                    .font(.pretendard(10, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)
                Spacer()
                Text(holdingValueText)
                    .font(.pretendard(10, weight: .semibold))
                    .foregroundStyle(Color.foreground)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        }
    }
}
