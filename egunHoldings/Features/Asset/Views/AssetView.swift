import SwiftUI

@MainActor
struct AssetView: View {
    @StateObject private var viewModel: AssetViewModel

    init(
        userId: Int64? = nil,
        brokerBalanceSnapshot: BrokerBalanceSnapshot? = nil,
        viewModel: AssetViewModel? = nil,
        exchangeRateViewModel: ExchangeRateViewModel? = nil,
        onAdjustmentRequested: @escaping () -> Void = {}
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
            topChrome

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
        }
        .background(AssetTabPalette.screen.ignoresSafeArea())
        .navigationDestination(item: $viewModel.navigationDestination) { destination in
            AssetExposureDestinationView(
                destination: destination,
                dashboard: viewModel.dashboard
            )
        }
        .sheet(isPresented: $viewModel.isBrokerConnectionPresented) {
            BrokerConnectionStubView(onDismiss: viewModel.dismissBrokerConnection)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.elevated)
                .presentationCornerRadius(KDXRadius.bottomSheet)
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
            }
            .frame(height: 72)
            .padding(.horizontal, PSSpacing.screenHorizontal)
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("총 평가금액")
                .font(.pretendard(13, weight: .regular))
                .foregroundStyle(AssetTabPalette.textSecondary)
                .padding(.bottom, 8)

            Text(viewModel.portfolioDisplay.totalEvaluationText)
                .font(.pretendard(34, weight: .bold))
                .foregroundStyle(AssetTabPalette.textPrimary)
                .monospacedDigit()
                .minimumScaleFactor(0.72)
                .lineLimit(1)

            Text(viewModel.portfolioDisplay.heroProfitText)
                .font(.pretendard(13, weight: .semibold))
                .foregroundStyle(viewModel.portfolioDisplay.heroProfitTone.color)
                .padding(.top, 7)

            AssetCompositionBar(segments: viewModel.portfolioDisplay.compositionSegments)
                .padding(.top, 20)

            AssetCompositionLegend(segments: viewModel.portfolioDisplay.compositionSegments)
                .padding(.top, 13)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 18)
        .background(
            AssetTabPalette.card,
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .assetHeroShadow()
    }

    private var holdingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("보유 종목")
                .font(.pretendard(17, weight: .bold))
                .foregroundStyle(AssetTabPalette.textPrimary)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.portfolioDisplay.holdings.enumerated()), id: \.element.id) { index, holding in
                    AssetHoldingDisplayRow(holding: holding)

                    if index < viewModel.portfolioDisplay.holdings.count - 1 {
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
        VStack(spacing: 0) {
            AssetSummaryRow(
                title: "총 수익",
                value: viewModel.portfolioDisplay.totalProfitText,
                valueColor: viewModel.portfolioDisplay.heroProfitTone.color,
                isEmphasized: true
            )
            AssetDivider()
            AssetSummaryRow(
                title: "총 수익률",
                value: viewModel.portfolioDisplay.totalProfitRateText,
                valueColor: viewModel.portfolioDisplay.heroProfitTone.color,
                isEmphasized: true
            )
            AssetDivider()
            AssetSummaryRow(
                title: "투자 원금",
                value: viewModel.portfolioDisplay.principalText,
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
}

private struct AssetCompositionBar: View {
    let segments: [AssetCompositionSegment]

    private let segmentSpacing: CGFloat = 2

    var body: some View {
        GeometryReader { proxy in
            let totalSpacing = CGFloat(max(segments.count - 1, 0)) * segmentSpacing
            let availableWidth = max(0, proxy.size.width - totalSpacing)
            let totalPercent = max(1, segments.reduce(0) { $0 + $1.percent })

            HStack(spacing: segmentSpacing) {
                ForEach(segments) { segment in
                    Capsule(style: .continuous)
                        .fill(segment.color)
                        .frame(
                            width: availableWidth * CGFloat(segment.percent) / CGFloat(totalPercent),
                            height: 6
                        )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 6)
        .clipShape(Capsule(style: .continuous))
    }
}

private struct AssetCompositionLegend: View {
    let segments: [AssetCompositionSegment]

    private let columns = [
        GridItem(.flexible(), spacing: 0),
        GridItem(.flexible(), spacing: 0)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 7) {
            ForEach(segments) { segment in
                HStack(spacing: 6) {
                    Circle()
                        .fill(segment.color)
                        .frame(width: 7, height: 7)

                    Text(segment.title)
                        .font(.pretendard(11, weight: .medium))
                        .foregroundStyle(AssetTabPalette.textSecondary)

                    Text("\(segment.percent)%")
                        .font(.pretendard(11, weight: .bold))
                        .foregroundStyle(AssetTabPalette.textPrimary)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct AssetHoldingDisplayRow: View {
    let holding: AssetPortfolioHoldingRow

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                if holding.isCash {
                    Text("💵")
                        .font(.system(size: 14))
                        .frame(width: 28, height: 28)
                        .background(
                            AssetTabPalette.subBackground,
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(AssetTabPalette.divider, lineWidth: 1)
                        }
                } else if let symbol = holding.symbol {
                    Text(symbol.uppercased())
                        .font(.pretendard(11, weight: .bold))
                        .foregroundStyle(AssetTabPalette.brand)
                        .tracking(0.44)
                        .padding(.horizontal, 9)
                        .frame(height: 22)
                        .background(
                            AssetTabPalette.brandSoft,
                            in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color(hex: "DBEAFE"), lineWidth: 1)
                        }
                }

                Text(holding.title)
                    .font(.pretendard(15, weight: .semibold))
                    .foregroundStyle(AssetTabPalette.textPrimary)
                    .lineLimit(1)

                Text(holding.subtitle)
                    .font(.pretendard(13, weight: .regular))
                    .foregroundStyle(AssetTabPalette.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 3) {
                Text(holding.amountText)
                    .font(.pretendard(15, weight: .semibold))
                    .foregroundStyle(AssetTabPalette.textPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(holding.profitText)
                    .font(.pretendard(13, weight: .semibold))
                    .foregroundStyle(holding.profitTone.color)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .frame(minWidth: 132, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

private struct AssetSummaryRow: View {
    let title: String
    let value: String
    let valueColor: Color
    var isEmphasized = false

    var body: some View {
        HStack {
            Text(title)
                .font(.pretendard(13, weight: .regular))
                .foregroundStyle(AssetTabPalette.textSecondary)

            Spacer()

            Text(value)
                .font(.pretendard(isEmphasized ? 17 : 15, weight: isEmphasized ? .bold : .semibold))
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

private struct AssetDivider: View {
    var body: some View {
        Divider()
            .background(AssetTabPalette.divider)
    }
}

enum AssetTabPalette {
    static let screen = Color(hex: "F0F4FF")
    static let card = Color.white
    static let subBackground = Color(hex: "F8FAFF")
    static let textPrimary = Color(hex: "0F172A")
    static let textSecondary = Color(hex: "64748B")
    static let brand = Color(hex: "2563EB")
    static let brandSoft = Color(hex: "EFF6FF")
    static let divider = Color(hex: "E2E8F0")
    static let up = Color(hex: "16A34A")
    static let down = Color(hex: "DC2626")
    static let neutral = Color(hex: "94A3B8")
    static let etfSegment = Color(hex: "2563EB")
    static let stockSegment = Color(hex: "8D96A3")
    static let cashSegment = Color(hex: "C5CAD3")
}

private extension View {
    func assetCardShadow() -> some View {
        shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 1)
    }

    func assetHeroShadow() -> some View {
        shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 1)
            .shadow(color: AssetTabPalette.brand.opacity(0.07), radius: 20, x: 0, y: 6)
    }
}

#Preview {
    NavigationStack {
        AssetView()
    }
}
