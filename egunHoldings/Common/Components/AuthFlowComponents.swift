import SwiftUI

private enum FlowTheme {
    static let accentStart = Color(hex: "7C6FFF")
    static let accentEnd = Color(hex: "5BBBFF")
    static let cardBackground = Color.white.opacity(0.06)
    static let cardBorder = Color.white.opacity(0.09)
    static let track = Color.white.opacity(0.10)
    static let disabledBackground = Color(hex: "2C344A")
    static let disabledText = Color.white.opacity(0.34)
    static let sparkleBackground = Color(hex: "1A1040")
    static let sparkleBorder = Color(hex: "7C6FFF", alpha: 0.30)
    static let logoWaveGradient = LinearGradient(
        colors: [Color.midnightAccent, Color.electricBlue, Color.policyCyan],
        startPoint: .leading,
        endPoint: .trailing
    )
}

struct FlowPrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.pretendard(17, weight: .semibold))
                .foregroundStyle(isEnabled ? Color.white : FlowTheme.disabledText)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(buttonBackground)
                )
        }
        .buttonStyle(.plain)
        .allowsHitTesting(isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }

    private var buttonBackground: AnyShapeStyle {
        if isEnabled {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [FlowTheme.accentStart, FlowTheme.accentEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        return AnyShapeStyle(FlowTheme.disabledBackground)
    }
}

struct FlowProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            let clampedProgress = max(0, min(progress, 1))

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(FlowTheme.track)

                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [FlowTheme.accentStart, FlowTheme.accentEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: proxy.size.width * clampedProgress)
                    .animation(.easeInOut(duration: 0.4), value: clampedProgress)
            }
        }
        .frame(height: 3)
    }
}

struct FlowSurfaceCard<Content: View>: View {
    private let padding: CGFloat
    private let cornerRadius: CGFloat
    private let content: Content

    init(
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                FlowTheme.cardBackground,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(FlowTheme.cardBorder, lineWidth: 1)
            }
    }
}

struct SignalDemoCard: View {
    let label: String
    let title: String
    let impactText: String
    let percentageText: String
    let subtitle: String

    var body: some View {
        FlowSurfaceCard(padding: 18, cornerRadius: 12) {
            VStack(alignment: .leading, spacing: 14) {
                Text(label)
                    .font(.pretendard(12, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.58))

                Text(title)
                    .font(.pretendard(24, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.92))

                Rectangle()
                    .fill(Color.white.opacity(0.09))
                    .frame(height: 1)

                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    Text(impactText)
                        .font(.pretendard(20, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.92))

                    Spacer(minLength: 12)

                    Text(percentageText)
                        .font(.pretendard(28, weight: .bold))
                        .foregroundStyle(FlowTheme.accentStart)
                }

                Text(subtitle)
                    .font(.pretendard(13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.62))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct SparkleAnimationView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity = 0.0
    @State private var hasAnimated = false

    var body: some View {
        ZStack {
            Circle()
                .fill(FlowTheme.sparkleBackground)
                .overlay {
                    Circle()
                        .stroke(FlowTheme.sparkleBorder, lineWidth: 1)
                }

            Text("✦")
                .font(.pretendard(24, weight: .bold))
                .foregroundStyle(FlowTheme.accentStart)
        }
        .frame(width: 56, height: 56)
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            guard !hasAnimated else { return }
            hasAnimated = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 0.34)) {
                    scale = 1.2
                    opacity = 1
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
                    withAnimation(.easeInOut(duration: 0.26)) {
                        scale = 1
                    }
                }
            }
        }
    }
}

struct CompletionCheckAnimationView: View {
    @State private var circleScale: CGFloat = 0.88
    @State private var circleOpacity = 0.0
    @State private var checkTrim = 0.0
    @State private var glowOpacity = 0.0
    @State private var hasAnimated = false

    var body: some View {
        ZStack {
            Circle()
                .fill(FlowTheme.sparkleBackground)
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }
                .overlay {
                    Circle()
                        .stroke(FlowTheme.logoWaveGradient, lineWidth: 1.6)
                        .opacity(glowOpacity)
                        .blur(radius: 1.2)
                }

            CheckmarkShape()
                .trim(from: 0, to: checkTrim)
                .stroke(
                    FlowTheme.logoWaveGradient,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                )
                .frame(width: 24, height: 18)
        }
        .frame(width: 56, height: 56)
        .scaleEffect(circleScale)
        .opacity(circleOpacity)
        .onAppear {
            guard !hasAnimated else { return }
            hasAnimated = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.easeOut(duration: 0.32)) {
                    circleScale = 1.04
                    circleOpacity = 1
                    glowOpacity = 1
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                    withAnimation(.easeInOut(duration: 0.42)) {
                        circleScale = 1
                        checkTrim = 1
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.46) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        glowOpacity = 0.82
                    }
                }
            }
        }
    }
}

private struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.56))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.42, y: rect.minY + rect.height * 0.86))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.88, y: rect.minY + rect.height * 0.18))

        return path
    }
}

struct FlowInfoHint: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.pretendard(12, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.52))
    }
}

struct FlowSummaryRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.52))
                .frame(width: 74, alignment: .leading)

            Text(value)
                .font(.pretendard(14, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.88))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
