import SwiftUI

extension Color {
    init(hex: String, alpha: Double = 1) {
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
