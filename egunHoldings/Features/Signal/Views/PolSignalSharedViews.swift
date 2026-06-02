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

struct PolSignalTodayBriefingView: View {
    let themeSignals: [PortfolioThemeSignal]
    var policyReadings: [PolSignalPolicyReading] = PolSignalFlowMockData.policyReadings
    let proposal: PolSignalAdjustmentProposal?
    /// "왜 그런지 알아보기" 탭 시 호출. 테마 단위 Signal 상세 화면으로 이동.
    let onThemeTap: (PortfolioThemeSignal.Theme) -> Void
    let onProposalTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ThemeSignalSection(
                signals: themeSignals,
                onFullAnalysis: onThemeTap
            )
            policyEventSection

            if let proposal {
                pendingProposalCard(proposal)
            }
        }
    }

    private var policyEventSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PolSignalSectionHeader(title: "오늘 읽을 정책 이벤트", meta: "\(policyReadings.count)건")

            VStack(spacing: 10) {
                ForEach(policyReadings) { event in
                    NavigationLink(value: PolSignalRoute.policyReader(event.id)) {
                        PolicyReadCard(event: event)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func pendingProposalCard(_ proposal: PolSignalAdjustmentProposal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            PolSignalSectionHeader(title: "대응 대기 중", meta: "1건")

            Button(action: onProposalTap) {
                PolSignalCard(variant: .tinted) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .center, spacing: 8) {
                            PolSignalTag(text: "조정 제안", style: .primary)
                            Text("09:20")
                                .font(.pretendard(12, weight: .medium))
                                .foregroundStyle(PSColor.textSecondary)
                            Spacer(minLength: 0)
                            Text("제안 보기 →")
                                .font(.pretendard(14, weight: .semibold))
                                .foregroundStyle(PSColor.primary)
                        }

                        Text(proposal.title)
                            .font(.pretendard(16, weight: .semibold))
                            .foregroundStyle(PSColor.textPrimary)
                            .lineLimit(2)

                        Text(proposal.allocationChanges.joined(separator: " · "))
                            .font(.pretendard(13, weight: .regular))
                            .foregroundStyle(PSColor.textSecondary)
                    }
                }
            }
            .buttonStyle(PressScaleButtonStyle())
        }
    }

}

struct PolicyReadCard: View {
    let event: PolSignalPolicyReading

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            metaRow

            Text(event.title)
                .font(.pretendard(18, weight: .semibold, relativeTo: .headline))
                .foregroundStyle(PSColor.textPrimary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            lensTag

            PolSignalDashedRule()
                .stroke(PSColor.Reader.border, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .frame(height: 1)
                .padding(.vertical, 2)

            HStack(alignment: .center, spacing: 10) {
                Label("읽기 \(event.readMinutes)분", systemImage: "clock")
                    .font(.pretendard(13, weight: .medium, relativeTo: .caption))
                    .foregroundStyle(PSColor.Reader.chipText)
                    .labelStyle(.titleAndIcon)

                Spacer(minLength: 12)

                HStack(spacing: 4) {
                    Text("읽으러 가기")
                        .font(.pretendard(13, weight: .semibold, relativeTo: .caption))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(PSColor.Reader.lensText)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PSColor.Reader.surface, in: RoundedRectangle(cornerRadius: PSRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PSRadius.card, style: .continuous)
                .stroke(PSColor.Reader.border, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("두 번 탭하면 읽기 페이지가 열립니다")
    }

    private var metaRow: some View {
        PolSignalFlowLayout(spacing: 6) {
            ForEach(event.keywords, id: \.self) { keyword in
                PolSignalReaderKeywordChip(text: "#\(keyword)")
            }

            Text("· \(event.institution)")
                .font(.pretendard(12, weight: .medium, relativeTo: .caption))
                .foregroundStyle(PSColor.textSecondary)

            Text("· \(event.dDay)")
                .font(.pretendard(12, weight: .medium, relativeTo: .caption))
                .foregroundStyle(PSColor.textSecondary)
        }
    }

    private var lensTag: some View {
        HStack(spacing: 6) {
            Image(systemName: "lightbulb")
                .font(.system(size: 12, weight: .semibold))
            Text(event.readingLens)
                .font(.pretendard(12, weight: .semibold, relativeTo: .caption))
                .lineLimit(1)
        }
        .foregroundStyle(PSColor.Reader.lensText)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(PSColor.Reader.lensBg, in: Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .stroke(PSColor.Reader.lensBorder, lineWidth: 1)
        }
    }
}

struct PolSignalReaderKeywordChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.pretendard(12, weight: .semibold, relativeTo: .caption))
            .foregroundStyle(PSColor.Reader.chipText)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(PSColor.Reader.chipBg, in: Capsule(style: .continuous))
    }
}

struct PolSignalDashedRule: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

/// 초보자용 상태 배지 (지켜봐요 / 조심하세요 / 대응하세요).
/// 접힌 Top 3 행과 펼친 카드 상단에서 공통으로 사용.
struct SentimentPill: View {
    let kind: PolSignalVerdictKind

