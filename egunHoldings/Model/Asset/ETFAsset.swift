import SwiftUI

struct ETFAsset: Identifiable, Hashable, Codable {
    let symbol: String
    let name: String
    let category: String
    let accentHex: String
    let icon: String

    var id: String { symbol }

    var accentColor: Color {
        Color(hex: accentHex)
    }

    var tintBackground: Color {
        accentColor.opacity(0.14)
    }

    static let allCases: [ETFAsset] = [
        ETFAsset(symbol: "QQQ", name: "나스닥 100", category: "성장주", accentHex: "4F6BFF", icon: "chart.line.uptrend.xyaxis"),
        ETFAsset(symbol: "SPY", name: "S&P 500", category: "대표지수", accentHex: "0EA5E9", icon: "chart.bar.fill"),
        ETFAsset(symbol: "VOO", name: "미국 대형주", category: "시장 추종", accentHex: "6366F1", icon: "building.columns"),
        ETFAsset(symbol: "SOXX", name: "반도체", category: "산업 테마", accentHex: "8B5CF6", icon: "cpu"),
        ETFAsset(symbol: "SCHD", name: "배당주", category: "현금흐름", accentHex: "10B981", icon: "banknote"),
        ETFAsset(symbol: "TLT", name: "미국 장기채", category: "채권", accentHex: "F59E0B", icon: "shield.checkered")
    ]

    static func asset(for symbol: String) -> ETFAsset? {
        allCases.first { $0.symbol == symbol }
    }
}
