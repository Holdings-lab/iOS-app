import SwiftUI

// MARK: - Holdings Top3 (Section 2)

struct TodayHoldingsTop3Card: View {
    let holdings: [TodayHolding]
    let isAccountLinked: Bool
    let onConnectAccount: () -> Void

    // 종목이 아니라 섹터(category)에 색을 배정 — 같은 섹터는 같은 색을 공유하며,
    // 처음 등장한 순서대로 5색 팔레트를 순환 배정한다.
    private static let sectorPalette: [Color] = [
        Color(hex: "3461FD"), Color(hex: "E8963C"), Color(hex: "2EA8A0"),
        Color(hex: "8B5CF6"), Color(hex: "D95C8F"),
    ]
    private static let otherColor = Color(hex: "C7CCDA")

    var body: some View {
        KDXCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("보유 비중 Top 3")
                    .font(.pretendard(15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                Rectangle()
                    .fill(Color.divider)
                    .frame(height: 1)
                    .padding(.top, 10)
                    .padding(.bottom, 4)

                if !isAccountLinked {
                    TodayQuietState(
                        iconName: "link",
                        message: Text("증권사 계정을 연결하면\n보유 종목 비중을 보여드려요"),
                        ctaTitle: "계정 연결하기",
                        onCTA: onConnectAccount
                    )
                } else {
                    VStack(spacing: 14) {
                        ForEach(rows) { row in
                            TodayHoldingRow(row: row)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    /// 뷰모델이 금액 기준으로 계산한 Top3와 기타 행을 표시한다.
    private var rows: [TodayHoldingRowData] {
        var sectorColors: [String: Color] = [:]
        let mapped: [TodayHoldingRowData] = holdings.map { holding in
            let color = sectorColors[holding.category] ?? {
                let assigned = Self.sectorPalette[sectorColors.count % Self.sectorPalette.count]
                sectorColors[holding.category] = assigned
                return assigned
            }()
            return TodayHoldingRowData(
                id: holding.id,
                ticker: holding.ticker,
                name: holding.name,
                weightPercent: holding.weight,
                color: color
            )
        }

        return mapped
    }
}

private struct TodayHoldingRowData: Identifiable {
    let id: String
    let ticker: String
    let name: String
    let weightPercent: Int
    let color: Color
}

private struct TodayHoldingRow: View {
    let row: TodayHoldingRowData

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                Circle()
                    .fill(row.color)
                    .frame(width: 7, height: 7)
                Text(row.ticker)
                    .font(.pretendard(13, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text(row.name)
                    .font(.pretendard(12, weight: .regular))
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 8)
                Text("\(row.weightPercent)%")
                    .font(.pretendard(13, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .monospacedDigit()
            }

            // 바 너비는 전체 보유 평가금액 대비 절대 비중만 반영한다.
            GeometryReader { proxy in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.muted)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(row.color)
                            .frame(width: proxy.size.width * CGFloat(row.weightPercent) / 100.0)
                    }
            }
            .frame(height: 8)
        }
    }
}