    var body: some View {
        Text(kind.sentimentLabel)
            .font(.pretendard(11, weight: .bold))
            .foregroundStyle(kind.sentimentForeground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(kind.sentimentSoft, in: Capsule(style: .continuous))
            .fixedSize()
    }
}

private struct PolSignalVerdictRow: View {
    let event: PolSignalEvent
    let isExpanded: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(event.exposures.first?.ticker ?? event.category)
                .font(.pretendard(12, weight: .bold))
                .foregroundStyle(PSColor.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(width: 44, height: 44)
                .background(PSColor.primarySoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.pretendard(15, weight: .semibold))
                    .foregroundStyle(PSColor.textPrimary)
                    .lineLimit(1)

                Text(event.sourceSummary)
                    .font(.pretendard(13, weight: .regular))
                    .foregroundStyle(PSColor.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            SentimentPill(kind: event.verdictKind)

            PolSignalExpandChevron(isExpanded: isExpanded)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

struct PolSignalVerdictBadge: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.pretendard(11, weight: .semibold))
            .foregroundStyle(PSColor.primary)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(PSColor.primarySoft, in: RoundedRectangle(cornerRadius: PSRadius.badge, style: .continuous))
    }
}

private struct PolSignalExpandChevron: View {
    let isExpanded: Bool

    var body: some View {
        Image(systemName: "chevron.down")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(isExpanded ? PSColor.primary : PSColor.textFaint)
            .rotationEffect(.degrees(isExpanded ? 180 : 0))
    }
}

// 오늘 탭 카드 확장: 상태 배지 + 상황 요약(평어) + 처방 블록 + Signal 이동 링크
private struct TodayDecisionExpansion: View {
    let event: PolSignalEvent
    let onFullAnalysis: () -> Void

    private var summary: String { event.prescription?.summary ?? event.expectedImpact }
    private var action: String { event.prescription?.action ?? event.verdict }
    private var nowPercent: String? { event.prescription?.nowPercent ?? event.exposures.first?.weightText }
    private var goalLabel: String? { event.prescription?.goalLabel }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // ① 상태 배지
            SentimentPill(kind: event.verdictKind)

            // ② 상황 한 줄 (평어, 최대 2줄)
            Text(summary)
                .font(.pretendard(13, weight: .regular))
                .foregroundStyle(PSColor.textSecondary)
                .lineLimit(2)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            // ③ 처방 블록
            prescriptionBlock

