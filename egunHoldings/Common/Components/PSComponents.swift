import SwiftUI

// MARK: - PSGlassCard

struct PSGlassCard<Content: View>: View {
    enum Variant {
        case primary
        case secondary
        case tinted(Color)
    }

    let variant: Variant
    let padding: CGFloat
    let content: Content

    init(
        variant: Variant = .primary,
        padding: CGFloat = PSSpacing.cardPad,
        @ViewBuilder content: () -> Content
    ) {
        self.variant = variant
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: PSRadius.card, style: .continuous)
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(bgFill, in: shape)
            .overlay { shape.stroke(Color.divider.opacity(0.55), lineWidth: 1) }
            .shadow(
                color: PSShadow.cardColor,
                radius: PSShadow.cardBlur,
                x: 0,
                y: PSShadow.cardYOffset
            )
    }

    private var bgFill: Color {
        switch variant {
        case .primary:       return Color.elevated
        case .secondary:     return Color.elevated
        case .tinted:        return Color.elevated
        }
    }
}

// MARK: - StatusChip

struct PSStatusChip: View {
    let label: String
    let color: Color
    var bgOpacity: Double = 0.12
    var isSelected: Bool = false

    var body: some View {
        Text(label)
            .font(PSFont.caption())
            .foregroundStyle(isSelected ? Color.textOnAccent : Color.textSecondary)
            .frame(minWidth: 48)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(fill, in: Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .stroke(isSelected ? Color.clear : Color.divider.opacity(0.70), lineWidth: 1)
            }
            .contentShape(Capsule(style: .continuous))
    }

    private var fill: Color {
        isSelected ? Color.brand : Color.clear
    }
}

// MARK: - JudgmentType + Badge

enum JudgmentType: String {
    case confirm  = "확인"
    case wait     = "대기"
    case defend   = "방어"
    case simulate = "모의반영"

    var color: Color {
        switch self {
        case .confirm:  return Color.brand
        case .wait:     return Color.warning
        case .defend:   return Color.up
        case .simulate: return Color.success
        }
    }

    var symbol: String {
        switch self {
        case .confirm:  return "checkmark.circle.fill"
        case .wait:     return "pause.circle.fill"
        case .defend:   return "shield.lefthalf.filled"
        case .simulate: return "arrow.triangle.2.circlepath"
        }
    }
}

struct JudgmentTypeBadge: View {
    let type: JudgmentType

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: type.symbol)
                .font(.system(size: 10, weight: .semibold))
            Text(type.rawValue)
                .font(PSFont.semibold(11))
        }
        .foregroundStyle(type.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(type.color.opacity(0.12), in: RoundedRectangle(cornerRadius: KDXRadius.chip, style: .continuous))
    }
}

// MARK: - ExposureBar

struct PSExposureBar: View {
    let theme: String
    let pct: Int
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Text(theme)
                .font(PSFont.caption())
                .foregroundStyle(PSColor.textMuted)
                .frame(width: 64, alignment: .leading)
                .lineLimit(1)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.divider)
                        .frame(height: 6)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [color, Color.brandLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * CGFloat(pct) / 100), height: 6)
                }
            }
            .frame(height: 6)

            Text("\(pct)%")
                .font(PSFont.semibold(12))
                .foregroundStyle(color)
                .frame(width: 36, alignment: .trailing)
                .monospacedDigit()
        }
    }
}

// MARK: - PolicyColorDot

struct PolicyColorDot: View {
    let color: Color
    var size: CGFloat = 6

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
    }
}

// MARK: - PolSignalLogo

struct PolSignalLogo: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let cx = w / 2, cy = h / 2

            var shield = Path()
            shield.move(to: CGPoint(x: cx, y: 2))
            shield.addCurve(
                to: CGPoint(x: w - 2, y: h * 0.36),
                control1: CGPoint(x: w * 0.82, y: 2),
                control2: CGPoint(x: w - 2, y: h * 0.14)
            )
            shield.addLine(to: CGPoint(x: w - 2, y: h * 0.54))
            shield.addCurve(
                to: CGPoint(x: cx, y: h - 2),
                control1: CGPoint(x: w - 2, y: h * 0.78),
                control2: CGPoint(x: w * 0.74, y: h * 0.92)
            )
            shield.addCurve(
                to: CGPoint(x: 2, y: h * 0.54),
                control1: CGPoint(x: w * 0.26, y: h * 0.92),
                control2: CGPoint(x: 2, y: h * 0.78)
            )
            shield.addLine(to: CGPoint(x: 2, y: h * 0.36))
            shield.addCurve(
                to: CGPoint(x: cx, y: 2),
                control1: CGPoint(x: 2, y: h * 0.14),
                control2: CGPoint(x: w * 0.18, y: 2)
            )
            shield.closeSubpath()

            ctx.fill(shield, with: .color(Color.brandTintBg))
            ctx.stroke(shield, with: .color(Color.brand.opacity(0.5)), lineWidth: 1)

            let r: CGFloat = 3
            ctx.fill(
                Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)),
                with: .color(Color.brand)
            )

            var arc1 = Path()
            arc1.addArc(center: CGPoint(x: cx, y: cy), radius: w * 0.30,
                        startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
            ctx.stroke(arc1, with: .color(Color.brand), lineWidth: 1.5)

            var arc2 = Path()
            arc2.addArc(center: CGPoint(x: cx, y: cy), radius: w * 0.42,
                        startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
            ctx.stroke(arc2, with: .color(Color.brandLight), lineWidth: 1)
        }
        .frame(width: 28, height: 28)
    }
}

// MARK: - PSPressStyle

struct PSPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.smooth(duration: 0.14), value: configuration.isPressed)
    }
}

// MARK: - PSGradientButton

struct PSGradientButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(PSFont.semibold(15))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.brand, Color.brandDark],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: KDXRadius.button, style: .continuous)
                )
        }
        .buttonStyle(PSPressStyle())
    }
}

#Preview("PSGlassCard + PSStatusChip") {
    VStack(alignment: .leading, spacing: PSSpacing.sectionGap) {
        PSGlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Portfolio Balance")
                    .font(PSFont.caption())
                    .foregroundStyle(PSColor.textSecondary)
                Text("$97,326.46")
                    .font(PSFont.display())
                    .foregroundStyle(PSColor.textPrimary)
            }
        }

        HStack(spacing: PSSpacing.pillGap) {
            PSStatusChip(label: "1D", color: Color.brand)
            PSStatusChip(label: "1W", color: Color.brand, isSelected: true)
            PSStatusChip(label: "1M", color: Color.brand)
            PSStatusChip(label: "1Y", color: Color.brand)
        }
    }
    .padding(24)
    .background(Color.canvas)
}
