import SwiftUI

struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.elevated, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                    .stroke(Color.hairline, lineWidth: 1)
            }
            // radius 4 / y 1은 ThemeSignalCard·AssetView 등 다른 카드들과 맞춘 값이다.
            // 이전의 radius 24는 오프스크린 블러 렌더 패스 비용이 크고, 다른 카드와 톤도 달랐다.
            .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 1)
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
            // radius 4 / y 1은 ThemeSignalCard·AssetView 등 다른 카드들과 맞춘 값이다.
            // 이전의 radius 24는 오프스크린 블러 렌더 패스 비용이 크고, 다른 카드와 톤도 달랐다.
            .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 1)
    }
}

struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.smooth(duration: 0.16), value: configuration.isPressed)
    }
}
