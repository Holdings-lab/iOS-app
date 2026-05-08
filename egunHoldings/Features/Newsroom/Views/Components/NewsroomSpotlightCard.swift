import SwiftUI

struct NewsroomSpotlightCard: View {
    let item: PolicyNewsItem
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            KDXCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        // Eyebrow chip
                        Text("오늘 가장 중요한 브리핑")
                            .font(.pretendard(11, weight: .semibold))
                            .foregroundStyle(Color.brand)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.brandChipBg, in: RoundedRectangle(cornerRadius: KDXRadius.chip, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: KDXRadius.chip, style: .continuous)
                                    .stroke(Color.brand.opacity(0.2), lineWidth: 1)
                            }

                        Spacer()

                        Text(item.relativePublishedText)
                            .font(.pretendard(11, weight: .medium))
                            .foregroundStyle(Color.textQuaternary)
                    }

                    Text(item.title)
                        .font(.pretendard(18, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .tracking(-0.3)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(item.newsroomCapsuleText)
                        .font(.pretendard(12, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "briefcase.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(item.category.color)
                            .padding(.top, 2)

                        Text(item.newsroomRelationText)
                            .font(.pretendard(12, weight: .semibold))
                            .foregroundStyle(Color.textSecondary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack {
                        Text("\(item.sourceName) · \(item.category.title)")
                            .font(.pretendard(11, weight: .medium))
                            .foregroundStyle(Color.textQuaternary)
                        Spacer()
                        Text("압축 해설 보기")
                            .font(.pretendard(12, weight: .semibold))
                            .foregroundStyle(Color.brand)
                    }
                }
            }
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}
