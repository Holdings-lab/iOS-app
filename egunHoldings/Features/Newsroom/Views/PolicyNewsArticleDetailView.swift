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
                subtitle: article.paragraphs.isEmpty ? "원문 링크에서 확인" : "중요 문장만 하이라이트",
                iconName: "doc.plaintext",
                tint: Color.electricBlue
            )

            if article.paragraphs.isEmpty {
                ArticleBodyUnavailableCard(
                    hasSourceURL: item.sourceURL != nil,
                    onOpenSource: {
                        if let sourceURL = item.sourceURL {
                            openURL(sourceURL)
                        }
                    }
                )
            } else {
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

private struct ArticleBodyUnavailableCard: View {
    let hasSourceURL: Bool
    let onOpenSource: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("기사 전문 데이터가 아직 제공되지 않았어요")
                .font(.pretendard(15, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            Text("전문 보기는 서버가 실제 기사 본문을 내려줄 때 그대로 표시합니다. 현재는 요약과 원문 링크만 확인할 수 있어요.")
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onOpenSource) {
                Label(hasSourceURL ? "원문에서 전문 보기" : "원문 링크 없음", systemImage: "arrow.up.forward.square")
                    .font(.pretendard(13, weight: .bold))
                    .foregroundStyle(hasSourceURL ? Color.electricBlue : Color.textDisabled)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.electricBlue.opacity(hasSourceURL ? 0.10 : 0.04), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(PressScaleButtonStyle())
            .disabled(!hasSourceURL)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.subtle.opacity(0.66), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
        let summaryBullets = Self.summarySentences(from: item.summary)
        let paragraphs = Self.articleParagraphs(from: item.articleBody)

        let highlights = [
            item.summary,
            tickers
        ] + item.relatedTickers

        return NewsroomArticleDetailContent(
            summaryBullets: summaryBullets,
            paragraphs: paragraphs,
            highlightPhrases: highlights
        )
    }

    private static func summarySentences(from summary: String) -> [String] {
        let sentences = summary
            .split(whereSeparator: { ".!?。！？".contains($0) })
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if sentences.isEmpty {
            let trimmedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedSummary.isEmpty ? ["요약 데이터가 아직 제공되지 않았어요."] : [trimmedSummary]
        }

        return Array(sentences.prefix(3))
    }

    private static func articleParagraphs(from articleBody: String?) -> [String] {
        guard let articleBody else { return [] }

        return articleBody
            .components(separatedBy: CharacterSet.newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

#Preview {
    NavigationStack {
        PolicyNewsArticleDetailView(item: HomeNewsMockData.items[0])
    }
}
