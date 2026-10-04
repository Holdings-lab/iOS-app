import SwiftUI

// MARK: - Holdings-related News (Section 4)

struct TodayNewsSection: View {
    let newsItems: [TodayNewsItem]
    let isAccountLinked: Bool
    let onNewsTap: (TodayNewsItem) -> Void
    let onSeeMoreTapped: () -> Void

    private var headerTitle: String {
        isAccountLinked ? "보유종목 관련 뉴스" : "관심 분야 뉴스"
    }

    var body: some View {
        KDXCard {
            VStack(alignment: .leading, spacing: 0) {
                Text(headerTitle)
                    .font(.pretendard(15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                Rectangle()
                    .fill(Color.divider)
                    .frame(height: 1)
                    .padding(.top, 10)
                    .padding(.bottom, 4)

                if newsItems.isEmpty {
                    TodayEmptyStateCard(
                        iconName: "newspaper",
                        title: "오늘 뉴스를 수집하고 있어요",
                        subtitle: "당일 뉴스가 확인되면 바로 알려드릴게요. 잠시 후 새로고침해 주세요"
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(newsItems.prefix(4).enumerated()), id: \.element.id) { index, item in
                            if index > 0 {
                                Divider().background(Color.divider)
                            }

                            Button { onNewsTap(item) } label: {
                                TodayNewsRow(item: item)
                            }
                            .buttonStyle(PressScaleButtonStyle())
                        }
                    }

                    Divider().background(Color.divider).padding(.top, 12)

                    Button(action: onSeeMoreTapped) {
                        HStack {
                            Text("뉴스룸에서 더 보기 →")
                                .font(.pretendard(13, weight: .semibold))
                                .foregroundStyle(Color.brand)
                            Spacer()
                        }
                        .padding(.top, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressScaleButtonStyle())
                }
            }
        }
    }
}

private struct TodayNewsRow: View {
    let item: TodayNewsItem

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let ticker = item.ticker {
                Text(ticker)
                    .font(.pretendard(12, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.subtle, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(item.summary)
                    .font(.pretendard(12, weight: .regular))
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
