import SwiftUI

struct AssetExposureDestinationView: View {
    let destination: AssetNavigationDestination
    let dashboard: AssetDashboard

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.canvas.ignoresSafeArea()

            destinationContent
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private var destinationContent: some View {
        switch destination {
        case .overallPolicy:
            detailScrollView(
                selectedAccount: nil,
                isOverallPolicyDetailPresented: true
            )
        case .account(let accountId):
            if let account = dashboard.accounts.first(where: { $0.id == accountId }) {
                detailScrollView(
                    selectedAccount: account,
                    isOverallPolicyDetailPresented: false
                )
            } else {
                missingAccountView
            }
        }
    }

    private func detailScrollView(
        selectedAccount: AssetAccount?,
        isOverallPolicyDetailPresented: Bool
    ) -> some View {
        PFContentScrollView(
            spacing: 20,
            topPadding: 8,
            bottomPadding: 34,
            scrollsToTopOnAppear: true,
            locksHorizontalOverflow: true
        ) {
            AssetExposureOverviewSection(
                dashboard: dashboard,
                weeklyAdjustmentNotice: nil,
                selectedAccount: selectedAccount,
                isOverallPolicyDetailPresented: isOverallPolicyDetailPresented,
                onShowOverallPolicyDetail: {},
                onSelectAccount: { _ in },
                onBackToAccounts: { dismiss() },
                onShowRebalancing: {},
                onBrokerConnectionTap: {}
            )
        }
    }

    private var missingAccountView: some View {
        VStack(spacing: 0) {
            HStack {
                LiquidGlassBackButton(action: { dismiss() })

                Spacer()

                Text("계좌")
                    .font(.pretendard(17, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                Color.clear
                    .frame(width: 34, height: 34)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)

            Spacer()

            Text("계좌 정보를 찾을 수 없어요.")
                .font(.pretendard(15, weight: .semibold))
                .foregroundStyle(Color.textTertiary)

            Spacer()
        }
    }
}

struct AssetAccountCard: View {
    let account: AssetAccount
    let expandsHoldings: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: account.symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(account.tint)
                    .frame(width: 38, height: 38)
                    .background(account.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(account.brokerName)
                        .font(.pretendard(14, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    Text(account.accountName)
                        .font(.pretendard(11, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(account.totalAmount)
                        .font(.pretendard(20, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text(account.profitSummary)
                        .font(.pretendard(12, weight: .bold))
                        .foregroundStyle(account.profitColor)
                        .monospacedDigit()
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.textSecondary)
            }

            PolicyTagPillRow(tags: account.policyTags)

            if expandsHoldings {
                VStack(spacing: 8) {
                    ForEach(Array(account.holdings.prefix(3))) { holding in
                        CompactHoldingRow(row: holding)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(PSSpacing.cardPadding)
        .contentShape(RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
        .glassCard()
    }
}

private struct CompactHoldingRow: View {
    let row: AssetHoldingRow

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.name)
                    .font(.pretendard(12, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                Text(row.weight)
                    .font(.pretendard(10, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }

            Spacer()

            Text(row.amount)
                .font(.pretendard(12, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .monospacedDigit()
        }
    }
}

struct PolicyTagPillRow: View {
    let tags: [AssetPolicyTag]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(tags.prefix(2))) { tag in
                Text(tag.title)
                    .font(.pretendard(10, weight: .semibold))
                    .foregroundStyle(tag.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(tag.color.opacity(0.14), in: RoundedRectangle(cornerRadius: KDXRadius.chip, style: .continuous))
            }
        }
    }
}

struct ExposureMetricCard: View {
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

struct AssetHoldingMatrixRow: View {
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

            VStack(alignment: .leading, spacing: 6) {
                ForEach(row.tags) { tag in
                    Text(tag.title)
                        .font(.pretendard(10, weight: .semibold))
                        .foregroundStyle(tag.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
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
