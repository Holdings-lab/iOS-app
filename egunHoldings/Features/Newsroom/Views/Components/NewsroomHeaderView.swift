import SwiftUI
import Combine

struct NewsroomHeaderView: View {
    let tickers: [NewsroomMarketTicker]
    let feedMode: NewsroomFeedMode
    let onTickerTap: (NewsroomMarketTicker) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "newspaper.fill")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(Color.electricBlue)
                    .frame(width: 30, height: 30)

                VStack(alignment: .leading, spacing: 3) {
                    Text("피드")
                        .font(.pretendard(22, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .tracking(-0.5)

                    Text(feedMode.subtitle)
                        .font(.pretendard(13, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                }

                Spacer()
            }

            if !tickers.isEmpty {
                NewsroomRollingTickerView(
                    tickers: tickers,
                    onTickerTap: onTickerTap
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.elevated, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.hairline, lineWidth: 1)
                }
            }
        }
    }
}

private struct NewsroomRollingTickerView: View {
    let tickers: [NewsroomMarketTicker]
    let onTickerTap: (NewsroomMarketTicker) -> Void
    @State private var activeIndex = 0

    private var activeTicker: NewsroomMarketTicker? {
        guard !tickers.isEmpty else { return nil }
        return tickers[activeIndex % tickers.count]
    }

    var body: some View {
        Group {
            if let activeTicker {
                Button {
                    onTickerTap(activeTicker)
                } label: {
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
                }
                .buttonStyle(.plain)
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
