import SwiftUI

struct NewsroomFeedModePicker: View {
    @Binding var selectedMode: NewsroomFeedMode

    var body: some View {
        HStack(spacing: 8) {
            ForEach(NewsroomFeedMode.allCases) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedMode = mode
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(mode.title)
                            .font(.pretendard(15, weight: .bold))
                            .foregroundStyle(selectedMode == mode ? Color.textOnAccent : Color.textSecondary)

                        Text(mode == .news ? "속보·보유" : "학습 피드")
                            .font(.pretendard(10, weight: .semibold))
                            .foregroundStyle(selectedMode == mode ? Color.textOnAccent.opacity(0.86) : Color.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(
                        selectedMode == mode ? Color.brand : Color.elevated,
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(selectedMode == mode ? Color.clear : Color.hairline, lineWidth: 1)
                    }
                }
                .buttonStyle(PressScaleButtonStyle())
            }
        }
        .padding(4)
        .background(Color.subtle, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct NewsroomNewsFilterBar: View {
    @Binding var selectedFilter: NewsroomNewsFilter

    var body: some View {
        HStack(spacing: 8) {
            ForEach(NewsroomNewsFilter.allCases) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        selectedFilter = filter
                    }
                } label: {
                    Text(filter.title)
                        .font(.pretendard(12, weight: .bold))
                        .foregroundStyle(selectedFilter == filter ? Color.textOnAccent : Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(
                            selectedFilter == filter ? Color.brand : Color.elevated,
                            in: Capsule(style: .continuous)
                        )
                        .overlay {
                            Capsule(style: .continuous)
                                .stroke(selectedFilter == filter ? Color.clear : Color.hairline, lineWidth: 1)
                        }
                }
                .buttonStyle(PressScaleButtonStyle())
            }
        }
    }
}

struct NewsroomIndustrySummarySection: View {
    let title: String
    let subtitle: String
    let items: [PolicyNewsItem]
    let isSaved: (PolicyNewsItem) -> Bool
    let onSelect: (PolicyNewsItem) -> Void
    let onToggleSave: (PolicyNewsItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(title)
                    .font(.pretendard(16, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text(subtitle)
                    .font(.pretendard(11, weight: .semibold))
                    .foregroundStyle(Color.textQuaternary)

                Spacer()
            }

            if items.isEmpty {
                NewsroomNoIndustryNewsCard()
            } else {
                ForEach(items) { item in
                    IndustryNewsSummaryCard(
                        item: item,
                        isSaved: isSaved(item),
                        onSelect: { onSelect(item) },
                        onToggleSave: { onToggleSave(item) }
                    )
                }
            }
        }
    }
}

struct NewsroomLearningContentSection: View {
    let title: String
    let subtitle: String
    let items: [NewsroomLearningContent]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(title)
                    .font(.pretendard(16, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text(subtitle)
                    .font(.pretendard(11, weight: .semibold))
                    .foregroundStyle(Color.textQuaternary)

                Spacer()
            }

            if items.isEmpty {
                NewsroomNoIndustryNewsCard()
            } else {
                ForEach(items) { item in
                    NewsroomLearningContentCard(item: item)
                }
            }
        }
    }
}

struct NewsroomInfoBox: View {
    let mode: NewsroomFeedMode

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.mutedForeground.opacity(0.25))
                .padding(.top, 2)

            Text(infoText)
                .font(.pretendard(11, weight: .medium))
                .foregroundStyle(Color.mutedForeground.opacity(0.3))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .softGlassCard()
    }

    private var infoText: String {
        switch mode {
        case .news:
            return "뉴스 탭은 연결된 자산을 기준으로 보유 종목 관련 기사와 실시간 속보를 정리합니다. 내 자산 기준 분석은 오늘 탭의 정책 리포트에서 확인할 수 있습니다."
        case .content:
            return "콘텐츠 탭은 뉴스 해석에 필요한 투자 개념과 산업 맥락을 학습용 피드로 정리합니다."
        }
    }
}

struct NewsInvestmentDisclaimer: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "shield.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.mutedForeground.opacity(0.25))
                .padding(.top, 2)

            Text("이 해설은 투자 추천이 아니며, 정책 변화에 대한 해석입니다.")
                .font(.pretendard(11, weight: .medium))
                .foregroundStyle(Color.mutedForeground.opacity(0.3))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct NewsAssetTagFlow: View {
    let tags: [NewsroomAssetTag]

    var body: some View {
        NewsTagFlowLayout {
            ForEach(tags) { tag in
                Text(tag.title)
                    .font(.pretendard(10, weight: .bold))
                    .foregroundStyle(tag.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        tag.color.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: KDXRadius.chip, style: .continuous)
                    )
            }
        }
    }
}

