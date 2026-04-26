import SwiftUI

enum NewsroomCapsuleStyle: Equatable {
    case linked
    case skim

    var iconName: String {
        switch self {
        case .linked:
            return "wallet.pass.fill"
        case .skim:
            return "bookmark.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .linked:
            return .policyPurple
        case .skim:
            return .policyAmber
        }
    }
}

struct NewsroomCapsuleSection: View {
    let title: String
    let subtitle: String
    let items: [PolicyNewsItem]
    let style: NewsroomCapsuleStyle
    let onSelect: (PolicyNewsItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: style.iconName)
                    .foregroundStyle(style.accentColor)
                Text(title)
                    .font(.pretendard(15, weight: .semibold))
                    .foregroundStyle(Color.foreground)
            }

            Text(subtitle)
                .font(.pretendard(12, weight: .medium))
                .foregroundStyle(Color.mutedForeground)

            ForEach(items) { item in
                Button {
                    onSelect(item)
                } label: {
                    NewsroomCapsuleRow(item: item, accentColor: style.accentColor, style: style)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .glassCard()
    }
}

private struct NewsroomCapsuleRow: View {
    let item: PolicyNewsItem
    let accentColor: Color
    let style: NewsroomCapsuleStyle

    private var secondaryLine: String {
        switch style {
        case .linked:
            return item.newsroomRelationText
        case .skim:
            return item.newsroomCapsuleText
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Text(item.category.title)
                    .font(.pretendard(10, weight: .semibold))
                    .foregroundStyle(item.category.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .glassEffect(.regular.tint(item.category.color.opacity(0.16)), in: Capsule())

                Spacer()

                Text(item.relativePublishedText)
                    .font(.pretendard(10, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)
            }

            Text(item.title)
                .font(.pretendard(13, weight: .semibold))
                .foregroundStyle(Color.foreground)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: style == .linked ? "link.circle.fill" : "text.justify.left")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .padding(.top, 2)

                Text(secondaryLine)
                    .font(.pretendard(11, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text(item.sourceName)
                .font(.pretendard(10, weight: .medium))
                .foregroundStyle(Color.mutedForeground.opacity(0.9))
        }
        .padding(12)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
