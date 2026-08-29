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

private struct AssetLoadingState: View {
    var body: some View {
        VStack(spacing: 14) {
            ProgressView().tint(AssetTabPalette.brand)
            Text("자산을 불러오는 중이에요")
                .font(.pretendard(14, weight: .medium))
                .foregroundStyle(AssetTabPalette.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct AssetEmptyState: View {
    let onConnect: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "chart.pie")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(AssetTabPalette.brand)
                .frame(width: 68, height: 68)
                .background(AssetTabPalette.brandSoft, in: Circle())
            Text("연결한 계좌가 없어요")
                .font(.pretendard(20, weight: .bold))
                .foregroundStyle(AssetTabPalette.textPrimary)
            Text("한국투자증권 모의투자 계좌를 연결하면\n보유 종목과 평가금액을 불러와요.")
                .font(.pretendard(14, weight: .regular))
                .foregroundStyle(AssetTabPalette.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            Button("계좌 연결하기", action: onConnect)
                .font(.pretendard(15, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(AssetTabPalette.brand, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(AssetTabPalette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AssetTabPalette.divider, lineWidth: 1)
        }
        .padding(.horizontal, PSSpacing.screenHorizontal)
        .frame(maxHeight: .infinity)
    }
}

private struct AssetErrorState: View {
    let message: String
    let onRetry: () -> Void
    let onConnect: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "exclamationmark.arrow.triangle.2.circlepath")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(AssetTabPalette.down)
            Text("자산을 불러오지 못했어요")
                .font(.pretendard(20, weight: .bold))
                .foregroundStyle(AssetTabPalette.textPrimary)
            Text(message)
                .font(.pretendard(14, weight: .regular))
                .foregroundStyle(AssetTabPalette.textSecondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 10) {
                Button("다시 시도", action: onRetry)
                    .buttonStyle(AssetSecondaryButtonStyle())
                Button("계좌 연결", action: onConnect)
                    .buttonStyle(AssetPrimaryButtonStyle())
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(AssetTabPalette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, PSSpacing.screenHorizontal)
        .frame(maxHeight: .infinity)
    }
}

private struct AssetConnectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let isConnecting: Bool
    let errorMessage: String?
    let onConnect: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("증권사 선택")
                        .font(.pretendard(13, weight: .semibold))
                        .foregroundStyle(AssetTabPalette.brand)
                    Text("어떤 계좌를 연결할까요?")
                        .font(.pretendard(28, weight: .bold))
                        .foregroundStyle(AssetTabPalette.textPrimary)
                    Text("한국투자증권 모의투자 계좌를 연결하면 보유 종목과 평가금액을 불러옵니다.")
                        .font(.pretendard(15, weight: .regular))
                        .foregroundStyle(AssetTabPalette.textSecondary)
                        .lineSpacing(4)

                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(AssetTabPalette.brand)
                        Text("앱은 증권사 자격증명을 입력받거나 저장하지 않아요.")
                            .font(.pretendard(13, weight: .medium))
                            .foregroundStyle(AssetTabPalette.textSecondary)
                    }
                    .padding(16)
                    .background(AssetTabPalette.brandSoft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("한국투자증권")
                            .font(.pretendard(16, weight: .bold))
                            .foregroundStyle(AssetTabPalette.textPrimary)
                        Text("모의투자 · 읽기 전용")
                            .font(.pretendard(13, weight: .medium))
                            .foregroundStyle(AssetTabPalette.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(AssetTabPalette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AssetTabPalette.brand, lineWidth: 1.5)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.pretendard(13, weight: .medium))
                            .foregroundStyle(AssetTabPalette.down)
                    }

                    Button(action: onConnect) {
                        HStack(spacing: 8) {
                            if isConnecting { ProgressView().tint(.white) }
                            Text(isConnecting ? "연결하는 중..." : "연결하고 자산 불러오기")
                        }
                    }
                    .buttonStyle(AssetPrimaryButtonStyle())
                    .disabled(isConnecting)
                }
                .padding(20)
            }
            .background(AssetTabPalette.screen)
            .navigationTitle("자산 연결")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct AssetPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.pretendard(15, weight: .bold))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AssetTabPalette.brand.opacity(configuration.isPressed ? 0.82 : 1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct AssetSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.pretendard(15, weight: .bold))
            .foregroundStyle(AssetTabPalette.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AssetTabPalette.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AssetTabPalette.divider, lineWidth: 1)
            }
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
    var foregroundStyle: Color = AssetTabPalette.textSecondary

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
                        .foregroundStyle(foregroundStyle.opacity(0.78))

                    Text("\(segment.percent)%")
                        .font(.pretendard(11, weight: .bold))
                        .foregroundStyle(foregroundStyle)
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

// Asset 탭 전용 알리아스. 값 대부분은 PSColor와 완전히 동일한 hex를 별도로 재선언하고
// 있었다 — 여기서는 PSColor를 단일 소스로 참조해 중복 정의를 없애고, PSColor에 없는
// 값(등락색, 종목/현금 세그먼트색)만 이 탭 고유의 hex로 유지한다.
enum AssetTabPalette {
    static let screen = PSColor.background
    static let card = PSColor.surface
    static let subBackground = PSColor.surfaceAlt
    static let textPrimary = PSColor.textPrimary
    static let textSecondary = PSColor.textSecondary
    static let brand = PSColor.primary
    static let brandSoft = PSColor.primarySoft
    static let divider = PSColor.border
    static let up = Color(hex: "16A34A")
    static let down = Color(hex: "DC2626")
    static let neutral = PSColor.textFaint
    static let stockETFSegment = PSColor.primary
    static let stockSegment = Color(hex: "8D96A3")
    static let bondSegment = Color(hex: "5B9BD5")
    static let goldCommoditySegment = Color(hex: "C89B3C")
    static let reitSegment = Color(hex: "8D70C9")
    static let otherSegment = Color(hex: "64748B")
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
