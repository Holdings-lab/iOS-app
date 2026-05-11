import Combine
import SwiftUI

@MainActor
final class ExchangeRateViewModel: ObservableObject {
    @Published private(set) var usdKrwRate: Double
    @Published private(set) var updatedAt: Date?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let provider: ExchangeRateProviding

    init(
        provider: ExchangeRateProviding = LiveExchangeRateProvider(),
        initialUSDKRWRate: Double = 1_375
    ) {
        self.provider = provider
        usdKrwRate = initialUSDKRWRate
    }

    func loadIfNeeded() async {
        guard updatedAt == nil else { return }
        await refresh()
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let quote = try await provider.fetchUSDKRW()
            usdKrwRate = quote.usdToKrw
            updatedAt = quote.fetchedAt
        } catch {
            errorMessage = "업데이트 실패"
        }
    }

    var rateText: String {
        let value = Self.rateFormatter.string(from: NSNumber(value: usdKrwRate))
            ?? String(format: "%.2f", usdKrwRate)
        return "\(value)원"
    }

    var updatedText: String {
        if let errorMessage {
            return errorMessage
        }
        if let updatedAt {
            return "\(Self.timeFormatter.string(from: updatedAt)) 업데이트"
        }
        return isLoading ? "불러오는 중" : "환율 준비 중"
    }

    var isShowingStaleValue: Bool {
        errorMessage != nil
    }

    private static let rateFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

struct ExchangeRateSnapshotCard: View {
    enum DisplayMode {
        case compact
        case full
    }

    @ObservedObject var viewModel: ExchangeRateViewModel
    var title: String = "실시간 원/달러"
    var caption: String = "USD/KRW"
    var displayMode: DisplayMode = .full

    var body: some View {
        KDXCard(padding: cardPadding) {
            content
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private var content: some View {
        HStack(alignment: .center, spacing: displayMode == .compact ? 10 : 14) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: displayMode == .compact ? 18 : 24, weight: .semibold))
                .foregroundStyle(Color.brand)
                .frame(
                    width: displayMode == .compact ? 32 : 44,
                    height: displayMode == .compact ? 32 : 44
                )
                .background(Color.brandTintBg, in: Circle())

            VStack(alignment: .leading, spacing: displayMode == .compact ? 3 : 5) {
                headerRow

                Text(rateLine)
                    .font(.pretendard(
                        displayMode == .compact ? 16 : 24,
                        weight: displayMode == .compact ? .bold : .heavy
                    ))
                    .foregroundStyle(Color.textPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                if displayMode == .full {
                    Text(viewModel.updatedText)
                        .font(.pretendard(11, weight: .semibold))
                        .foregroundStyle(viewModel.isShowingStaleValue ? Color.up : Color.textQuaternary)
                }
            }

            Spacer(minLength: 8)

            refreshButton
        }
    }

    private var headerRow: some View {
        HStack(spacing: 6) {
            Text(displayMode == .compact ? "환율" : title)
                .font(.pretendard(displayMode == .compact ? 11 : 13, weight: .semibold))
                .foregroundStyle(Color.textTertiary)
                .lineLimit(1)

            if displayMode == .full {
                Text(caption)
                    .font(.pretendard(10, weight: .bold))
                    .foregroundStyle(Color.brand)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.brandTintBg, in: RoundedRectangle(cornerRadius: KDXRadius.chip, style: .continuous))
            } else {
                Text(viewModel.updatedText)
                    .font(.pretendard(10, weight: .semibold))
                    .foregroundStyle(viewModel.isShowingStaleValue ? Color.up : Color.textQuaternary)
                    .lineLimit(1)
            }
        }
    }

    private var refreshButton: some View {
        Button {
            Task {
                await viewModel.refresh()
            }
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: displayMode == .compact ? 12 : 14, weight: .semibold))
                .foregroundStyle(Color.brand)
                .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                .animation(
                    viewModel.isLoading
                        ? .linear(duration: 0.8).repeatForever(autoreverses: false)
                        : .default,
                    value: viewModel.isLoading
                )
                .frame(
                    width: displayMode == .compact ? 30 : 36,
                    height: displayMode == .compact ? 30 : 36
                )
                .background(Color.subtle, in: Circle())
                .overlay { Circle().stroke(Color.hairline, lineWidth: 1) }
        }
        .buttonStyle(PSPressStyle())
        .disabled(viewModel.isLoading)
        .accessibilityLabel("환율 새로고침")
    }

    private var cardPadding: EdgeInsets {
        switch displayMode {
        case .compact:
            return EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 10)
        case .full:
            return EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        }
    }

    private var rateLine: String {
        switch displayMode {
        case .compact:
            return "원/달러 \(viewModel.rateText)"
        case .full:
            return viewModel.rateText
        }
    }
}

#Preview {
    ExchangeRateSnapshotCard(
        viewModel: ExchangeRateViewModel(provider: MockExchangeRateProvider()),
        displayMode: .compact
    )
    .padding()
    .background(Color.canvas)
}
