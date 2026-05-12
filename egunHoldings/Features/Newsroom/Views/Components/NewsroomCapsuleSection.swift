import SwiftUI

enum NewsroomCardPresentation {
    case detail
    case skim
    case ignore
}

struct NewsroomPrioritySection: View {
    let title: String
    let subtitle: String
    let items: [PolicyNewsItem]
    let presentation: NewsroomCardPresentation
    let isSaved: (PolicyNewsItem) -> Bool
    let onSelect: (PolicyNewsItem) -> Void
    let onToggleSave: (PolicyNewsItem) -> Void
    let onShowLowReason: (PolicyNewsItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader

            ForEach(items) { item in
                switch presentation {
                case .detail:
                    NewsDetailCard(
                        item: item,
                        onSelect: { onSelect(item) }
                    )
                case .skim:
                    NewsSkimCard(
                        item: item,
                        isSaved: isSaved(item),
                        onSelect: { onSelect(item) },
                        onToggleSave: { onToggleSave(item) }
                    )
                case .ignore:
                    NewsIgnoreCard(
                        item: item,
                        onShowReason: { onShowLowReason(item) },
                        onOpen: { onSelect(item) }
                    )
                }
            }
        }
    }

    private var sectionHeader: some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            Text(title)
                .font(.pretendard(15, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            Text(subtitle)
                .font(.pretendard(11, weight: .semibold))
                .foregroundStyle(Color.textQuaternary)

            Spacer()
        }
    }
}

struct NewsroomSavedSection: View {
    let items: [PolicyNewsItem]
    let onSelect: (PolicyNewsItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("저장됨")
                    .font(.pretendard(15, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text("\(items.count)건")
                    .font(.pretendard(11, weight: .semibold))
                    .foregroundStyle(Color.textQuaternary)

                Spacer()
            }

            if items.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(Color.mutedForeground.opacity(0.2))

                    Text("저장한 뉴스가 없어요")
                        .font(.pretendard(13, weight: .semibold))
                        .foregroundStyle(Color.mutedForeground.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 34)
                .softGlassCard()
            } else {
                ForEach(items) { item in
                    NewsDetailCard(item: item) {
                        onSelect(item)
                    }
                }
            }
        }
    }
}

struct NewsroomInfoBox: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.mutedForeground.opacity(0.25))
                .padding(.top, 2)

            Text("뉴스는 현재 보유종목과의 연관성을 기준으로 우선순위를 자동 분류합니다. 모든 해설은 투자 권유가 아닙니다.")
                .font(.pretendard(11, weight: .medium))
                .foregroundStyle(Color.mutedForeground.opacity(0.3))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .softGlassCard()
    }
}

