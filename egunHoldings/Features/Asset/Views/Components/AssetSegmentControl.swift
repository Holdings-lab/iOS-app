import SwiftUI

struct AssetSegmentControl: View {
    @Binding var selectedSegment: AssetSegment
    let onSelect: (AssetSegment) -> Void

    var body: some View {
        HStack(spacing: PSSpacing.pillGap) {
            ForEach(AssetSegment.allCases) { segment in
                Button {
                    onSelect(segment)
                } label: {
                    Text(segment.displayTitle)
                        .font(PSFont.caption())
                        .foregroundStyle(selectedSegment == segment ? Color.textPrimary : Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedSegment == segment ? Color.elevated : Color.clear,
                            in: Capsule(style: .continuous)
                        )
                        .shadow(
                            color: selectedSegment == segment ? Color.cardShadow : Color.clear,
                            radius: selectedSegment == segment ? 10 : 0,
                            x: 0,
                            y: selectedSegment == segment ? 4 : 0
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(Color.subtle, in: RoundedRectangle(cornerRadius: PSRadius.button, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PSRadius.button, style: .continuous)
                .stroke(Color.divider.opacity(0.70), lineWidth: 1)
        }
    }
}

private struct AssetSegmentControlPreview: View {
    @State private var selectedSegment: AssetSegment = .overview

    var body: some View {
        VStack(spacing: 20) {
            AssetSegmentControl(selectedSegment: $selectedSegment) { segment in
                selectedSegment = segment
            }

            AssetSegmentControl(selectedSegment: .constant(.rebalance)) { _ in }
        }
        .padding(24)
        .background(Color.canvas)
    }
}

#Preview("AssetSegmentControl") {
    AssetSegmentControlPreview()
}
