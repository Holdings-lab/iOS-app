import Foundation

nonisolated struct PolicyNewsFeedResponseDTO: Decodable, Sendable {
    let feedType: String?
    let generatedAt: String?
    let source: PolicyNewsSourceDTO?
    let summary: PolicyNewsSummaryDTO?
    let model: PolicyNewsModelDTO?
    let cards: [PolicyNewsCardDTO]

    func toDomainItems() -> [PolicyNewsItem] {
        cards.map { card in
            card.toDomain(defaultTicker: model?.targetTicker, defaultSourceName: source?.dataset)
        }
    }
}

nonisolated struct PolicyNewsSourceDTO: Decodable, Sendable {
    let dataset: String?
    let modelTarget: String?
    let modelVersion: String?
}

nonisolated struct PolicyNewsSummaryDTO: Decodable, Sendable {
    let totalCount: Int?
    let positiveCount: Int?
    let negativeCount: Int?
    let neutralCount: Int?
    let overallSentiment: String?
    let overallSentimentScore: Double?
}

nonisolated struct PolicyNewsModelDTO: Decodable, Sendable {
    let targetTicker: String?
    let bestHorizonDays: Int?
    let bestFeatures: [String]?
    let metrics: PolicyNewsModelMetricsDTO?
}

nonisolated struct PolicyNewsModelMetricsDTO: Decodable, Sendable {
    let directionAccuracy: Double?
    let policyScore: Double?
    let policyVolatility: Double?
    let policyMomentum: Double?
    let sampleSize: Int?
    let topLabel: String?
    let topLabelProbability: Double?
}

nonisolated struct PolicyNewsCardDTO: Decodable, Sendable {
    let id: String
    let date: String?
    let category: String?
    let docType: String?
    let title: String
    let bodySummary: String?
    let link: String?
    let sentiment: PolicyNewsCardSentimentDTO?
    let modelSignal: PolicyNewsCardModelSignalDTO?

    func toDomain(defaultTicker: String?, defaultSourceName: String?) -> PolicyNewsItem {
        PolicyNewsItem(
            id: id,
            category: Self.mapCategory(category),
            publishedAt: Self.parseDate(date) ?? Date(),
            title: title,
            summary: bodySummary ?? "",
            sourceName: Self.sourceName(category: category, docType: docType, fallback: defaultSourceName),
            sourceURL: link.flatMap(URL.init(string:)),
            relatedTickers: [defaultTicker, modelSignal?.clusterLabel].compactMap { $0 }.filter { !$0.isEmpty },
            sentiment: Self.mapSentiment(rawValue: sentiment?.label, score: sentiment?.bodySentimentScore ?? sentiment?.titleSentimentScore)
        )
    }

    private static func sourceName(category: String?, docType: String?, fallback: String?) -> String {
        let parts = [category, docType]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if !parts.isEmpty {
            return parts.joined(separator: " · ")
        }

        return fallback ?? "Policy Feed"
    }

    private static func parseDate(_ value: String?) -> Date? {
        guard let value else { return nil }

        if let date = shortDateFormatter.date(from: value) {
            return date
        }

        if let date = fractionalISO8601Formatter.date(from: value) {
            return date
        }

        return iso8601Formatter.date(from: value)
    }

    private static func mapCategory(_ value: String?) -> PolicyNewsCategory {
        let normalized = value?.lowercased() ?? ""

        if normalized.contains("fomc") || normalized.contains("rate") {
            return .interestRate
        }

        if normalized.contains("energy") {
            return .energy
        }

        if normalized.contains("ai") {
            return .ai
        }

        if normalized.contains("bank") || normalized.contains("bis") || normalized.contains("finance") {
            return .finance
        }

        if normalized.contains("semi") || normalized.contains("chip") {
            return .semiconductor
        }

        return .macro
    }

    private static func mapSentiment(rawValue: String?, score: Double?) -> PolicyNewsSentiment {
        let normalized = rawValue?.lowercased() ?? ""

        if normalized.contains("negative") || normalized.contains("caution") {
            return .caution
        }

        if normalized.contains("positive") {
            return .positive
        }

        guard let score else {
            return .neutral
        }

        if score >= 0.15 {
            return .positive
        }

        if score <= -0.15 {
            return .caution
        }

        return .neutral
    }

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let fractionalISO8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

nonisolated struct PolicyNewsCardSentimentDTO: Decodable, Sendable {
    let label: String?
    let titleSentimentScore: Double?
    let bodySentimentScore: Double?
}

nonisolated struct PolicyNewsCardModelSignalDTO: Decodable, Sendable {
    let horizonDays: Int?
    let predictedLogReturn: Double?
    let predictedReturnPct: Double?
    let signal: String?
    let thresholdUsed: Double?
    let confidence: Double?
    let clusterLabel: String?
}
