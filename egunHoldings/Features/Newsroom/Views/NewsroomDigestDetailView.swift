import SwiftUI

/// 다이제스트 상세 (§3). 종목 다이제스트와 시장 스토리가 같은 템플릿을 공유한다.
/// 하나의 짧은 기사처럼 위에서 아래로 읽힌다 — 섹션 라벨·질문 헤더 없이
/// 블록의 순서와 시각 위계만으로 흐름을 만든다.
struct NewsroomDigestDetailView: View {
    let content: NewsroomDetailContent
    let severity: TodayBriefingSeverity
    let referenceText: String
    let relatedLearningContent: NewsroomLearningContent?
    let onSelectLearningContent: (NewsroomLearningContent) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isTitleVisible = false
    @State private var presentedArticleURL: URL?

    var body: some View {
        ZStack {
            Color.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView(.vertical, showsIndicators: false) {
                    // 균일 spacing 대신 그룹 단위 리듬 —
                    // 헤더 ↔ 기사 블록 32(디바이더 기준 16+16), 이후 카드들 28, 푸터 20.
                    VStack(alignment: .leading, spacing: 0) {
                        headerBlock

                        Divider().overlay(Color.hairline)
                            .padding(.top, 16)

                        VStack(alignment: .leading, spacing: 12) {
                            Text(headline)
                                .font(.pretendard(23, weight: .bold))
                                .foregroundStyle(Color.textPrimary)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)

                            if let summary {
                                Text(summary)
                                    .font(.pretendard(16, weight: .regular))
                                    .foregroundStyle(Color.textPrimary)
                                    .lineSpacing(7)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            if !newFacts.isEmpty {
                                newFactsSection
                            }
                        }
                        .padding(.top, 16)

                        if let translationText {
                            NewsroomInlineTranslationBlock(content: translationText)
                                .padding(.top, 28)
                        }

                        if let relatedLearningContent {
                            learningLinkCard(relatedLearningContent)
                                .padding(.top, 28)
                        }

                        if !articles.isEmpty {
                            articlesSection
                                .padding(.top, 28)
                        }

                        footer
                            .padding(.top, 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, KDXSpacing.tabBarHeight + 16)
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { _, newValue in
                    isTitleVisible = newValue > 64
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $presentedArticleURL) { url in
            NewsroomSafariView(url: url)
                .ignoresSafeArea()
        }
    }

    // MARK: - Top Bar (스크롤 시 타이틀 표시)

    private var topBar: some View {
        HStack {
            LiquidGlassBackButton(action: { dismiss() })

            Spacer()

            Text(topBarTitleText)
                .font(.pretendard(15, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .opacity(isTitleVisible ? 1 : 0)
                .animation(.easeInOut(duration: 0.16), value: isTitleVisible)

            Spacer()

            Color.clear.frame(width: 34, height: 34)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.canvas.opacity(0.96))
    }

    // MARK: - Header Block (§3 — 종목명+등락 = 주식앱의 익숙한 문법)

    @ViewBuilder
    private var headerBlock: some View {
        switch content {
        case .ticker(let digest):
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(digest.ticker)
                        .font(.pretendard(15, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    Text(digest.name)
                        .font(.pretendard(13, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                }

                if let priceChangePercent = digest.priceChangePercent {
                    Text("오늘 \(NewsroomPercentFormat.signed(priceChangePercent))")
                        .font(.pretendard(26, weight: .bold))
                        .foregroundStyle(headerNumberColor(for: priceChangePercent))
                        .monospacedDigit()

                    if let impact = digest.portfolioImpactPercent {
                        Text("내 자산의 \(digest.portfolioWeightPercent)% · 총자산 기준 \(NewsroomPercentFormat.signedImpact(impact))")
                            .font(.pretendard(12.5, weight: .semibold))
                            .foregroundStyle(Color.textSecondary)
                    }
                }

                Text(referenceText)
                    .font(.pretendard(11, weight: .semibold))
                    .foregroundStyle(Color.textQuaternary)
                    .padding(.top, 2)
            }

        case .marketStory(_, let portfolioTodayChangePercent):
            VStack(alignment: .leading, spacing: 4) {
                Text("내 자산 전체")
                    .font(.pretendard(13, weight: .bold))
                    .foregroundStyle(Color.textTertiary)

                Text("오늘 \(NewsroomPercentFormat.signed(portfolioTodayChangePercent))")
                    .font(.pretendard(26, weight: .bold))
                    .foregroundStyle(headerNumberColor(for: portfolioTodayChangePercent))
                    .monospacedDigit()

                Text(referenceText)
                    .font(.pretendard(11, weight: .semibold))
                    .foregroundStyle(Color.textQuaternary)
                    .padding(.top, 2)
            }
        }
    }

    /// 오늘탭 규칙 재사용: calm이면 부호 기반, watch/alert면 severity 색 고정.
    /// `drawdownColor`는 고점 대비 낙폭용(양수=빨강)이라 일일 등락엔 calm에서 그대로 쓸 수 없다.
    private func headerNumberColor(for value: Double) -> Color {
        switch severity {
        case .calm:
            return NewsroomPercentFormat.color(for: value)
        case .watch, .alert:
            return severity.drawdownColor(for: value)
        }
    }

    private var newFactsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("새로 알려진 내용")
                .font(.pretendard(14.5, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            ForEach(Array(newFacts.enumerated()), id: \.offset) { _, fact in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .font(.pretendard(14, weight: .bold))
                        .foregroundStyle(Color.textTertiary)

                    Text(fact)
                        .font(.pretendard(14.5, weight: .medium))
                        .foregroundStyle(Color.textPrimary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func learningLinkCard(_ item: NewsroomLearningContent) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("함께 보면 좋아요")
                .font(.pretendard(12, weight: .bold))
                .foregroundStyle(Color.textTertiary)

            Button {
                onSelectLearningContent(item)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: item.heroSystemImage)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(item.category.color)
                        .frame(width: 32, height: 32)
                        .background(item.category.color.opacity(0.12), in: Circle())

                    Text(item.title)
                        .font(.pretendard(13, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)

                    Text("· \(item.readTimeText)")
                        .font(.pretendard(11.5, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)

                    Spacer(minLength: 4)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.textQuaternary)
                }
                .padding(12)
                .background(Color.elevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.hairline, lineWidth: 1)
                }
            }
            .buttonStyle(PressScaleButtonStyle())
        }
    }

    private var articlesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("근거 기사 \(articles.count)")
                .font(.pretendard(14.5, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                ForEach(Array(articles.enumerated()), id: \.element.id) { index, article in
                    if index > 0 {
                        Divider().overlay(Color.hairline)
                    }

                    Button {
                        if let url = article.url {
                            presentedArticleURL = url
                        }
                    } label: {
                        HStack(alignment: .center, spacing: 10) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(article.title)
                                    .font(.pretendard(14, weight: .semibold))
                                    .foregroundStyle(Color.textPrimary)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text("\(article.source) · \(NewsroomDigestDateFormat.relativeText(for: article.publishedAt))")
                                    .font(.pretendard(11, weight: .medium))
                                    .foregroundStyle(Color.textTertiary)
                            }

                            Spacer(minLength: 4)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.textQuaternary)
                        }
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(Color.elevated, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                    .stroke(Color.hairline, lineWidth: 1)
            }
        }
    }

    private var footer: some View {
        Text("\(referenceText) · AI가 여러 기사를 요약했어요. 원문과 다를 수 있어요")
            .font(.pretendard(11, weight: .medium))
            .foregroundStyle(Color.textTertiary)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Content 분기 헬퍼

    private var topBarTitleText: String {
        switch content {
        case .ticker(let digest):
            return digest.ticker
        case .marketStory(let story, _):
            return story.headline
        }
    }

    private var headline: String {
        switch content {
        case .ticker(let digest):
            return digest.headline ?? digest.name
        case .marketStory(let story, _):
            return story.headline
        }
    }

    private var summary: String? {
        switch content {
        case .ticker(let digest):
            return digest.summary
        case .marketStory(let story, _):
            return story.summary
        }
    }

    private var newFacts: [String] {
        switch content {
        case .ticker(let digest):
            return digest.newFacts
        case .marketStory:
            return []
        }
    }

    private var translationText: String? {
        switch content {
        case .ticker(let digest):
            return digest.translationText
        case .marketStory(let story, _):
            return story.translationText
        }
    }

    private var articles: [NewsroomDigestArticle] {
        switch content {
        case .ticker(let digest):
            return digest.articles
        case .marketStory:
            return []
        }
    }
}

#Preview("종목 상세 (alert)") {
    NavigationStack {
        NewsroomDigestDetailView(
            content: .ticker(NewsroomDigestMockData.alert.tickerDigests[0]),
            severity: .alert,
            referenceText: NewsroomDigestMockData.alert.referenceText,
            relatedLearningContent: NewsroomConceptCards.cpiExplained,
            onSelectLearningContent: { _ in }
        )
    }
}

#Preview("종목 상세 (번역 있음)") {
    NavigationStack {
        NewsroomDigestDetailView(
            content: .ticker(NewsroomDigestMockData.calmMixed.tickerDigests[0]),
            severity: .calm,
            referenceText: NewsroomDigestMockData.calmMixed.referenceText,
            relatedLearningContent: NewsroomConceptCards.earningsSeason,
            onSelectLearningContent: { _ in }
        )
    }
}
