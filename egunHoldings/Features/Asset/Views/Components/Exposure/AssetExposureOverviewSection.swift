import SwiftUI

struct AssetExposureOverviewSection: View {
    let dashboard: AssetDashboard
    let onBrokerConnectionTap: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            exposureInsightCard
            assetPolicyMatrix
            hiddenPolicyBetsCard
            exposureSummaryGrid
            brokerConnectionCTA
        }
    }

    private var exposureInsightCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: leadingExposureMetric?.symbol ?? "scope")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(leadingExposureMetric?.color ?? Color.electricBlue)
                .frame(width: 28, height: 28)
                .background((leadingExposureMetric?.color ?? Color.electricBlue).opacity(0.1), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(exposureInsightText)
                    .font(.pretendard(15, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if leadingExposureMetric != nil {
                    Text("아래 보유 자산의 정책 태그를 합산한 결과입니다.")
                        .font(.pretendard(11, weight: .medium))
                        .foregroundStyle(Color.mutedForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .glassCard()
    }

    private var exposureSummaryGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            AssetSectionTitle(AppVocabulary.Asset.exposureSummary)

            LazyVGrid(columns: twoColumnGrid, spacing: 10) {
                ForEach(dashboard.exposureMetrics) { metric in
                    ExposureMetricCard(metric: metric)
                }
            }
        }
    }

    private var assetPolicyMatrix: some View {
        VStack(alignment: .leading, spacing: 12) {
            AssetSectionTitle(AppVocabulary.Asset.policyMatrix)

            VStack(spacing: 10) {
                ForEach(dashboard.holdingRows) { row in
                    AssetHoldingMatrixRow(row: row)
                }
            }
        }
    }

    private var hiddenPolicyBetsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.policyAmber)

                Text(AppVocabulary.Asset.hiddenPolicyBets)
                    .font(.pretendard(15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
            }

            ForEach(dashboard.hiddenBets) { bet in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        Text(bet.title)
                            .font(.pretendard(13, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                        Text(bet.percent)
                            .font(.pretendard(13, weight: .bold))
                            .foregroundStyle(bet.color)
                            .monospacedDigit()
                    }

                    Text(bet.assets)
                        .font(.pretendard(11, weight: .semibold))
                        .foregroundStyle(Color.mutedForeground)

                    Text(bet.note)
                        .font(.pretendard(11, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(bet.color.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(bet.color.opacity(0.15), lineWidth: 1)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    private var brokerConnectionCTA: some View {
        Button(action: onBrokerConnectionTap) {
            HStack(spacing: 10) {
                Image(systemName: "link")
                    .font(.system(size: 15, weight: .semibold))
                Text("증권사 계좌 연결하기")
                    .font(.pretendard(14, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
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

    private var leadingExposureMetric: AssetExposureMetric? {
        dashboard.exposureMetrics.max { lhs, rhs in
            lhs.percent < rhs.percent
        }
    }

    private var exposureInsightText: String {
        guard let metric = leadingExposureMetric else {
            return "보유 자산의 정책 연결 정도를 확인해 보세요."
        }

        return "\(metric.title) 정책에 가장 많이 연결돼 있어요."
    }
}

private struct ExposureMetricCard: View {
    let metric: AssetExposureMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: metric.symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(metric.color)

                Spacer()

                Image(systemName: metric.trend.symbol)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(metric.trend.color)
            }

            Text(metric.title)
                .font(.pretendard(12, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            Text("\(metric.percent)%")
                .font(.pretendard(22, weight: .bold))
                .foregroundStyle(metric.color)
                .monospacedDigit()

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(metric.color.opacity(0.12))
                    Capsule()
                        .fill(metric.color)
                        .frame(width: proxy.size.width * CGFloat(metric.percent) / 100)
                }
            }
            .frame(height: 6)
        }
        .padding(14)
        .glassCard()
    }
}

private struct AssetHoldingMatrixRow: View {
    let row: AssetHoldingRow

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(row.name)
                        .font(.pretendard(14, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                    Text(row.weight)
                        .font(.pretendard(11, weight: .medium))
                        .foregroundStyle(Color.mutedForeground)
                        .monospacedDigit()
                }

                Spacer()

                Text(row.amount)
                    .font(.pretendard(13, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .monospacedDigit()
            }

            HStack(spacing: 6) {
                ForEach(row.tags) { tag in
                    Text(tag.title)
                        .font(.pretendard(10, weight: .semibold))
                        .foregroundStyle(tag.color)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(tag.color.opacity(0.15), in: RoundedRectangle(cornerRadius: KDXRadius.chip, style: .continuous))
                }
            }
        }
        .padding(14)
        .glassCard()
    }
}
