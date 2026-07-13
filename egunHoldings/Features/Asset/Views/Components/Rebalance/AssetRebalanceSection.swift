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
