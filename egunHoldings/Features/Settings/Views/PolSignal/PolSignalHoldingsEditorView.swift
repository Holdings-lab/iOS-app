import SwiftUI

struct PolSignalHoldingsEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var holdings: [EditableHolding] = [
        EditableHolding(ticker: "SOXX", name: "iShares Semiconductor ETF", percent: 12, color: PSColor.primary),
        EditableHolding(ticker: "SMH", name: "VanEck Semiconductor ETF", percent: 8, color: PSColor.tagSemi),
        EditableHolding(ticker: "QQQ", name: "Invesco QQQ Trust", percent: 9, color: PSColor.success)
    ]

    private let suggestions = ["SMH", "QQQ", "TLT", "GLD", "SCHD"]

    var body: some View {
        VStack(spacing: 0) {
            holdingsNavBar

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    searchBar
                    holdingsSection
                    totalCard
                    addAssetButton
                    suggestionsSection
                }
                .padding(.horizontal, PSSpacing.screenHorizontal)
                .padding(.top, 10)
                .padding(.bottom, 32)
            }
        }
        .background(PSColor.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var holdingsNavBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(PSColor.textPrimary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("보유 자산")
                .font(.pretendard(17, weight: .semibold))
                .foregroundStyle(PSColor.textPrimary)

            Spacer()

            Button("완료") {
                dismiss()
            }
            .font(.pretendard(15, weight: .semibold))
            .foregroundStyle(PSColor.primary)
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(PSColor.background)
    }

    private var searchBar: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(PSColor.textFaint)

            TextField("ETF, 종목명 검색", text: $searchText)
                .font(.pretendard(14, weight: .regular))
                .foregroundStyle(PSColor.textPrimary)
                .textInputAutocapitalization(.characters)
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(PSColor.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(PSColor.border, lineWidth: 1)
        }
    }

    private var holdingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            PolSignalSectionHeader(title: "보유 중", meta: "\(holdings.count)개")

            PolSignalCard(padding: EdgeInsets(top: 4, leading: 14, bottom: 4, trailing: 14)) {
                VStack(spacing: 0) {
                    ForEach($holdings) { $holding in
                        HoldingRow(
                            holding: $holding,
                            onRemove: {
                                holdings.removeAll { $0.id == holding.id }
                            }
                        )

                        if holding.id != holdings.last?.id {
                            Divider().background(PSColor.rule)
                        }
                    }
                }
            }
        }
    }

    private var totalCard: some View {
        PolSignalCard(padding: EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("합계")
                        .font(.pretendard(13, weight: .regular))
                        .foregroundStyle(PSColor.textSecondary)
                    Spacer()
                    Text("\(Int(totalPercent))%")
                        .font(.pretendard(14, weight: .semibold))
                        .foregroundStyle(totalPercent > 100 ? PSColor.danger : PSColor.textPrimary)
                    Text("/ 100%")
                        .font(.pretendard(13, weight: .regular))
                        .foregroundStyle(PSColor.textFaint)
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(PSColor.rule)
                        Capsule()
                            .fill(totalPercent > 100 ? PSColor.danger : PSColor.primary)
                            .frame(width: min(proxy.size.width, proxy.size.width * totalPercent / 100))
                    }
                }
                .frame(height: 10)

                Text("나머지 \(max(0, Int(100 - totalPercent)))%는 기타로 분류됩니다")
                    .font(.pretendard(12, weight: .regular))
                    .foregroundStyle(PSColor.textFaint)
            }
        }
    }

    private var addAssetButton: some View {
        Button {} label: {
            Text("+ 자산 추가")
                .font(.pretendard(14, weight: .semibold))
                .foregroundStyle(PSColor.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(PSColor.primarySoft.opacity(0.35), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(PSColor.border, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                }
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("자주 추가되는 자산")
                .font(.pretendard(13, weight: .regular))
                .foregroundStyle(PSColor.textSecondary)

            PolSignalFlowLayout(spacing: 8) {
                ForEach(suggestions, id: \.self) { ticker in
                    Button {
                        addQuick(ticker)
                    } label: {
                        Text(ticker)
                            .font(.pretendard(13, weight: .semibold))
                            .foregroundStyle(PSColor.primary)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 8)
                            .background(PSColor.surface, in: Capsule(style: .continuous))
                            .overlay {
                                Capsule(style: .continuous)
                                    .stroke(PSColor.primary.opacity(0.35), lineWidth: 1.5)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var totalPercent: Double {
        holdings.reduce(0) { $0 + $1.percent }
    }

    private func addQuick(_ ticker: String) {
        guard holdings.contains(where: { $0.ticker == ticker }) == false else { return }
        holdings.append(
            EditableHolding(
                ticker: ticker,
                name: quickName(for: ticker),
                percent: 0,
                color: PSColor.primary
            )
        )
    }

    private func quickName(for ticker: String) -> String {
        switch ticker {
        case "TLT":
            return "iShares 20+ Year Treasury Bond"
        case "GLD":
            return "SPDR Gold Shares"
        case "SCHD":
            return "Schwab U.S. Dividend Equity"
        case "SMH":
            return "VanEck Semiconductor ETF"
        case "QQQ":
            return "Invesco QQQ Trust"
        default:
            return "\(ticker) ETF"
        }
    }
}

private struct EditableHolding: Identifiable {
    let id = UUID()
    var ticker: String
    var name: String
    var percent: Double
    var color: Color
}

private struct HoldingRow: View {
    @Binding var holding: EditableHolding
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(String(holding.ticker.prefix(4)))
                .font(.pretendard(11, weight: .bold))
                .foregroundStyle(holding.color)
                .frame(width: 38, height: 38)
                .background(holding.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(holding.ticker)
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(PSColor.textPrimary)
                Text(holding.name)
                    .font(.pretendard(12, weight: .regular))
                    .foregroundStyle(PSColor.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            HStack(spacing: 2) {
                TextField("", value: $holding.percent, format: .number.precision(.fractionLength(0)))
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(PSColor.textPrimary)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                    .frame(width: 34)
                Text("%")
                    .font(.pretendard(13, weight: .semibold))
                    .foregroundStyle(PSColor.textSecondary)
            }

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(PSColor.textFaint)
                    .frame(width: 26, height: 26)
                    .background(PSColor.surfaceAlt, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 11)
    }
}
