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
    nonisolated static let canvas       = Color(hex: "F5F6F8")
    nonisolated static let elevated     = Color.white
    nonisolated static let subtle       = Color(hex: "F7F8FA")
    nonisolated static let muted        = Color(hex: "F4F5F7")
    nonisolated static let divider      = Color(hex: "F0F1F4")
    nonisolated static let kdxDivider   = Color(hex: "F0F1F4")
    nonisolated static let hairline     = Color(hex: "ECEEF1")

    // KODEX Light — Text
    nonisolated static let textPrimary    = Color(hex: "0F1115")
    nonisolated static let textSecondary  = Color(hex: "1A1A1A")
    nonisolated static let textTertiary   = Color(hex: "6B7280")
    nonisolated static let textQuaternary = Color(hex: "9AA0A6")
    nonisolated static let textDisabled   = Color(hex: "B5BAC2")
    nonisolated static let textOnAccent   = Color.white

    // KODEX Light — Brand
    nonisolated static let brand         = Color(hex: "2566E8")
    nonisolated static let brandDark     = Color(hex: "0F3FB0")
    nonisolated static let brandLight    = Color(hex: "5B8DEF")
    nonisolated static let brandTintBg   = Color(hex: "EEF4FF")
    nonisolated static let brandChipBg   = Color(hex: "E8EFFD")
    nonisolated static let brandChipText = Color(hex: "2566E8")

    // KODEX Light — Semantic
    nonisolated static let up            = Color(hex: "E84B4B")
    nonisolated static let upBg          = Color(hex: "FCEAEA")
    nonisolated static let down          = Color(hex: "2566E8")
    nonisolated static let success       = Color(hex: "1F8A4C")
    nonisolated static let successBg     = Color(hex: "E6F4EC")
    nonisolated static let warning       = Color(hex: "C58B00")
    nonisolated static let warningBg     = Color(hex: "FFFBEB")
    nonisolated static let warningBorder = Color(hex: "FCE9A6")
    nonisolated static let kodexYellow   = Color(hex: "FFCC00")
    nonisolated static let inkBlack      = Color(hex: "1A1A1A")

    // Compatibility aliases for older feature code. Prefer KODEX tokens above.
    nonisolated static let deepNavy = Color.canvas
    nonisolated static let electricBlue = Color.brand
    nonisolated static let foreground = Color.textPrimary
    nonisolated static let mutedForeground = Color.textTertiary
    nonisolated static let navyCard = Color.elevated
    nonisolated static let emerald = Color.success
    nonisolated static let emeraldLight = Color.success
    nonisolated static let emeraldSoft = Color.successBg
    nonisolated static let policyPurple = Color.brandDark
    nonisolated static let policyAmber = Color.warning
    nonisolated static let policyCoral = Color.up
    nonisolated static let policyCyan = Color.brandLight
    nonisolated static let policyGold = Color.kodexYellow

    nonisolated static let midnightTop = Color.canvas
    nonisolated static let midnightBottom = Color.canvas
    nonisolated static let midnightSurface = Color.elevated
    nonisolated static let midnightBorder = Color.hairline
    nonisolated static let midnightTextPrimary = Color.textPrimary
    nonisolated static let midnightTextSecondary = Color.textTertiary
    nonisolated static let midnightTextTertiary = Color.textQuaternary
    nonisolated static let midnightAccent = Color.brand
    nonisolated static let midnightSuccess = Color.success
    nonisolated static let midnightError = Color.up
}
