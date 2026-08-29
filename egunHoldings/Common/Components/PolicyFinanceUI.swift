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

// Auth/onboarding background aligned with KODEX light surfaces.
struct PFGradientBackground: View {
    var body: some View {
        Color.canvas.ignoresSafeArea()
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
    private let locksHorizontalOverflow: Bool
    private let content: Content

    init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat = PFSpacing.section,
        horizontalPadding: CGFloat = PFSpacing.screenHorizontal,
        topPadding: CGFloat = 8,
        bottomPadding: CGFloat = 0,
        scrollsToTopOnAppear: Bool = false,
        locksHorizontalOverflow: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.horizontalPadding = horizontalPadding
        self.topPadding = topPadding
        self.bottomPadding = bottomPadding
        self.scrollsToTopOnAppear = scrollsToTopOnAppear
        self.locksHorizontalOverflow = locksHorizontalOverflow
        self.content = content()
    }

    var body: some View {
        if locksHorizontalOverflow {
            GeometryReader { geometry in
                scrollContent(width: max(0, geometry.size.width - horizontalPadding * 2))
            }
        } else {
            scrollContent(width: nil)
        }
    }

    private func scrollContent(width: CGFloat?) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: alignment, spacing: spacing) {
                    Color.clear.frame(height: 0).id("pfScrollTop")
                    content
                }
                .frame(width: width, alignment: Alignment(horizontal: alignment, vertical: .center))
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
                                .foregroundStyle(Color.textOnAccent)
                        }
                }
            }
    }
}
