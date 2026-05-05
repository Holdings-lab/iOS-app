import SwiftUI

nonisolated enum PSColor {
    // Background
    static let bgDeepNavy  = Color(hex: "0A0E27")
    static let bgCard      = Color(hex: "121838")
    static let bgCardSub   = Color(white: 1, opacity: 0.035)
    static let bgCardMuted = Color(white: 1, opacity: 0.025)

    // Brand
    static let electricBlue = Color(hex: "3B82F6")
    static let blueSubtle   = Color(hex: "93B4F8")
    static let purple       = Color(hex: "8B5CF6")
    static let emerald      = Color(hex: "10B981")
    static let yellow       = Color(hex: "F59E0B")
    static let red          = Color(hex: "EF4444")
    static let cyan         = Color(hex: "06B6D4")
    static let gray         = Color(hex: "6B7280")

    // Text
    static let textPrimary = Color(hex: "E8ECF4")
    static let textMuted   = Color(white: 1, opacity: 0.40)
    static let textFaint   = Color(white: 1, opacity: 0.25)

    // Border
    static let border       = Color(white: 1, opacity: 0.08)
    static let borderStrong = Color(white: 1, opacity: 0.12)
}

enum PSRadius {
    static let card: CGFloat  = 24
    static let inner: CGFloat = 16
    static let small: CGFloat = 12
    static let chip: CGFloat  = 999
}

enum PSSpacing {
    static let pagePad: CGFloat    = 16
    static let sectionGap: CGFloat = 16
    static let cardPad: CGFloat    = 20
}

enum PSFont {
    static func title(_ size: CGFloat = 22)    -> Font { .pretendard(size, weight: .medium) }
    static func body(_ size: CGFloat = 14)     -> Font { .pretendard(size, weight: .regular) }
    static func semibold(_ size: CGFloat = 14) -> Font { .pretendard(size, weight: .semibold) }
    static func caption(_ size: CGFloat = 11)  -> Font { .pretendard(size, weight: .regular) }
}
