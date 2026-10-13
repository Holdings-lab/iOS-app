import SwiftUI

// 있었다 — 여기서는 PSColor를 단일 소스로 참조해 중복 정의를 없애고, PSColor에 없는
// 값(등락색, 종목/현금 세그먼트색)만 이 탭 고유의 hex로 유지한다.
enum AssetTabPalette {
    static let screen = PSColor.background
    static let card = PSColor.surface
    static let subBackground = PSColor.surfaceAlt
    static let textPrimary = PSColor.textPrimary
    static let textSecondary = PSColor.textSecondary
    static let brand = PSColor.primary
    static let brandSoft = PSColor.primarySoft
    static let divider = PSColor.border
    static let up = Color(hex: "16A34A")
    static let down = Color(hex: "DC2626")
    static let neutral = PSColor.textFaint
    static let stockETFSegment = PSColor.primary
    static let stockSegment = Color(hex: "8D96A3")
    static let bondSegment = Color(hex: "5B9BD5")
    static let goldCommoditySegment = Color(hex: "C89B3C")
    static let reitSegment = Color(hex: "8D70C9")
    static let otherSegment = Color(hex: "64748B")
    static let cashSegment = Color(hex: "C5CAD3")
}

extension View {
    func assetCardShadow() -> some View {
        shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 1)
    }

    func assetHeroShadow() -> some View {
        shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 1)
            .shadow(color: AssetTabPalette.brand.opacity(0.07), radius: 20, x: 0, y: 6)
    }
}
