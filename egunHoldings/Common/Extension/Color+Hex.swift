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

    // Compatibility aliases for older feature code. Prefer KODEX tokens above.
    static let deepNavy = Color.canvas
    static let electricBlue = Color.brand
    static let foreground = Color.textPrimary
    static let mutedForeground = Color.textTertiary
    static let navyCard = Color.elevated
    static let emerald = Color.success
    static let emeraldLight = Color.success
    static let emeraldSoft = Color.successBg
    static let policyPurple = Color.brandDark
    static let policyAmber = Color.warning
    static let policyCoral = Color.up
    static let policyCyan = Color.brandLight
    static let policyGold = Color.kodexYellow

    static let midnightTop = Color.canvas
    static let midnightBottom = Color.canvas
    static let midnightSurface = Color.elevated
    static let midnightBorder = Color.hairline
    static let midnightTextPrimary = Color.textPrimary
    static let midnightTextSecondary = Color.textTertiary
    static let midnightTextTertiary = Color.textQuaternary
    static let midnightAccent = Color.brand
    static let midnightSuccess = Color.success
    static let midnightError = Color.up
}
