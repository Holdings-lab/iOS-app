import SwiftUI

struct AssetSegmentControl: View {
    @Binding var selectedSegment: AssetSegment
    let onSelect: (AssetSegment) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AssetSegment.allCases) { segment in
                Button {
                    onSelect(segment)
                } label: {
                    Text(segment.displayTitle)
                        .font(.pretendard(12, weight: .semibold))
                        .foregroundStyle(selectedSegment == segment ? Color.electricBlue : Color.mutedForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedSegment == segment ? Color.electricBlue.opacity(0.15) : .clear,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.muted, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }
}
