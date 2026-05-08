import SwiftUI

nonisolated enum PSColor {
    // KODEX Light aliases kept for existing PolSignal views.
    static let bgDeepNavy  = Color.canvas
    static let bgCard      = Color.elevated
    static let bgCardSub   = Color.subtle
    static let bgCardMuted = Color.muted

    static let electricBlue = Color.brand
    static let blueSubtle   = Color.brandLight
    static let purple       = Color.brandDark
    static let emerald      = Color.success
    static let yellow       = Color.warning
    static let red          = Color.up
    static let cyan         = Color.brandLight
    static let gray         = Color.textTertiary

    static let textPrimary = Color.textPrimary
    static let textMuted   = Color.textTertiary
    static let textFaint   = Color.textQuaternary

    static let border       = Color.hairline
    static let borderStrong = Color.divider
}

enum PSRadius {
    static let card: CGFloat  = KDXRadius.card
    static let inner: CGFloat = KDXRadius.button
    static let small: CGFloat = 10
    static let chip: CGFloat  = KDXRadius.chip
}

enum PSSpacing {
    static let pagePad: CGFloat    = KDXSpacing.screenHorizontal
    static let sectionGap: CGFloat = KDXSpacing.section
    static let cardPad: CGFloat    = KDXSpacing.cardPadding
}

enum PSFont {
    static func title(_ size: CGFloat = 22)    -> Font { .pretendard(size, weight: .bold) }
    static func body(_ size: CGFloat = 14)     -> Font { .pretendard(size, weight: .regular) }
    static func semibold(_ size: CGFloat = 14) -> Font { .pretendard(size, weight: .semibold) }
    static func caption(_ size: CGFloat = 11)  -> Font { .pretendard(size, weight: .regular) }
}
