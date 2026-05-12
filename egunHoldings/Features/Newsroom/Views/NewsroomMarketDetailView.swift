import SwiftUI

struct NewsroomMarketDetailView: View {
    let selectedTicker: NewsroomMarketTicker
    let quotes: [NewsroomMarketQuote]

    @Environment(\.dismiss) private var dismiss
    @State private var selectedGroup: NewsroomMarketQuoteGroup = .indexCurrency
    @State private var selectedRegion: NewsroomMarketQuoteRegion = .all

    private var filteredQuotes: [NewsroomMarketQuote] {
        quotes.filter { quote in
            quote.group == selectedGroup
                && (selectedRegion == .all || quote.region == selectedRegion)
        }
    }

    var body: some View {
        ZStack {
            Color.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        groupTabs
                        regionTabs
                        quoteList
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            selectedGroup = quotes.first { $0.id == selectedTicker.id }?.group ?? .indexCurrency
        }
    }

    private var topBar: some View {
        HStack {
            LiquidGlassBackButton(action: { dismiss() })

            Spacer()

            Text("주요 지수")
                .font(.pretendard(20, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Color.clear
                .frame(width: 34, height: 34)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.canvas.opacity(0.96))
    }

    private var groupTabs: some View {
        HStack(spacing: 22) {
            ForEach(NewsroomMarketQuoteGroup.allCases) { group in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedGroup = group
                        selectedRegion = .all
                    }
                } label: {
                    VStack(spacing: 11) {
                        Text(group.title)
                            .font(.pretendard(17, weight: .bold))
                            .foregroundStyle(selectedGroup == group ? Color.textPrimary : Color.textTertiary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.76)

                        Capsule(style: .continuous)
                            .fill(selectedGroup == group ? Color.textPrimary : Color.clear)
                            .frame(height: 3)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var regionTabs: some View {
        HStack(spacing: 9) {
            ForEach(NewsroomMarketQuoteRegion.allCases) { region in
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        selectedRegion = region
                    }
                } label: {
                    Text(region.title)
                        .font(.pretendard(14, weight: .bold))
                        .foregroundStyle(selectedRegion == region ? Color.textPrimary : Color.textTertiary)
                        .padding(.horizontal, 18)
                        .frame(height: 46)
                        .background(
                            selectedRegion == region ? Color.elevated : Color.clear,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(selectedRegion == region ? Color.hairline : Color.clear, lineWidth: 1)
                        }
                }
                .buttonStyle(PressScaleButtonStyle())
            }
        }
    }

    private var quoteList: some View {
        VStack(spacing: 24) {
            ForEach(filteredQuotes) { quote in
                MarketQuoteRow(quote: quote)
            }
        }
    }
}

private struct MarketQuoteRow: View {
    let quote: NewsroomMarketQuote

    private var tint: Color {
        quote.isPositive ? Color.policyCoral : Color.electricBlue
    }

    var body: some View {
        HStack(spacing: 18) {
            MarketQuoteSparklineView(values: quote.sparkline, color: tint)
                .frame(width: 82, height: 58)

            VStack(alignment: .leading, spacing: 6) {
                Text(quote.name)
                    .font(.pretendard(19, weight: .bold))
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(quote.valueText)
                    .font(.pretendard(25, weight: .bold))
                    .foregroundStyle(tint)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                Text(quote.changeText)
                    .font(.pretendard(13, weight: .bold))
                    .foregroundStyle(tint)
                    .monospacedDigit()
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "heart.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color.textTertiary.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MarketQuoteSparklineView: View {
    let values: [CGFloat]
    let color: Color

    var body: some View {
        Canvas { context, size in
            guard values.count > 1 else { return }

            let clamped = values.map { min(1, max(0, $0)) }
            let stepX = size.width / CGFloat(max(clamped.count - 1, 1))
            var path = Path()

            for index in clamped.indices {
                let point = CGPoint(
                    x: CGFloat(index) * stepX,
                    y: size.height * (1 - clamped[index])
                )

                if index == clamped.startIndex {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }

            var fillPath = path
            fillPath.addLine(to: CGPoint(x: size.width, y: size.height))
            fillPath.addLine(to: CGPoint(x: 0, y: size.height))
            fillPath.closeSubpath()

            context.fill(fillPath, with: .color(color.opacity(0.12)))
            context.stroke(path, with: .color(color), lineWidth: 2.5)
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    NavigationStack {
        NewsroomMarketDetailView(
            selectedTicker: NewsroomMarketData.tickers[0],
            quotes: NewsroomMarketData.quotes
        )
    }
}
