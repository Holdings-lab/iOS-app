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
            .background {
                ZStack(alignment: .top) {
                    shape.fill(bgFill)
                    shape.fill(
                        LinearGradient(
                            colors: [glowColor, .clear],
                            startPoint: .top,
                            endPoint: UnitPoint(x: 0.5, y: 0.1)
                        )
                    )
                }
            }
            .clipShape(shape)
            .overlay { shape.stroke(PSColor.border, lineWidth: 0.5) }
            .glassEffect(.regular.tint(tintColor), in: shape)
    }

    private var bgFill: Color {
        switch variant {
        case .primary:          return PSColor.bgCardSub
        case .secondary:        return PSColor.bgCardMuted
        case .tinted(let c):    return c.opacity(0.04)
        }
    }

    private var glowColor: Color {
        switch variant {
        case .primary:          return .white.opacity(0.07)
        case .secondary:        return .white.opacity(0.05)
        case .tinted(let c):    return c.opacity(0.10)
        }
    }

    private var tintColor: Color {
        switch variant {
        case .primary, .secondary: return .white.opacity(0.02)
        case .tinted(let c):       return c.opacity(0.04)
        }
    }
}

// MARK: - StatusChip

struct PSStatusChip: View {
    let label: String
    let color: Color
    var bgOpacity: Double = 0.12

    var body: some View {
        Text(label)
            .font(PSFont.caption())
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(bgOpacity), in: Capsule())
            .overlay { Capsule().stroke(color.opacity(0.2), lineWidth: 0.5) }
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
        case .confirm:  return PSColor.electricBlue
        case .wait:     return PSColor.purple
        case .defend:   return PSColor.red
        case .simulate: return PSColor.emerald
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
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(type.color.opacity(0.12), in: Capsule())
        .overlay { Capsule().stroke(type.color.opacity(0.22), lineWidth: 0.5) }
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
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 5)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.5), color.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * CGFloat(pct) / 100), height: 5)
                        .shadow(color: color.opacity(0.3), radius: 4)
                }
            }
            .frame(height: 5)

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

            ctx.fill(shield, with: .color(Color.electricBlue.opacity(0.15)))
            ctx.stroke(shield, with: .color(Color.electricBlue.opacity(0.5)), lineWidth: 1)

            let r: CGFloat = 3
            ctx.fill(
                Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)),
                with: .color(Color.electricBlue.opacity(0.7))
            )

            var arc1 = Path()
            arc1.addArc(center: CGPoint(x: cx, y: cy), radius: w * 0.30,
                        startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
            ctx.stroke(arc1, with: .color(Color.electricBlue.opacity(0.7)), lineWidth: 1.5)

            var arc2 = Path()
            arc2.addArc(center: CGPoint(x: cx, y: cy), radius: w * 0.42,
                        startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
            ctx.stroke(arc2, with: .color(Color.electricBlue.opacity(0.4)), lineWidth: 1)
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
                        colors: [PSColor.electricBlue, PSColor.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: PSRadius.inner, style: .continuous)
                )
        }
        .buttonStyle(PSPressStyle())
    }
}
