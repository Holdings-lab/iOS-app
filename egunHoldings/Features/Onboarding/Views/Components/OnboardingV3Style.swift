import SwiftUI

enum OnboardingV3Theme {
    static let primary = Color(hex: "2563EB")
    static let success = Color(hex: "10B981")
    static let warning = Color(hex: "F59E0B")
    static let background = Color(hex: "F0F4FF")
    static let cardBackground = Color.white
    static let selectedBackground = Color(hex: "EFF6FF")
    static let panelBackground = Color(hex: "F8FAFF")
    static let border = Color(hex: "E2E8F0")
    static let muted = Color(hex: "94A3B8")
}

enum OnboardingV3Layout {
    static let maxWidth: CGFloat = 390
    static let horizontalPadding: CGFloat = 24
    static let bottomButtonHeight: CGFloat = 52
    static let progressTop: CGFloat = 0
    static let progressHorizontalPadding: CGFloat = 20
    static let progressExpandedHeight: CGFloat = 44
    static let progressCollapsedHeight: CGFloat = 20
    static let progressContentTopPadding: CGFloat = progressExpandedHeight
}