private struct IndustryNewsSummaryCard: View {
    let item: PolicyNewsItem
    let isSaved: Bool
    let onSelect: () -> Void
    let onToggleSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onSelect) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center, spacing: 8) {
                        NewsCategoryBadge(category: item.category)

                        Text(item.newsroomSourceTimeText)
                            .font(.pretendard(10, weight: .semibold))
                            .foregroundStyle(Color.textTertiary)
                            .lineLimit(1)

                        Spacer(minLength: 4)

                        Image(systemName: item.sentiment.iconName)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(item.newsroomDirectionColor)
                            .frame(width: 28, height: 28)
                            .background(item.newsroomDirectionColor.opacity(0.12), in: Circle())
                    }

                    Text(item.title)
                        .font(.pretendard(18, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(item.summary)
                        .font(.pretendard(13, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    NewsAssetTagFlow(tags: item.newsroomAssetTags)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PressScaleButtonStyle())

            HStack(spacing: 8) {
                Button(action: onSelect) {
                    Label("요약·AI해석 보기", systemImage: "doc.text")
                        .font(.pretendard(12, weight: .bold))
                        .foregroundStyle(Color.brand)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color.brandTintBg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(PressScaleButtonStyle())

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onToggleSave()
                } label: {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(isSaved ? Color.brand : Color.textTertiary)
                        .frame(width: 44, height: 40)
                        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.hairline, lineWidth: 1)
                        }
                }
                .buttonStyle(PressScaleButtonStyle())
                .accessibilityLabel(isSaved ? "저장 해제" : "저장")
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

private struct NewsroomLearningContentCard: View {
    let item: NewsroomLearningContent

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: item.heroSystemImage)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(item.category.color)
                    .frame(width: 46, height: 46)
                    .background(item.category.color.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.author)
                        .font(.pretendard(13, weight: .bold))
                        .foregroundStyle(Color.textSecondary)

                    Text(item.publishedText)
                        .font(.pretendard(11, weight: .semibold))
                        .foregroundStyle(Color.textQuaternary)
                }

                Spacer()

                NewsCategoryBadge(category: item.category)
            }

            Text(item.title)
                .font(.pretendard(20, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(item.summary)
                .font(.pretendard(15, weight: .medium))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            learningHero

            HStack(spacing: 14) {
                Label("\(item.commentCount)", systemImage: "message.fill")
                    .font(.pretendard(12, weight: .bold))
                    .foregroundStyle(Color.textTertiary)

                Label(item.readTimeText, systemImage: "clock.fill")
                    .font(.pretendard(12, weight: .bold))
                    .foregroundStyle(Color.textTertiary)

                Spacer()

                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(16)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }

    private var learningHero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            item.category.color.opacity(0.20),
                            Color.textPrimary.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: item.heroSystemImage)
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(item.category.color)
                .frame(width: 86, height: 86)
                .background(Color.elevated.opacity(0.64), in: Circle())
        }
        .frame(maxWidth: .infinity)
        .frame(height: 156)
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(item.category.color.opacity(0.16), lineWidth: 1)
        }
    }
}

private struct NewsroomNoIndustryNewsCard: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "newspaper")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(Color.textDisabled)

            Text("표시할 뉴스가 아직 없어요")
                .font(.pretendard(14, weight: .bold))
                .foregroundStyle(Color.textSecondary)

            Text("속보나 보유 자산 관련 기사가 들어오면 여기에 정리됩니다.")
                .font(.pretendard(12, weight: .medium))
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .softGlassCard()
    }
}

private struct NewsCategoryBadge: View {
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

private struct NewsTagFlowLayout: Layout {
    private let spacing: CGFloat = 6
    private let rowSpacing: CGFloat = 6

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? 320
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var measuredWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x > 0, x + size.width > maxWidth {
                measuredWidth = max(measuredWidth, x - spacing)
                x = 0
                y += rowHeight + rowSpacing
                rowHeight = 0
            }

            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        measuredWidth = max(measuredWidth, max(0, x - spacing))
        return CGSize(width: proposal.width ?? measuredWidth, height: y + rowHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + rowSpacing
                rowHeight = 0
            }

            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(size)
            )

            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
