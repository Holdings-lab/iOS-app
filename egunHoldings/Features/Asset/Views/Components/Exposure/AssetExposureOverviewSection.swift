import SwiftUI

struct AssetExposureOverviewSection: View {
    let dashboard: AssetDashboard
    let weeklyAdjustmentNotice: AssetAdjustmentNotice?
    let selectedAccount: AssetAccount?
    let isOverallPolicyDetailPresented: Bool
    let onShowOverallPolicyDetail: () -> Void
    let onSelectAccount: (AssetAccount) -> Void
    let onBackToAccounts: () -> Void
    let onShowRebalancing: () -> Void
    let onBrokerConnectionTap: () -> Void

    var body: some View {
        if let selectedAccount {
            accountDetailView(selectedAccount)
        } else if isOverallPolicyDetailPresented {
            overallPolicyDetailView
        } else {
            accountOverviewView
        }
    }

    private var accountOverviewView: some View {
        VStack(spacing: PSSpacing.sectionGap) {
            portfolioInsightCard

            if let notice = weeklyAdjustmentNotice {
                adjustmentNoticeCard(notice)
            }

            accountListSection

            hiddenPolicyBetsCard(
                bets: dashboard.hiddenBets,
                title: AppVocabulary.Asset.hiddenPolicyBets
            )

            brokerConnectionCTA
        }
    }

    private var overallPolicyDetailView: some View {
        VStack(spacing: 20) {
            detailNavigationHeader(title: "전체 정책 노출")

            exposureInsightCard(
                metric: leadingExposureMetric(in: dashboard.exposureMetrics),
                subtitle: "전체 계좌의 보유 자산 태그를 합산한 결과입니다."
            )

            assetPolicyMatrix(
                rows: dashboard.holdingRows,
                title: AppVocabulary.Asset.policyMatrix
            )

            hiddenPolicyBetsCard(
                bets: dashboard.hiddenBets,
                title: AppVocabulary.Asset.hiddenPolicyBets
            )

            exposureSummaryGrid(
                metrics: dashboard.exposureMetrics,
                title: AppVocabulary.Asset.exposureSummary
            )
        }
    }

    private func accountDetailView(_ account: AssetAccount) -> some View {
        VStack(spacing: 20) {
            detailNavigationHeader(title: account.accountName)
            accountHeroCard(account)

            assetPolicyMatrix(
                rows: account.holdings,
                title: "보유 종목"
            )

            exposureSummaryGrid(
                metrics: account.exposureMetrics,
                title: AppVocabulary.Asset.exposureSummary
            )

            hiddenPolicyBetsCard(
                bets: account.hiddenBets,
                title: AppVocabulary.Asset.hiddenPolicyBets
            )
        }
    }

