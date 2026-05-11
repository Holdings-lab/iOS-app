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
    @ObservedObject var viewModel: ExchangeRateViewModel
    var title: String = "실시간 원/달러"
    var caption: String = "USD/KRW"

    var body: some View {
        KDXCard {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.brand)
                    .frame(width: 44, height: 44)
                    .background(Color.brandTintBg, in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.pretendard(13, weight: .semibold))
                            .foregroundStyle(Color.textTertiary)
                            .lineLimit(1)

                        Text(caption)
                            .font(.pretendard(10, weight: .bold))
                            .foregroundStyle(Color.brand)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.brandTintBg, in: RoundedRectangle(cornerRadius: KDXRadius.chip, style: .continuous))
                    }

                    Text(viewModel.rateText)
                        .font(.pretendard(24, weight: .heavy))
                        .foregroundStyle(Color.textPrimary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(viewModel.updatedText)
                        .font(.pretendard(11, weight: .semibold))
                        .foregroundStyle(viewModel.isShowingStaleValue ? Color.up : Color.textQuaternary)
                }

                Spacer(minLength: 8)

                refreshButton
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    @ViewBuilder
    private var refreshButton: some View {
        if viewModel.isLoading {
            ProgressView()
                .controlSize(.small)
                .tint(Color.brand)
                .frame(width: 36, height: 36)
        } else {
            Button {
                Task {
                    await viewModel.refresh()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.brand)
                    .frame(width: 36, height: 36)
                    .background(Color.subtle, in: Circle())
                    .overlay { Circle().stroke(Color.hairline, lineWidth: 1) }
            }
            .buttonStyle(PSPressStyle())
            .accessibilityLabel("환율 새로고침")
        }
    }
}

#Preview {
    ExchangeRateSnapshotCard(
        viewModel: ExchangeRateViewModel(provider: MockExchangeRateProvider())
    )
    .padding()
    .background(Color.canvas)
}
