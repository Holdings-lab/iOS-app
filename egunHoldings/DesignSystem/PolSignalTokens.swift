import SwiftUI

nonisolated enum PSColor {
    static let background = Color(hex: "F0F4FF")
    static let surface = Color.white
    static let surfaceAlt = Color(hex: "F8FAFF")
    static let border = Color(hex: "E2E8F0")
    static let rule = Color(hex: "EEF2F8")

    static let textPrimary = Color(hex: "0F172A")
    static let textSecondary = Color(hex: "64748B")
    static let textMuted = Color(hex: "64748B")
    static let textFaint = Color(hex: "94A3B8")

    static let primary = Color(hex: "2563EB")
    static let primarySoft = Color(hex: "EFF6FF")
    static let danger = Color(hex: "EF4444")
    static let dangerBg = Color(hex: "FEF2F2")
    static let warn = Color(hex: "F59E0B")
    static let warnBg = Color(hex: "FFFBEB")
    static let success = Color(hex: "10B981")
    static let successBg = Color(hex: "ECFDF5")

    static let tagSemi = Color(hex: "3B82F6")
    static let tagPolicy = Color(hex: "1E293B")
    static let tagRate = Color(hex: "6B7280")
    static let tagPolicyBg = Color(hex: "F1F5F9")
    static let tagRateBg = Color(hex: "F3F4F6")

    static let cardShadow = Color.black.opacity(0.06)
    static let sheetShadow = Color(hex: "0F172A", alpha: 0.10)

    // Compatibility aliases kept for existing PolSignal and Today mock code.
    static let bgDeepNavy = background
    static let bgCard = surface
    static let bgCardSub = surfaceAlt
    static let bgCardMuted = surfaceAlt
    static let primaryBlue = primary
    static let primaryBluePressed = Color(hex: "1D4ED8")
    static let electricBlue = primary
    static let blueSubtle = tagSemi
    static let purple = tagPolicy
    static let emerald = success
    static let yellow = warn
    static let red = danger
    static let cyan = tagSemi
    static let gray = textFaint
    static let trendUp = success
    static let trendDown = danger
    static let borderStrong = border
    static let divider = rule
}

enum PSRadius {
    static let card: CGFloat  = 16
    static let inner: CGFloat = 14
    static let small: CGFloat = 10
    static let chip: CGFloat  = 999
    static let pill: CGFloat  = 999
    static let badge: CGFloat = 6
    static let button: CGFloat = 12
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
    static let displayTracking: CGFloat = -0.01

    static func display(_ size: CGFloat = 34)  -> Font { .pretendard(size, weight: .bold) }
    static func title(_ size: CGFloat = 18)    -> Font { .pretendard(size, weight: .semibold) }
    static func body(_ size: CGFloat = 15)     -> Font { .pretendard(size, weight: .regular) }
    static func semibold(_ size: CGFloat = 14) -> Font { .pretendard(size, weight: .semibold) }
    static func caption(_ size: CGFloat = 13)  -> Font { .pretendard(size, weight: .medium) }
    static func tickerLabel(_ size: CGFloat = 16) -> Font { .pretendard(size, weight: .semibold) }
}

enum PSShadow {
    static let cardColor = PSColor.cardShadow
    static let cardYOffset: CGFloat = 1
    static let cardBlur: CGFloat = 4
}
