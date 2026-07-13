import SwiftUI

struct PolSignalFlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        return CGSize(width: maxWidth, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX, currentX > bounds.minX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

enum PolSignalTagStyle {
    case semi
    case policy
    case rate
    case danger
    case warn
    case success
    case primary
    case neutral
    case custom(Color)

    var foreground: Color {
        switch self {
        case .semi:
            return PSColor.tagSemi
        case .policy:
            return PSColor.tagPolicy
        case .rate:
            return PSColor.tagRate
        case .danger:
            return PSColor.danger
        case .warn:
            return PSColor.warn
        case .success:
            return PSColor.success
        case .primary:
            return PSColor.primary
        case .neutral:
            return PSColor.textSecondary
        case .custom(let color):
            return color
        }
    }

    var background: Color {
        switch self {
        case .semi, .primary, .custom:
            return PSColor.primarySoft
        case .policy:
            return PSColor.tagPolicyBg
        case .rate, .neutral:
            return PSColor.tagRateBg
        case .danger:
            return PSColor.dangerBg
        case .warn:
            return PSColor.warnBg
        case .success:
            return PSColor.successBg
        }
    }
}

enum PolSignalBadgeStyle {
    case danger
    case warn
    case success
    case primary
    case rate

    var foreground: Color {
        switch self {
        case .danger:
            return PSColor.danger
        case .warn:
            return PSColor.warn
        case .success:
            return PSColor.success
        case .primary:
            return PSColor.primary
        case .rate:
            return PSColor.tagRate
        }
    }

    var background: Color {
        switch self {
        case .danger:
            return PSColor.dangerBg
        case .warn:
            return PSColor.warnBg
        case .success:
            return PSColor.successBg
        case .primary:
            return PSColor.primarySoft
        case .rate:
            return PSColor.tagRateBg
        }
    }
}

struct PolSignalTag: View {
    let text: String
    let style: PolSignalTagStyle
    var prominent = false

    var body: some View {
        Text(text)
            .font(.pretendard(13, weight: .medium))
            .foregroundStyle(prominent ? Color.white : style.foreground)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(prominent ? style.foreground : style.background, in: Capsule(style: .continuous))
    }
}

struct PolSignalBadge: View {
    let text: String
    let style: PolSignalBadgeStyle
    var inverted = false

    var body: some View {
        Text(text)
            .font(.pretendard(11, weight: .semibold))
            .foregroundStyle(inverted ? Color.white : style.foreground)
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(inverted ? style.foreground : style.background, in: RoundedRectangle(cornerRadius: PSRadius.badge, style: .continuous))
    }
}

struct PolSignalChip: View {
    let text: String
    let color: Color
    var isProminent = false

    var body: some View {
        PolSignalTag(text: text, style: .custom(color), prominent: isProminent)
    }
}

enum PolSignalCardVariant {
    case surface
    case tinted
    case surfaceAlt
    case danger
    case warn
}

struct PolSignalCard<Content: View>: View {
    let variant: PolSignalCardVariant
    let padding: EdgeInsets
    let content: Content

    init(
        variant: PolSignalCardVariant = .surface,
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        @ViewBuilder content: () -> Content
    ) {
        self.variant = variant
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background, in: RoundedRectangle(cornerRadius: PSRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PSRadius.card, style: .continuous)
                    .stroke(strokeColor, lineWidth: 1)
            }
            .shadow(color: PSColor.cardShadow, radius: 4, x: 0, y: 1)
    }

    private var background: Color {
        switch variant {
        case .surface:
            return PSColor.surface
        case .tinted:
            return PSColor.primarySoft
        case .surfaceAlt:
            return PSColor.surfaceAlt
        case .danger:
            return PSColor.dangerBg
        case .warn:
            return PSColor.warnBg
        }
    }

    private var strokeColor: Color {
        switch variant {
        case .surface:
            return PSColor.border
        case .tinted:
            return PSColor.primary.opacity(0.14)
        case .surfaceAlt:
            return PSColor.rule
        case .danger:
            return PSColor.danger.opacity(0.18)
        case .warn:
            return PSColor.warn.opacity(0.18)
        }
    }
}

struct PolSignalSectionHeader: View {
    let title: String
    let meta: String?
    let onMore: (() -> Void)?

