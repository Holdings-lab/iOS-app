import SwiftUI

enum PFSpacing {
    static let screenHorizontal: CGFloat = 16
    static let section: CGFloat = 20
    static let item: CGFloat = 12
    static let flowBottomInset: CGFloat = 96
}

enum PFRadius {
    static let card: CGFloat = 16
    static let button: CGFloat = 14
}

// Legacy gradient background — auth/onboarding only
struct PFGradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color.midnightTop, Color.midnightBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

struct PFStepHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.pretendard(30, weight: .bold))
                .foregroundStyle(Color.midnightTextPrimary)

            Text(subtitle)
                .font(.pretendard(15, weight: .medium))
                .foregroundStyle(Color.midnightTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// KODEX light progress bar (replaces legacy midnight version)
struct PFProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            let clampedProgress = max(0, min(progress, 1))
            let width = proxy.size.width * clampedProgress

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color.kdxDivider)

                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.brand, Color.brandLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width)
            }
        }
        .frame(height: 6)
    }
}

struct PFInlineErrorText: View {
    let message: String
    var alignment: Alignment = .leading

    var body: some View {
        Text(message)
            .font(.pretendard(13, weight: .medium))
            .foregroundStyle(Color.up)
            .frame(maxWidth: .infinity, alignment: alignment)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct PFContentScrollView<Content: View>: View {
    private let alignment: HorizontalAlignment
    private let spacing: CGFloat
    private let horizontalPadding: CGFloat
    private let topPadding: CGFloat
    private let bottomPadding: CGFloat
    private let scrollsToTopOnAppear: Bool
    private let content: Content

    init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat = PFSpacing.section,
        horizontalPadding: CGFloat = PFSpacing.screenHorizontal,
        topPadding: CGFloat = 8,
        bottomPadding: CGFloat = 0,
        scrollsToTopOnAppear: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.horizontalPadding = horizontalPadding
        self.topPadding = topPadding
        self.bottomPadding = bottomPadding
        self.scrollsToTopOnAppear = scrollsToTopOnAppear
        self.content = content()
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: alignment, spacing: spacing) {
                    Color.clear.frame(height: 0).id("pfScrollTop")
                    content
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
            }
            .onAppear {
                if scrollsToTopOnAppear {
                    proxy.scrollTo("pfScrollTop", anchor: .top)
                }
            }
        }
    }
}

// KODEX light surface card — white bg + hairline border, no shadow
struct PFSurfaceCard<Content: View>: View {
    private let padding: CGFloat
    private let cornerRadius: CGFloat
    private let selected: Bool
    private let selectedTint: Color
    private let content: Content

    init(
        padding: CGFloat = 16,
        cornerRadius: CGFloat = KDXRadius.card,
        selected: Bool = false,
        selectedTint: Color = .brand,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.selected = selected
        self.selectedTint = selectedTint
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(Color.elevated, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        selected ? selectedTint.opacity(0.5) : Color.hairline,
                        lineWidth: 1
                    )
            }
    }
}

extension View {
    func policyFinanceNavigationChrome(bottomInset: CGFloat = 90) -> some View {
        safeAreaPadding(.bottom, bottomInset)
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
    }

    // Light version — canvas background
    func policyFinanceLightTabChrome(bottomInset: CGFloat = 90) -> some View {
        policyFinanceNavigationChrome(bottomInset: bottomInset)
            .background(Color.canvas.ignoresSafeArea())
    }

    // Keep old name as alias so existing call sites compile without changes
    func policyFinanceDarkTabChrome(bottomInset: CGFloat = 90) -> some View {
        policyFinanceLightTabChrome(bottomInset: bottomInset)
    }
}

struct PFSelectionIndicator: View {
    let isSelected: Bool
    let tint: Color
    var size: CGFloat = 28

    var body: some View {
        Circle()
            .stroke(Color.hairline, lineWidth: 2)
            .frame(width: size, height: size)
            .overlay {
                if isSelected {
                    Circle()
                        .fill(tint)
                        .overlay {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                        }
                }
            }
    }
}
