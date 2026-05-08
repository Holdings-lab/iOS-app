import SwiftUI

extension Color {
    nonisolated init(hex: String, alpha: Double = 1) {
        let sanitized = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)

        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0

        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }

    // KODEX Light — Surface
    static let canvas       = Color(hex: "F5F6F8")
    static let elevated     = Color.white
    static let subtle       = Color(hex: "F7F8FA")
    static let muted        = Color(hex: "F4F5F7")
    static let divider      = Color(hex: "F0F1F4")
    static let kdxDivider   = Color(hex: "F0F1F4")
    static let hairline     = Color(hex: "ECEEF1")

    // KODEX Light — Text
    static let textPrimary    = Color(hex: "0F1115")
    static let textSecondary  = Color(hex: "1A1A1A")
    static let textTertiary   = Color(hex: "6B7280")
    static let textQuaternary = Color(hex: "9AA0A6")
    static let textDisabled   = Color(hex: "B5BAC2")
    static let textOnAccent   = Color.white

    // KODEX Light — Brand
    static let brand         = Color(hex: "2566E8")
    static let brandDark     = Color(hex: "0F3FB0")
    static let brandLight    = Color(hex: "5B8DEF")
    static let brandTintBg   = Color(hex: "EEF4FF")
    static let brandChipBg   = Color(hex: "E8EFFD")
    static let brandChipText = Color(hex: "2566E8")

    // KODEX Light — Semantic
    static let up            = Color(hex: "E84B4B")
    static let upBg          = Color(hex: "FCEAEA")
    static let down          = Color(hex: "2566E8")
    static let success       = Color(hex: "1F8A4C")
    static let successBg     = Color(hex: "E6F4EC")
    static let warning       = Color(hex: "C58B00")
    static let warningBg     = Color(hex: "FFFBEB")
    static let warningBorder = Color(hex: "FCE9A6")
    static let kodexYellow   = Color(hex: "FFCC00")
    static let inkBlack      = Color(hex: "1A1A1A")

    // Legacy — Auth / Onboarding dark theme (do not use in main app)
    static let deepNavy = Color(hex: "0A0E27")
    static let electricBlue = Color(hex: "3B82F6")
    static let foreground = Color(hex: "E8ECF4")
    static let mutedForeground = Color(hex: "7A88A8")
    static let navyCard = Color(hex: "161C3C")
    static let emerald = Color(hex: "10B981")
    static let emeraldLight = Color(hex: "34D399")
    static let emeraldSoft = Color(hex: "6EE7B7")
    static let policyPurple = Color(hex: "8B5CF6")
    static let policyAmber = Color(hex: "F59E0B")
    static let policyCoral = Color(hex: "EF4444")
    static let policyCyan = Color(hex: "06B6D4")
    static let policyGold = Color(hex: "FACC15")

    static let midnightTop = Color(hex: "08112B")
    static let midnightBottom = Color(hex: "060A1C")
    static let midnightSurface = Color.white.opacity(0.07)
    static let midnightBorder = Color.white.opacity(0.08)
    static let midnightTextPrimary = Color.white.opacity(0.92)
    static let midnightTextSecondary = Color.white.opacity(0.62)
    static let midnightTextTertiary = Color.white.opacity(0.42)
    static let midnightAccent = Color(hex: "7C86FF")
    static let midnightSuccess = Color(hex: "83E2B8")
    static let midnightError = Color(hex: "FF8F8F")
}
