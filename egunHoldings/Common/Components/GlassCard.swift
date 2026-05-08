import SwiftUI

// KODEX light card — white bg + 1px hairline, no shadow, no glass blur
struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.elevated, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                    .stroke(Color.hairline, lineWidth: 1)
            }
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCard())
    }
}

struct SoftGlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.subtle, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                    .stroke(Color.hairline, lineWidth: 1)
            }
    }
}

extension View {
    func softGlassCard() -> some View {
        modifier(SoftGlassCard())
    }
}

// KODEX light card — white bg, 1px hairline border, 16pt radius, no shadow.
struct KDXCard<Content: View>: View {
    let padding: EdgeInsets
    let content: Content

    init(
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)

        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.elevated, in: shape)
            .overlay { shape.stroke(Color.hairline, lineWidth: 1) }
    }
}

// Subtle inner box — used inside KDXCard for secondary info.
struct KDXInnerBox<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.subtle, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.hairline, lineWidth: 1)
            }
    }
}

struct KDXEyebrow: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.pretendard(11, weight: .semibold))
            .foregroundStyle(Color.brand)
    }
}

struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.smooth(duration: 0.16), value: configuration.isPressed)
    }
}
