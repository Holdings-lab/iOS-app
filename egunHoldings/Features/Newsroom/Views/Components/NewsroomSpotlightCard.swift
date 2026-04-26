import SwiftUI

struct NewsroomSpotlightCard: View {
    let item: PolicyNewsItem
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("오늘 가장 중요한 브리핑")
                        .font(.pretendard(11, weight: .semibold))
                        .foregroundStyle(Color.electricBlue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .glassEffect(.regular.tint(Color.electricBlue.opacity(0.18)), in: Capsule())

                    Spacer()

                    Text(item.relativePublishedText)
                        .font(.pretendard(11, weight: .medium))
                        .foregroundStyle(Color.mutedForeground)
                }

                Text(item.title)
                    .font(.pretendard(18, weight: .bold))
                    .foregroundStyle(Color.foreground)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(item.newsroomCapsuleText)
                    .font(.pretendard(12, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "briefcase.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(item.category.color)
                        .padding(.top, 2)

                    Text(item.newsroomRelationText)
                        .font(.pretendard(12, weight: .semibold))
                        .foregroundStyle(Color.foreground)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack {
                    Text("\(item.sourceName) · \(item.category.title)")
                        .font(.pretendard(11, weight: .medium))
                        .foregroundStyle(Color.mutedForeground)
                    Spacer()
                    Text("압축 해설 보기")
                        .font(.pretendard(12, weight: .semibold))
                        .foregroundStyle(Color.electricBlue)
                }
            }
            .padding(16)
            .glassCard()
        }
        .buttonStyle(.plain)
    }
}