struct NewsInvestmentDisclaimer: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "shield.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.mutedForeground.opacity(0.25))
                .padding(.top, 2)

            Text("이 해설은 투자 권유가 아니며, 정책 변화에 대한 해석입니다.")
                .font(.pretendard(11, weight: .medium))
                .foregroundStyle(Color.mutedForeground.opacity(0.3))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct NewsDetailCard: View {
    let item: PolicyNewsItem
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 8) {
                    NewsModeBadge(text: "분석 · 3분", tint: item.newsroomAccentColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.newsroomSourceTimeText)
                            .font(.pretendard(10, weight: .medium))
                            .foregroundStyle(Color.mutedForeground.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.mutedForeground.opacity(0.35))
                        .padding(.top, 4)
                }

                Text(item.title)
                    .font(.pretendard(16, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(item.summary)
                    .font(.pretendard(12, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                NewsAssetTagFlow(tags: item.newsroomAssetTags)

                VStack(alignment: .leading, spacing: 6) {
                    Text("내 자산 기준 분석")
                        .font(.pretendard(11, weight: .bold))
                        .foregroundStyle(Color.electricBlue)

                    Text(item.newsroomAssetImpactText)
                        .font(.pretendard(12, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 5) {
                        Text("근거와 시나리오 보기")
                            .font(.pretendard(11, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(Color.electricBlue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.subtle, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.hairline, lineWidth: 1)
                }
            }
            .padding(14)
            .glassCard()
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}

private struct NewsSkimCard: View {
    let item: PolicyNewsItem
    let isSaved: Bool
    let onSelect: () -> Void
    let onToggleSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onSelect) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center, spacing: 8) {
                        NewsModeBadge(text: "요약 · 1분", tint: item.newsroomDecisionColor)

                        Text(item.newsroomSourceTimeText)
                            .font(.pretendard(10, weight: .semibold))
                            .foregroundStyle(Color.textTertiary)
                            .lineLimit(1)

                        Spacer(minLength: 4)

                        Image(systemName: item.newsroomDecisionIconName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(item.newsroomDecisionColor)
                            .frame(width: 30, height: 30)
                            .background(item.newsroomDecisionColor.opacity(0.12), in: Circle())
                    }

                    Text(item.newsroomDecisionTitle)
                        .font(.pretendard(20, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(item.newsroomDecisionSummary)
                        .font(.pretendard(13, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 7) {
                        ForEach(Array(item.newsroomQuickPoints.prefix(3).enumerated()), id: \.offset) { index, point in
                            QuickNewsPointRow(
                                index: index + 1,
                                text: point,
                                tint: index == 0 ? item.newsroomDecisionColor : item.newsroomAccentColor
                            )
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                Button(action: onSelect) {
                    Label(item.newsroomDecisionTitle, systemImage: item.newsroomDecisionIconName)
                        .font(.pretendard(12, weight: .bold))
                        .foregroundStyle(Color.textOnAccent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(item.newsroomDecisionColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(PressScaleButtonStyle())

                Button(action: onToggleSave) {
                    Label(isSaved ? "추가됨" : "나중에 보기", systemImage: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.pretendard(12, weight: .bold))
                        .foregroundStyle(isSaved ? Color.electricBlue : Color.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .frame(width: 118, height: 40)
                        .background(Color.elevated.opacity(0.85), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.hairline, lineWidth: 1)
                        }
                }
                .buttonStyle(PressScaleButtonStyle())
            }
        }
        .padding(14)
        .softGlassCard()
    }
}

private struct NewsModeBadge: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.pretendard(10, weight: .bold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .frame(height: 25)
            .background(tint.opacity(0.12), in: Capsule(style: .continuous))
    }
}

private struct QuickNewsPointRow: View {
    let index: Int
    let text: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(index)")
                .font(.pretendard(10, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 22, height: 22)
                .background(tint.opacity(0.12), in: Circle())
                .padding(.top, 1)

            Text(text)
                .font(.pretendard(12, weight: .medium))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct NewsIgnoreCard: View {
    let item: PolicyNewsItem
    let onShowReason: () -> Void
    let onOpen: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.pretendard(12, weight: .semibold))
                    .foregroundStyle(Color.textPrimary.opacity(0.5))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(item.sourceName)
                    .font(.pretendard(10, weight: .medium))
                    .foregroundStyle(Color.mutedForeground.opacity(0.3))
            }

            HStack(spacing: 6) {
                Button(action: onShowReason) {
                    HStack(spacing: 3) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 11, weight: .semibold))
                        Text("왜?")
                            .font(.pretendard(11, weight: .semibold))
                    }
                    .foregroundStyle(Color.mutedForeground.opacity(0.3))
                    .frame(height: 28)
                }
                .buttonStyle(.plain)

                Button(action: onOpen) {
                    Text("보기")
                        .font(.pretendard(10, weight: .bold))
                        .foregroundStyle(Color.electricBlue)
                        .padding(.horizontal, 9)
                        .frame(height: 28)
                        .background(
                            Color.electricBlue.opacity(0.12),
                            in: Capsule(style: .continuous)
                        )
                }
                .buttonStyle(PressScaleButtonStyle())
            }
        }
        .padding(12)
        .softGlassCard()
        .opacity(0.6)
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

private struct PulseDirectionDot: View {
    let color: Color
    @State private var isActive = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 6, height: 6)
            .opacity(isActive ? 1 : 0.4)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    isActive = true
                }
            }
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
                anchor: .topLeading,
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )

            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