    init(title: String, meta: String? = nil, onMore: (() -> Void)? = nil) {
        self.title = title
        self.meta = meta
        self.onMore = onMore
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.pretendard(17, weight: .semibold))
                .foregroundStyle(PSColor.textPrimary)

            Spacer(minLength: 12)

            if let meta {
                if let onMore {
                    Button(action: onMore) {
                        Text(meta)
                            .font(.pretendard(13, weight: .semibold))
                            .foregroundStyle(PSColor.primary)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(meta)
                        .font(.pretendard(12, weight: .semibold))
                        .foregroundStyle(PSColor.textFaint)
                }
            }
        }
    }
}

struct PolSignalSectionTitle: View {
    let title: String
    let caption: String?

    init(_ title: String, caption: String? = nil) {
        self.title = title
        self.caption = caption
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            PolSignalSectionHeader(title: title)
            if let caption {
                Text(caption)
                    .font(.pretendard(12, weight: .medium))
                    .foregroundStyle(PSColor.textFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct PolSignalAIBlock: View {
    let text: String
    var isExpanded = true
    var onTap: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "diamond.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(PSColor.primary)
                .padding(.top, 3)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text("AI 한줄 요약")
                        .font(.pretendard(12, weight: .bold))
                        .foregroundStyle(PSColor.primary)

                    Spacer(minLength: 0)

                    if onTap != nil {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(PSColor.primary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                }

                if isExpanded {
                    Text(text)
                        .font(.pretendard(14, weight: .regular))
                        .foregroundStyle(PSColor.textPrimary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
        .background(PSColor.primarySoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}

struct PolSignalCallout: View {
    enum Tone {
        case danger
        case warn
    }

    let title: String
    let message: String
    var tone: Tone = .danger

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: tone == .danger ? "exclamationmark.triangle.fill" : "bolt.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tint)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.pretendard(13, weight: .bold))
                    .foregroundStyle(PSColor.textPrimary)

                Text(message)
                    .font(.pretendard(13, weight: .regular))
                    .foregroundStyle(PSColor.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var tint: Color {
        tone == .danger ? PSColor.danger : PSColor.warn
    }

    private var background: Color {
        tone == .danger ? PSColor.dangerBg : PSColor.warnBg
    }
}

struct PolSignalButton: View {
    enum Style {
        case primary
        case secondary
        case ghost
    }

    let title: String
    let iconName: String?
    let style: Style
    var isSmall = false
    let action: () -> Void

    init(
        _ title: String,
        iconName: String? = nil,
        style: Style = .primary,
        isSmall: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.iconName = iconName
        self.style = style
        self.isSmall = isSmall
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.pretendard(isSmall ? 13 : 15, weight: .semibold))
                if let iconName {
                    Image(systemName: iconName)
                        .font(.system(size: isSmall ? 11 : 13, weight: .bold))
                }
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: isSmall ? 36 : 52)
            .background(background, in: RoundedRectangle(cornerRadius: PSRadius.button, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PSRadius.button, style: .continuous)
                    .stroke(border, lineWidth: style == .ghost ? 0 : 1)
            }
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    private var foreground: Color {
        switch style {
        case .primary:
            return Color.white
        case .secondary, .ghost:
            return PSColor.primary
        }
    }

    private var background: Color {
        switch style {
        case .primary:
            return PSColor.primary
        case .secondary:
            return PSColor.surface
        case .ghost:
            return Color.clear
        }
    }

    private var border: Color {
        style == .secondary ? PSColor.border : Color.clear
    }
}

struct PolSignalCompositionBar: View {
    struct Segment: Identifiable {
        let id = UUID()
        let percent: Double
        let color: Color
    }

    let segments: [Segment]

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                ForEach(segments) { segment in
                    Rectangle()
                        .fill(segment.color)
                        .frame(width: max(0, proxy.size.width * segment.percent / total))
                }
            }
            .clipShape(Capsule(style: .continuous))
        }
        .frame(height: 10)
        .background(PSColor.rule, in: Capsule(style: .continuous))
    }

    private var total: Double {
        max(segments.reduce(0) { $0 + $1.percent }, 1)
    }
}
