import Foundation

nonisolated struct PolicyNewsFeedResponseDTO: Decodable, Sendable {
    let items: [PolicyNewsItemDTO]
}

nonisolated struct PolicyNewsItemDTO: Decodable, Sendable {
    let id: String
    let category: String
    let publishedAt: String
    let title: String
    let summary: String
    let sourceName: String
    let sourceURL: String?
    let relatedTickers: [String]
    let sentiment: String

    func toDomain() -> PolicyNewsItem {
        PolicyNewsItem(
            id: id,
            category: PolicyNewsCategory(rawValue: category) ?? .macro,
            publishedAt: Self.iso8601.date(from: publishedAt) ?? Date(),
            title: title,
            summary: summary,
            sourceName: sourceName,
            sourceURL: sourceURL.flatMap(URL.init(string:)),
            relatedTickers: relatedTickers,
            sentiment: PolicyNewsSentiment(rawValue: sentiment) ?? .neutral
        )
    }

    private static let iso8601 = ISO8601DateFormatter()
}

nonisolated struct PolicyNewsInsightRequestDTO: Encodable, Sendable {
    nonisolated struct HoldingDTO: Encodable, Sendable {
        let name: String
        let category: String
        let weightPercent: Int
    }

    let articleID: String
    let title: String
    let sourceName: String
    let holdings: [HoldingDTO]

    init(item: PolicyNewsItem, userAssetProfile: UserAssetProfile) {
        articleID = item.id
        title = item.title
        sourceName = item.sourceName
        holdings = userAssetProfile.holdings.map {
            HoldingDTO(
                name: $0.name,
                category: $0.category.rawValue,
                weightPercent: $0.weightPercent
            )
        }
    }
}

nonisolated struct PolicyNewsInsightResponseDTO: Decodable, Sendable {
    let articleID: String
    let headline: String
    let generatedAt: String
    let sourceName: String
    let sourceURL: String?
    let articleSummary: [String]
    let portfolioHeadline: String
    let portfolioBullets: [String]
    let actionChecklist: [String]
    let riskNotes: [String]
    let disclaimer: String

    func toDomain() -> PolicyNewsInsight {
        PolicyNewsInsight(
            articleID: articleID,
            headline: headline,
            generatedAt: Self.iso8601.date(from: generatedAt) ?? Date(),
            sourceName: sourceName,
            sourceURL: sourceURL.flatMap(URL.init(string:)),
            articleSummary: articleSummary,
            portfolioHeadline: portfolioHeadline,
            portfolioBullets: portfolioBullets,
            actionChecklist: actionChecklist,
            riskNotes: riskNotes,
            disclaimer: disclaimer
        )
    }

    private static let iso8601 = ISO8601DateFormatter()
}
