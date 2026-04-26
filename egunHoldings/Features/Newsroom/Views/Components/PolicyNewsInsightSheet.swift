import SwiftUI

struct PolicyNewsInsightSheet: View {
    let item: PolicyNewsItem
    let insight: PolicyNewsInsight?
    let isLoading: Bool
    let errorMessage: String?
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.deepNavy.opacity(0.94),
                    Color.electricBlue.opacity(0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    if let insight {
                        loadedContent(insight)
                    } else if isLoading {
                        loadingState
                    } else if let errorMessage {
                        errorState(message: errorMessage)
                    } else {
                        loadingState
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(item.category.color.opacity(0.18))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "newspaper.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(item.category.color)
                    }
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text("\(item.category.title) · \(item.sourceName)")
                        .font(.pretendard(12, weight: .medium))
                        .foregroundStyle(Color.mutedForeground)

                    Text(item.title)
                        .font(.pretendard(18, weight: .bold))
                        .foregroundStyle(Color.foreground)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                Label(item.relativePublishedText, systemImage: "clock")

                if let sourceURL = item.sourceURL {
                    Link(destination: sourceURL) {
                        Label("원문 보기", systemImage: "arrow.up.right.square")
                    }
                }
            }
            .font(.pretendard(12, weight: .medium))
            .foregroundStyle(Color.electricBlue)
        }
        .padding(14)
        .softGlassCard()
    }

    private func loadedContent(_ insight: PolicyNewsInsight) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            summaryCard(
                title: "기사 핵심",
                symbol: "text.alignleft",
                headline: insight.headline,
                lines: insight.articleSummary
            )

            summaryCard(
                title: "내 자산 기준 해설",
                symbol: "person.crop.circle.badge.checkmark",
                headline: insight.portfolioHeadline,
                lines: insight.portfolioBullets
            )

            checklistCard(
                title: "지금 확인할 포인트",
                symbol: "checklist",
                items: insight.actionChecklist,
                accentColor: .electricBlue
            )

            checklistCard(
                title: "주의할 점",
                symbol: "exclamationmark.triangle.fill",
                items: insight.riskNotes,
                accentColor: .policyAmber
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.electricBlue)
                    Text("생성 정보")
                        .font(.pretendard(14, weight: .semibold))
                        .foregroundStyle(Color.foreground)
                }

                Text("업데이트 \(insight.generatedAtText)")
                    .font(.pretendard(12, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)

                Text(insight.disclaimer)
                    .font(.pretendard(11, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .softGlassCard()
        }
    }

    private var loadingState: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ProgressView()
                    .tint(Color.electricBlue)
                Text("기사와 보유 자산을 바탕으로 맞춤 해설을 만드는 중이에요")
                    .font(.pretendard(13, weight: .semibold))
                    .foregroundStyle(Color.foreground)
            }

            Text("이 구간은 나중에 serverless backend가 OpenAI 응답을 받아 채워주는 자리예요.")
                .font(.pretendard(12, weight: .medium))
                .foregroundStyle(Color.mutedForeground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .softGlassCard()
    }

    private func errorState(message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(message)
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.foreground)
                .fixedSize(horizontal: false, vertical: true)

            Button("다시 시도하기") {
                onRetry()
            }
            .font(.pretendard(13, weight: .semibold))
            .foregroundStyle(Color.electricBlue)
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .softGlassCard()
    }

    private func summaryCard(
        title: String,
        symbol: String,
        headline: String,
        lines: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .foregroundStyle(Color.electricBlue)
                Text(title)
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(Color.foreground)
            }

            Text(headline)
                .font(.pretendard(13, weight: .semibold))
                .foregroundStyle(Color.foreground)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.pretendard(11, weight: .bold))
                        .foregroundStyle(Color.electricBlue)
                        .frame(width: 20, height: 20)
                        .background(Color.electricBlue.opacity(0.14), in: Circle())

                    Text(line)
                        .font(.pretendard(12, weight: .medium))
                        .foregroundStyle(Color.mutedForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(14)
        .softGlassCard()
    }

    private func checklistCard(
        title: String,
        symbol: String,
        items: [String],
        accentColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .foregroundStyle(accentColor)
                Text(title)
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(Color.foreground)
            }

            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(accentColor)
                        .padding(.top, 2)

                    Text(item)
                        .font(.pretendard(12, weight: .medium))
                        .foregroundStyle(Color.mutedForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
        .softGlassCard()
    }
}

#Preview {
    PolicyNewsInsightSheet(
        item: HomeNewsMockData.items[0],
        insight: HomeNewsMockData.insights[HomeNewsMockData.items[0].id],
        isLoading: false,
        errorMessage: nil,
        onRetry: {}
    )
    .presentationDetents([.medium, .large])
}
