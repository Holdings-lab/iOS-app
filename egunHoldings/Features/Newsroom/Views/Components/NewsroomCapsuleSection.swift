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

            Text("이 해설/체크포인트는 투자 권유가 아니며, 정책 변화에 대한 해석입니다.")
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
                HStack(alignment: .top, spacing: 8) {
                    PulseDirectionDot(color: item.newsroomDirectionColor)
                        .padding(.top, 6)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.pretendard(13, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(item.newsroomSourceTimeText)
                            .font(.pretendard(10, weight: .medium))
                            .foregroundStyle(Color.mutedForeground.opacity(0.4))
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.mutedForeground.opacity(0.35))
                        .padding(.top, 4)
                }

                Text(item.summary)
                    .font(.pretendard(12, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                NewsAssetTagFlow(tags: item.newsroomAssetTags)

                VStack(alignment: .leading, spacing: 6) {
                    Text("내 자산 해석")
                        .font(.pretendard(11, weight: .bold))
                        .foregroundStyle(Color.electricBlue)

                    Text(item.newsroomAssetImpactText)
                        .font(.pretendard(12, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
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
        HStack(spacing: 10) {
            Button(action: onSelect) {
                HStack(alignment: .top, spacing: 8) {
                    PulseDirectionDot(color: item.newsroomDirectionColor)
                        .padding(.top, 5)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.pretendard(12, weight: .semibold))
                            .foregroundStyle(Color.textPrimary.opacity(0.8))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(item.newsroomSourceTimeText)
                            .font(.pretendard(10, weight: .medium))
                            .foregroundStyle(Color.mutedForeground.opacity(0.3))
                    }
                }
            }
            .buttonStyle(.plain)

            Button(action: onToggleSave) {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(isSaved ? Color.electricBlue : Color.mutedForeground.opacity(0.45))
                    .frame(width: 36, height: 36)
                    .background(Color.elevated.opacity(0.7), in: Circle())
                    .overlay {
                        Circle()
                            .stroke(Color.hairline, lineWidth: 1)
                    }
            }
            .buttonStyle(PressScaleButtonStyle())
        }
        .padding(12)
        .softGlassCard()
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
