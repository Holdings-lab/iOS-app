import SwiftUI

nonisolated enum PSColor {
    // Stockit Light aliases kept for existing PolSignal views.
    static let background = Color.canvas
    static let surface    = Color.elevated

    static let bgDeepNavy  = Color.canvas
    static let bgCard      = Color.elevated
    static let bgCardSub   = Color.subtle
    static let bgCardMuted = Color.muted

    static let primaryBlue        = Color.brand
    static let primaryBluePressed = Color.brandDark
    static let electricBlue = Color.brand
    static let blueSubtle   = Color.brandLight
    static let purple       = Color.brandDark
    static let emerald      = Color.success
    static let yellow       = Color.warning
    static let red          = Color.trendDown
    static let cyan         = Color.brandLight
    static let gray         = Color.textTertiary
    static let trendUp      = Color.trendUp
    static let trendDown    = Color.trendDown

    static let textPrimary = Color.textPrimary
    static let textSecondary = Color.textSecondary
    static let textMuted   = Color.textSecondary
    static let textFaint   = Color.textQuaternary

    static let border       = Color.hairline
    static let borderStrong = Color.divider
    static let divider      = Color.divider
    static let cardShadow   = Color.cardShadow
}

enum PSRadius {
    static let card: CGFloat  = 20
    static let inner: CGFloat = 14
    static let small: CGFloat = 14
    static let chip: CGFloat  = 999
    static let pill: CGFloat  = 999
    static let button: CGFloat = 14
}

enum PSSpacing {
    static let pagePad: CGFloat    = 20
    static let screenHorizontal: CGFloat = 20
    static let sectionGap: CGFloat = 24
    static let cardPad: CGFloat    = 20
    static let cardPadding: CGFloat = 20
    static let itemGap: CGFloat    = 16
    static let pillGap: CGFloat    = 8
}

enum PSFont {
    static let displayTracking: CGFloat = -0.5

    static func display(_ size: CGFloat = 34)  -> Font { .pretendard(size, weight: .bold) }
    static func title(_ size: CGFloat = 18)    -> Font { .pretendard(size, weight: .semibold) }
    static func body(_ size: CGFloat = 15)     -> Font { .pretendard(size, weight: .regular) }
    static func semibold(_ size: CGFloat = 14) -> Font { .pretendard(size, weight: .semibold) }
    static func caption(_ size: CGFloat = 13)  -> Font { .pretendard(size, weight: .medium) }
    static func tickerLabel(_ size: CGFloat = 16) -> Font { .pretendard(size, weight: .semibold) }
}

enum PSShadow {
    static let cardColor = Color.cardShadow
    static let cardYOffset: CGFloat = 8
    static let cardBlur: CGFloat = 24
}
