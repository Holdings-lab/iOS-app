import SwiftUI

struct PolicyNewsArticleDetailView: View {
    let item: PolicyNewsItem

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private var article: NewsroomArticleDetailContent {
        NewsroomArticleDetailContent.make(for: item)
    }

    var body: some View {
        ZStack {
            Color.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                GeometryReader { geometry in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            articleHeader
                            summarySection
                            fullArticleSection
                            sourceSection
                        }
                        .frame(width: max(0, geometry.size.width - 32), alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 34)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var topBar: some View {
        HStack {
            LiquidGlassBackButton(action: { dismiss() })

            Spacer()

            Text("뉴스 상세")
                .font(.pretendard(18, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Button {
                if let sourceURL = item.sourceURL {
                    openURL(sourceURL)
                }
            } label: {
                Image(systemName: "arrow.up.forward.square")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(item.sourceURL == nil ? Color.textDisabled : Color.textPrimary)
                    .frame(width: 34, height: 34)
                    .contentShape(Circle())
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .controlSize(.small)
            .disabled(item.sourceURL == nil)
            .accessibilityLabel("원문 열기")
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.canvas.opacity(0.96))
    }

    private var articleHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                NewsArticleCategoryBadge(category: item.category)

                Text(item.sourceName)
                    .font(.pretendard(12, weight: .bold))
                    .foregroundStyle(Color.textTertiary)

                Text("·")
                    .font(.pretendard(12, weight: .bold))
                    .foregroundStyle(Color.textQuaternary)

                Text(item.newsroomSourceTimeText)
                    .font(.pretendard(12, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)

                Spacer()
            }

            Text(item.title)
                .font(.pretendard(25, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            NewsAssetTagFlow(tags: item.newsroomAssetTags)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            NewsArticleSectionHeader(
                title: "뉴스 요약",
                subtitle: "핵심만 먼저",
                iconName: "text.alignleft",
                tint: item.newsroomAccentColor
            )

            Text(item.summary)
                .font(.pretendard(17, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(article.summaryBullets.enumerated()), id: \.offset) { index, bullet in
                    NewsArticleBulletRow(
                        index: index + 1,
                        text: bullet,
                        tint: item.newsroomAccentColor
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(item.newsroomAccentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(item.newsroomAccentColor.opacity(0.18), lineWidth: 1)
        }
    }

    private var fullArticleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            NewsArticleSectionHeader(
                title: "전문 보기",
                subtitle: "중요 문장만 하이라이트",
                iconName: "doc.plaintext",
                tint: Color.electricBlue
            )

            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(article.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                    Text(highlighted(paragraph))
                        .font(.pretendard(15, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                        .lineSpacing(7)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            NewsArticleSectionHeader(
                title: "원문",
                subtitle: item.sourceName,
                iconName: "link",
                tint: Color.electricBlue
            )

            Button {
                if let sourceURL = item.sourceURL {
                    openURL(sourceURL)
                }
            } label: {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.sourceURL?.host ?? "원문 링크 없음")
                            .font(.pretendard(14, weight: .bold))
                            .foregroundStyle(item.sourceURL == nil ? Color.textDisabled : Color.textPrimary)
                            .lineLimit(1)

                        Text("브라우저에서 기사 원문을 확인해요")
                            .font(.pretendard(12, weight: .medium))
                            .foregroundStyle(Color.textTertiary)
                    }

                    Spacer()

                    Image(systemName: "arrow.up.forward")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(item.sourceURL == nil ? Color.textDisabled : Color.electricBlue)
                }
                .padding(14)
                .background(Color.subtle.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(PressScaleButtonStyle())
            .disabled(item.sourceURL == nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }

    private func highlighted(_ paragraph: String) -> AttributedString {
        var attributed = AttributedString(paragraph)

        for phrase in article.highlightPhrases where !phrase.isEmpty {
            if let range = attributed.range(of: phrase, options: [.caseInsensitive]) {
                attributed[range].foregroundColor = Color.textPrimary
                attributed[range].backgroundColor = item.newsroomAccentColor.opacity(0.16)
                attributed[range].font = .pretendard(15, weight: .bold)
            }
        }

        return attributed
    }
}

private struct NewsArticleSectionHeader: View {
    let title: String
    let subtitle: String
    let iconName: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.pretendard(15, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text(subtitle)
                    .font(.pretendard(11, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
            }

            Spacer()
        }
    }
}

private struct NewsArticleBulletRow: View {
    let index: Int
    let text: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Text("\(index)")
                .font(.pretendard(11, weight: .bold))
                .foregroundStyle(Color.textOnAccent)
                .frame(width: 22, height: 22)
                .background(tint, in: Circle())
                .padding(.top, 1)

            Text(text)
                .font(.pretendard(13, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct NewsArticleCategoryBadge: View {
    let category: PolicyNewsCategory

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: category.newsroomIconName)
                .font(.system(size: 10, weight: .bold))
            Text(category.title)
                .font(.pretendard(10, weight: .bold))
        }
        .foregroundStyle(category.color)
        .padding(.horizontal, 9)
        .frame(height: 25)
        .background(category.color.opacity(0.12), in: Capsule(style: .continuous))
    }
}

private struct NewsroomArticleDetailContent {
    let summaryBullets: [String]
    let paragraphs: [String]
    let highlightPhrases: [String]

    static func make(for item: PolicyNewsItem) -> NewsroomArticleDetailContent {
        let tickers = item.relatedTickers.joined(separator: ", ")
        let relatedAssetText = tickers.isEmpty ? "관련 자산의 직접 영향은 제한적으로 확인됩니다." : "\(tickers) 관련 흐름이 함께 언급됐습니다."
        let sourceText = "\(item.sourceName)은 \(item.category.title) 이슈가 시장 심리에 미치는 영향을 전했습니다."

        let summaryBullets = [
            item.summary,
            relatedAssetText,
            item.sentiment == .caution ? "단기 변동성이 커질 수 있어 원문 수치와 일정을 확인할 필요가 있습니다." : "단기 반응보다 실제 발표 수치와 집행 일정을 함께 확인하는 편이 좋습니다."
        ]

        let categoryContext: String
        switch item.category {
        case .semiconductor:
            categoryContext = "반도체 업종은 보조금, 수출 규제, 설비투자 뉴스에 민감하게 반응합니다. 특히 장비와 소재 공급망까지 기대가 번질 경우 ETF 거래대금이 함께 늘어날 수 있습니다."
        case .interestRate:
            categoryContext = "금리 뉴스는 결정 자체보다 발표문 문구와 시장의 다음 인하 시점 해석이 중요합니다. 은행주, 채권, 환율이 서로 다른 속도로 반응할 수 있습니다."
        case .energy:
            categoryContext = "에너지 정책은 예산 배정과 실제 집행 일정에 따라 수혜 범위가 달라집니다. 전력망, 재생에너지, 저장장치처럼 세부 산업별 반응도 분리해서 볼 필요가 있습니다."
        case .macro:
            categoryContext = "거시경제 지표는 주식, 달러, 금리 기대를 동시에 움직입니다. 첫 반응은 되돌림이 잦기 때문에 수치와 시장 예상치의 차이를 같이 확인해야 합니다."
        case .finance:
            categoryContext = "금융 뉴스는 예금 금리, 대출 비용, 은행주 수익성에 동시에 영향을 줄 수 있습니다. 숫자보다 시행 시점과 적용 범위를 확인하는 것이 우선입니다."
        case .ai:
            categoryContext = "AI 규제와 가이드라인은 플랫폼, 반도체, 클라우드 기업의 투자 심리에 영향을 줄 수 있습니다. 다만 실제 매출 변화로 이어지는 데에는 시간이 필요합니다."
        }

        let paragraphs = [
            sourceText + " 이번 기사에서 가장 먼저 볼 부분은 \(item.summary)",
            categoryContext,
            "기사에 따르면 \(relatedAssetText) 다만 같은 업종 안에서도 기업별 노출도와 수혜 시점은 달라질 수 있어 제목만으로 방향을 단정하기는 어렵습니다.",
            "전문을 읽을 때는 발표 주체, 시행 시점, 실제 금액이나 수치가 확인됐는지 순서대로 보는 것이 좋습니다. 이미 가격이 먼저 움직인 경우에는 추가 뉴스보다 거래대금과 변동성 확대 여부가 더 중요한 확인 지점입니다."
        ]

        let highlights = [
            item.summary,
            relatedAssetText,
            "발표 주체, 시행 시점, 실제 금액이나 수치",
            "제목만으로 방향을 단정하기는 어렵습니다"
        ] + item.relatedTickers

        return NewsroomArticleDetailContent(
            summaryBullets: summaryBullets,
            paragraphs: paragraphs,
            highlightPhrases: highlights
        )
    }
}

#Preview {
    NavigationStack {
        PolicyNewsArticleDetailView(item: HomeNewsMockData.items[0])
    }
}
