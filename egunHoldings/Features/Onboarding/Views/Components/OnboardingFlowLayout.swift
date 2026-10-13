import SwiftUI

struct OnboardingV3FlowLayout: Layout {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    init(horizontalSpacing: CGFloat = 8, verticalSpacing: CGFloat = 10) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .greatestFiniteMagnitude
        let layout = makeLayout(maxWidth: maxWidth, subviews: subviews)

        return CGSize(
            width: proposal.width ?? layout.width,
            height: layout.height
        )
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if xOffset > 0, xOffset + size.width > bounds.width {
                xOffset = 0
                yOffset += rowHeight + verticalSpacing
                rowHeight = 0
            }

            subview.place(
                at: CGPoint(x: bounds.minX + xOffset, y: bounds.minY + yOffset),
                proposal: ProposedViewSize(size)
            )

            xOffset += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }
    }

    private func makeLayout(maxWidth: CGFloat, subviews: Subviews) -> (width: CGFloat, height: CGFloat) {
        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0
        var rowHeight: CGFloat = 0
        var measuredWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if xOffset > 0, xOffset + size.width > maxWidth {
                measuredWidth = max(measuredWidth, xOffset - horizontalSpacing)
                xOffset = 0
                yOffset += rowHeight + verticalSpacing
                rowHeight = 0
            }

            xOffset += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }

        measuredWidth = max(measuredWidth, xOffset > 0 ? xOffset - horizontalSpacing : 0)

        return (measuredWidth, yOffset + rowHeight)
    }
}
