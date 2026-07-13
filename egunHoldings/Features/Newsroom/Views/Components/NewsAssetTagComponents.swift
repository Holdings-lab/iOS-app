import SwiftUI

/// 뉴스 상세/인사이트 화면 공용 — 투자 추천이 아님을 알리는 고지 문구.
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

/// 뉴스 상세/인사이트 화면 공용 — 관련 종목/카테고리 태그 흐름.
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