    private var portfolioInsightCard: some View {
        Button(action: onShowOverallPolicyDetail) {
            let metric = leadingExposureMetric(in: dashboard.exposureMetrics)
            let accentColor = metric?.color ?? Color.brand

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    Text("정책 노출 현황")
                        .font(PSFont.caption())
                        .foregroundStyle(Color.textSecondary)

                    Spacer(minLength: 0)

                    HStack(spacing: 4) {
                        Text("자산별로 보기")
                            .font(.pretendard(12, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(accentColor.opacity(0.09), in: Capsule())
                }

                HStack(alignment: .center, spacing: 14) {
                    Image(systemName: metric?.symbol ?? "scope")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(accentColor)
                        .frame(width: 48, height: 48)
                        .background(accentColor.opacity(0.1), in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(metric?.title ?? "정책")
                            .font(PSFont.caption())
                            .foregroundStyle(Color.textSecondary)

                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(metric?.percent ?? 0)%")
                                .font(.pretendard(28, weight: .bold))
                                .foregroundStyle(accentColor)
                                .monospacedDigit()

                            Image(systemName: metric?.trend.symbol ?? "arrow.up.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(metric?.trend.color ?? Color.trendUp)
                        }

                        Text("전체 계좌 기준 합산")
                            .font(.pretendard(11, weight: .medium))
                            .foregroundStyle(Color.textTertiary)
                    }

                    Spacer(minLength: 0)
                }
            }
            .padding(PSSpacing.cardPadding)
            .glassCard()
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    private func adjustmentNoticeCard(_ notice: AssetAdjustmentNotice) -> some View {
        Button(action: onShowRebalancing) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(notice.color)
                    .frame(width: 34, height: 34)
                    .background(notice.color.opacity(0.1), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(notice.title)
                        .font(.pretendard(14, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    Text(notice.summary)
                        .font(.pretendard(11, weight: .medium))
                        .foregroundStyle(Color.mutedForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Text("\(notice.count)건")
                    .font(.pretendard(11, weight: .bold))
                    .foregroundStyle(notice.color)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(notice.color.opacity(0.12), in: Capsule())
            }
            .padding(PSSpacing.cardPadding)
            .glassCard()
        }
        .buttonStyle(.plain)
    }

    private var accountListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                AssetSectionTitle("계좌")

                Spacer()

                Text("\(dashboard.accounts.count)개")
                    .font(.pretendard(12, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
            }

            VStack(spacing: 10) {
                ForEach(dashboard.accounts) { account in
                    Button {
                        onSelectAccount(account)
                    } label: {
                        AssetAccountCard(
                            account: account,
                            expandsHoldings: dashboard.accounts.count == 1
                        )
                    }
                    .buttonStyle(PressScaleButtonStyle())
                }
            }
        }
    }

    private func detailNavigationHeader(title: String) -> some View {
        HStack {
            LiquidGlassBackButton(action: onBackToAccounts)

            Spacer()

            Text(title)
                .font(.pretendard(17, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Color.clear
                .frame(width: 34, height: 34)
        }
    }

    private func accountHeroCard(_ account: AssetAccount) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: account.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(account.tint)
                    .frame(width: 42, height: 42)
                    .background(account.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(account.brokerName)
                        .font(.pretendard(14, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    Text("\(account.accountName) · \(account.accountNumber)")
                        .font(.pretendard(11, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(account.totalAmount)
                    .font(.pretendard(28, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                HStack(spacing: 8) {
                    Text(account.profitSummary)
                        .font(.pretendard(13, weight: .bold))
                        .foregroundStyle(account.profitColor)
                        .monospacedDigit()

                    Text("현금 \(account.cashAmount)")
                        .font(.pretendard(12, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                        .monospacedDigit()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("이 계좌의 정책 태그")
                    .font(.pretendard(11, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)

                PolicyTagPillRow(tags: account.policyTags)
            }
        }
        .padding(18)
        .glassCard()
    }

    private func exposureInsightCard(metric: AssetExposureMetric?, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: metric?.symbol ?? "scope")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(metric?.color ?? Color.electricBlue)
                .frame(width: 28, height: 28)
                .background((metric?.color ?? Color.electricBlue).opacity(0.1), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(exposureInsightText(for: metric))
                    .font(.pretendard(15, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(.pretendard(11, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(PSSpacing.cardPadding)
        .glassCard()
    }

    private func exposureSummaryGrid(metrics: [AssetExposureMetric], title: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                AssetSectionTitle(title)

                Text("화살표는 지난주 대비 노출 변화입니다.")
                    .font(.pretendard(11, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }

            LazyVGrid(columns: twoColumnGrid, spacing: 10) {
                ForEach(metrics) { metric in
                    ExposureMetricCard(metric: metric)
                }
            }
        }
    }

    private func assetPolicyMatrix(rows: [AssetHoldingRow], title: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            AssetSectionTitle(title)

            VStack(spacing: 10) {
                ForEach(rows) { row in
                    AssetHoldingMatrixRow(row: row)
                }
            }
        }
    }

    private func hiddenPolicyBetsCard(bets: [HiddenAssetBet], title: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.policyAmber)

                Text(title)
                    .font(.pretendard(15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
            }

            ForEach(bets) { bet in
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
        .padding(PSSpacing.cardPadding)
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

    private func leadingExposureMetric(in metrics: [AssetExposureMetric]) -> AssetExposureMetric? {
        metrics.max { lhs, rhs in
            lhs.percent < rhs.percent
        }
    }

    private func exposureInsightText(for metric: AssetExposureMetric?) -> String {
        guard let metric else {
            return "보유 자산의 정책 연결 정도를 확인해 보세요."
        }

        return "\(metric.title) 정책에 가장 많이 묶여있어요."
    }

}