            // ④ Signal 탭 이동
            Button(action: onFullAnalysis) {
                HStack(spacing: 4) {
                    Text("왜 그런지 알아보기")
                        .font(.pretendard(13, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(PSColor.primary)
                .padding(.vertical, 12)
                .padding(.horizontal, 4)
                .frame(minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(event.verdictKind.sentimentSoft.opacity(0.6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(event.verdictKind.sentimentForeground.opacity(0.18), lineWidth: 1)
        }
    }

    private var prescriptionBlock: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(event.verdictKind.prescriptionIconColor)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 8) {
                Text(action)
                    .font(.pretendard(15, weight: .bold))
                    .foregroundStyle(PSColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)

                if let now = nowPercent {
                    HStack(spacing: 10) {
                        Text("지금 \(now)")
                            .font(.pretendard(12, weight: .medium).monospacedDigit())
                            .foregroundStyle(PSColor.textSecondary)

                        if let goal = goalLabel {
                            Text("→")
                                .font(.pretendard(13, weight: .semibold))
                                .foregroundStyle(PSColor.textFaint)

                            Text(goal)
                                .font(.pretendard(12, weight: .semibold).monospacedDigit())
                                .foregroundStyle(PSColor.primary)
                        }
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(event.verdictKind.sentimentSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct PolSignalAssetSnapshotView: View {
    let summary: PolSignalAssetSummary
    let proposal: PolSignalAdjustmentProposal?
    let onProposalTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let proposal {
                proposalBanner(proposal)
            }

            totalAssetSection
            riskSection
            themeExposureSection
        }
    }

    private func proposalBanner(_ proposal: PolSignalAdjustmentProposal) -> some View {
        Button(action: onProposalTap) {
            PolSignalCard(variant: .tinted) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        PolSignalTag(text: "조정 제안", style: .primary)
                        Text("1건 대기")
                            .font(.pretendard(12, weight: .medium))
                            .foregroundStyle(PSColor.textSecondary)
                        Spacer(minLength: 0)
                        Text("제안 보기 →")
                            .font(.pretendard(14, weight: .semibold))
                            .foregroundStyle(PSColor.primary)
                    }

                    Text(proposal.title)
                        .font(.pretendard(17, weight: .semibold))
                        .foregroundStyle(PSColor.textPrimary)
                        .lineLimit(2)

                    Text(proposal.allocationChanges.joined(separator: " · "))
                        .font(.pretendard(13, weight: .regular))
                        .foregroundStyle(PSColor.textSecondary)
                }
            }
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    private var totalAssetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PolSignalSectionHeader(title: "총 자산")

            PolSignalCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("총 자산")
                            .font(.pretendard(13, weight: .regular))
                            .foregroundStyle(PSColor.textSecondary)

                        Spacer()

                        PolSignalBadge(text: "↑ \(summary.returnBadgeText)", style: .success)
                    }

                    Text(summary.totalAssetText)
                        .font(.pretendard(30, weight: .bold))
                        .foregroundStyle(PSColor.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .monospacedDigit()

                    PolSignalCompositionBar(
                        segments: summary.composition.map {
                            PolSignalCompositionBar.Segment(percent: $0.percent, color: $0.color)
                        }
                    )

                    PolSignalFlowLayout(spacing: 12) {
                        ForEach(summary.composition) { item in
                            HStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(item.color)
                                    .frame(width: 10, height: 10)

                                Text(item.title)
                                    .font(.pretendard(12, weight: .medium))
                                    .foregroundStyle(PSColor.textSecondary)

                                Text("\(Int(item.percent))%")
                                    .font(.pretendard(12, weight: .semibold))
                                    .foregroundStyle(PSColor.textPrimary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var riskSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PolSignalSectionHeader(title: "포트폴리오 위험 신호", meta: "\(summary.riskAlerts.count)건")

            VStack(spacing: 10) {
                ForEach(summary.riskAlerts) { alert in
                    PolSignalRiskRow(alert: alert)
                }
            }
        }
    }

    private var themeExposureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PolSignalSectionHeader(title: "주요 테마 노출")

            PolSignalCard(padding: EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)) {
                VStack(spacing: 0) {
                    ForEach(Array(summary.themeExposures.enumerated()), id: \.element.id) { index, item in
                        HStack(spacing: 12) {
                            Text(item.title)
                                .font(.pretendard(14, weight: .medium))
                                .foregroundStyle(PSColor.textPrimary)
                                .frame(width: 80, alignment: .leading)
                                .lineLimit(1)

                            GeometryReader { proxy in
                                ZStack(alignment: .leading) {
                                    Capsule(style: .continuous)
                                        .fill(PSColor.rule)
                                    Capsule(style: .continuous)
                                        .fill(item.color)
                                        .frame(width: max(0, proxy.size.width * item.percent / 100))
                                }
                            }
                            .frame(height: 8)

                            Text("\(Int(item.percent))%")
                                .font(.pretendard(14, weight: .semibold))
                                .foregroundStyle(PSColor.textPrimary)
                                .frame(width: 36, alignment: .trailing)
                                .monospacedDigit()
                        }
                        .padding(.vertical, 12)

                        if index < summary.themeExposures.count - 1 {
                            Divider().background(PSColor.rule)
                        }
                    }
                }
            }
        }
    }
}

private struct PolSignalRiskRow: View {
    let alert: PolSignalRiskAlert

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Rectangle()
                .fill(alert.color)
                .frame(width: 4)
                .clipShape(Capsule(style: .continuous))

            Image(systemName: alert.severity == .red ? "exclamationmark.triangle.fill" : "bolt.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(alert.color)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(alert.title)
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(PSColor.textPrimary)
                    .lineLimit(1)

                Text(alert.detail)
                    .font(.pretendard(12, weight: .regular))
                    .foregroundStyle(PSColor.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(PSColor.textFaint)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alert.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(Rectangle())
    }
}
