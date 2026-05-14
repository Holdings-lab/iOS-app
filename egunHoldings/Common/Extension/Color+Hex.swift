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

    // Stockit Light — Surface
    nonisolated static let canvas       = Color(hex: "F4F6FB")
    nonisolated static let elevated     = Color.white
    nonisolated static let subtle       = Color(hex: "F4F6FB")
    nonisolated static let muted        = Color(hex: "EEF1F6")
    nonisolated static let divider      = Color(hex: "EEF1F6")
    nonisolated static let kdxDivider   = Color(hex: "EEF1F6")
    nonisolated static let hairline     = Color(hex: "EEF1F6")
    nonisolated static let cardShadow   = Color(hex: "0A0E27", alpha: 0.04)

    // Stockit Light — Text
    nonisolated static let textPrimary    = Color(hex: "0A0E27")
    nonisolated static let textSecondary  = Color(hex: "8B92A8")
    nonisolated static let textTertiary   = Color(hex: "8B92A8")
    nonisolated static let textQuaternary = Color(hex: "AEB5C6")
    nonisolated static let textDisabled   = Color(hex: "C8CEDB")
    nonisolated static let textOnAccent   = Color.white

    // Stockit Light — Brand
    nonisolated static let brand         = Color(hex: "3461FD")
    nonisolated static let brandDark     = Color(hex: "2849C8")
    nonisolated static let brandLight    = Color(hex: "6D92FF")
    nonisolated static let brandTintBg   = Color(hex: "3461FD", alpha: 0.10)
    nonisolated static let brandChipBg   = Color(hex: "3461FD", alpha: 0.08)
    nonisolated static let brandChipText = Color(hex: "3461FD")

    // Stockit Light — Semantic
    nonisolated static let trendUp       = Color(hex: "1ECB81")
    nonisolated static let trendDown     = Color(hex: "F25C5C")
    nonisolated static let up            = Color.trendDown
    nonisolated static let upBg          = Color(hex: "F25C5C", alpha: 0.12)
    nonisolated static let down          = Color.trendDown
    nonisolated static let downBg        = Color(hex: "F25C5C", alpha: 0.12)
    nonisolated static let success       = Color.trendUp
    nonisolated static let successBg     = Color(hex: "1ECB81", alpha: 0.12)
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
    nonisolated static let policyCoral = Color.trendDown
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
    nonisolated static let midnightError = Color.trendDown
}
