import SwiftUI
import Combine

struct NewsroomHeaderView: View {
    let latestUpdateText: String
    let selectedCategoryCount: Int
    let tickers: [NewsroomMarketTicker]
    let feedMode: NewsroomFeedMode

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "newspaper.fill")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(Color.electricBlue)
                        .frame(width: 30, height: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .lastTextBaseline, spacing: 9) {
                            Text("피드")
                                .font(.pretendard(28, weight: .bold))
                                .foregroundStyle(Color.textPrimary)
                                .tracking(-0.5)

                            NewsroomRollingTickerView(tickers: tickers)
                        }

                        Text(feedMode.subtitle)
                            .font(.pretendard(13, weight: .medium))
                            .foregroundStyle(Color.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(latestUpdateText) 업데이트")
                        .font(.pretendard(11, weight: .semibold))
                        .foregroundStyle(Color.brand)
                    Text("관심 산업 \(selectedCategoryCount)개")
                        .font(.pretendard(11, weight: .medium))
                        .foregroundStyle(Color.textQuaternary)
                }
            }
        }
    }
}

private struct NewsroomRollingTickerView: View {
    let tickers: [NewsroomMarketTicker]
    @State private var activeIndex = 0

    private var activeTicker: NewsroomMarketTicker? {
        guard !tickers.isEmpty else { return nil }
        return tickers[activeIndex % tickers.count]
    }

    var body: some View {
        Group {
            if let activeTicker {
                HStack(spacing: 5) {
                    Text(activeTicker.title)
                        .font(.pretendard(12, weight: .bold))
                        .foregroundStyle(Color.textTertiary)
                        .lineLimit(1)

                    Text(activeTicker.price)
                        .font(.pretendard(13, weight: .bold))
                        .foregroundStyle(Color.brand)
                        .monospacedDigit()
                        .lineLimit(1)

                    Text(activeTicker.changeText)
                        .font(.pretendard(12, weight: .bold))
                        .foregroundStyle(activeTicker.isPositive ? Color.emerald : Color.policyCoral)
                        .monospacedDigit()
                        .lineLimit(1)
                }
                .id(activeTicker.id)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .frame(height: 24, alignment: .leading)
                .clipped()
            }
        }
        .animation(.easeInOut(duration: 0.34), value: activeIndex)
        .onReceive(Timer.publish(every: 2.8, on: .main, in: .common).autoconnect()) { _ in
            guard tickers.count > 1 else { return }
            activeIndex = (activeIndex + 1) % tickers.count
        }
        .onChange(of: tickers) { _, newValue in
            if newValue.isEmpty {
                activeIndex = 0
            } else if activeIndex >= newValue.count {
                activeIndex = 0
            }
        }
    }
}
