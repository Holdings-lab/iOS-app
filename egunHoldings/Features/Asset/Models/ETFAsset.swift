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

    nonisolated static let allCases: [ETFAsset] = [
        ETFAsset(symbol: "QQQ", name: "나스닥 100", category: "성장주", accentHex: "2566E8", icon: "chart.line.uptrend.xyaxis"),
        ETFAsset(symbol: "SPY", name: "S&P 500", category: "대표지수", accentHex: "5B8DEF", icon: "chart.bar.fill"),
        ETFAsset(symbol: "VOO", name: "미국 대형주", category: "시장 추종", accentHex: "1F8A4C", icon: "building.columns"),
        ETFAsset(symbol: "SOXX", name: "반도체", category: "산업 테마", accentHex: "0F3FB0", icon: "cpu"),
        ETFAsset(symbol: "SCHD", name: "배당주", category: "현금흐름", accentHex: "1F8A4C", icon: "banknote"),
        ETFAsset(symbol: "TLT", name: "미국 장기채", category: "채권", accentHex: "C58B00", icon: "shield.checkered")
    ]

    nonisolated static func asset(for symbol: String) -> ETFAsset? {
        allCases.first { $0.symbol == symbol }
    }
}
