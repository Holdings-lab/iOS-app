import Foundation

struct InterestKeywordCategory: Identifiable {
    let id: String
    let displayName: String
    let keywords: [InterestKeyword]
}

struct InterestKeyword: Identifiable, Hashable {
    let id: String
    let tag: String
    let categoryID: String
}

extension InterestKeywordCategory {
    static let allCategories: [InterestKeywordCategory] = [
        InterestKeywordCategory(
            id: "bigtech_ai",
            displayName: "빅테크·AI",
            keywords: [
                InterestKeyword(id: "nvidia", tag: "#엔비디아", categoryID: "bigtech_ai"),
                InterestKeyword(id: "mag7", tag: "#매그니피센트7", categoryID: "bigtech_ai"),
                InterestKeyword(id: "ai_chip", tag: "#AI반도체", categoryID: "bigtech_ai"),
                InterestKeyword(id: "apple", tag: "#애플", categoryID: "bigtech_ai"),
                InterestKeyword(id: "meta", tag: "#메타", categoryID: "bigtech_ai"),
                InterestKeyword(id: "msft", tag: "#마이크로소프트", categoryID: "bigtech_ai")
            ]
        ),
        InterestKeywordCategory(
            id: "us_index_etf",
            displayName: "미국 지수·ETF",
            keywords: [
                InterestKeyword(id: "qqq", tag: "#QQQ", categoryID: "us_index_etf"),
                InterestKeyword(id: "nasdaq100", tag: "#나스닥100", categoryID: "us_index_etf"),
                InterestKeyword(id: "spy", tag: "#SPY", categoryID: "us_index_etf"),
                InterestKeyword(id: "sp500", tag: "#S&P500", categoryID: "us_index_etf"),
                InterestKeyword(id: "soxx", tag: "#SOXX", categoryID: "us_index_etf")
            ]
        ),
        InterestKeywordCategory(
            id: "rates_macro",
            displayName: "금리·매크로",
            keywords: [
                InterestKeyword(id: "fomc", tag: "#FOMC", categoryID: "rates_macro"),
                InterestKeyword(id: "rate_cut", tag: "#금리인하", categoryID: "rates_macro"),
                InterestKeyword(id: "usd_krw", tag: "#달러환율", categoryID: "rates_macro"),
                InterestKeyword(id: "us_treasury", tag: "#미국채", categoryID: "rates_macro"),
                InterestKeyword(id: "tlt", tag: "#TLT", categoryID: "rates_macro"),
                InterestKeyword(id: "inflation", tag: "#인플레이션", categoryID: "rates_macro"),
                InterestKeyword(id: "us_china_trade", tag: "#미중무역", categoryID: "rates_macro"),
                InterestKeyword(id: "geopolitics", tag: "#지정학", categoryID: "rates_macro")
            ]
        ),
        InterestKeywordCategory(
            id: "energy_green",
            displayName: "에너지·친환경",
            keywords: [
                InterestKeyword(id: "crude_oil", tag: "#원유", categoryID: "energy_green"),
                InterestKeyword(id: "xle", tag: "#XLE", categoryID: "energy_green"),
                InterestKeyword(id: "solar", tag: "#태양광", categoryID: "energy_green"),
                InterestKeyword(id: "icln", tag: "#ICLN", categoryID: "energy_green"),
                InterestKeyword(id: "nat_gas", tag: "#천연가스", categoryID: "energy_green")
            ]
        ),
        InterestKeywordCategory(
            id: "sector_industry",
            displayName: "섹터·산업",
            keywords: [
                InterestKeyword(id: "tsla", tag: "#테슬라", categoryID: "sector_industry"),
                InterestKeyword(id: "ev", tag: "#전기차", categoryID: "sector_industry"),
                InterestKeyword(id: "rivian", tag: "#리비안", categoryID: "sector_industry"),
                InterestKeyword(id: "lmt", tag: "#록히드", categoryID: "sector_industry"),
                InterestKeyword(id: "defense_etf", tag: "#방산ETF", categoryID: "sector_industry"),
                InterestKeyword(id: "xlf", tag: "#XLF", categoryID: "sector_industry"),
                InterestKeyword(id: "financials", tag: "#금융주", categoryID: "sector_industry")
            ]
        )
    ]
}
