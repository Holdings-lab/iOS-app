import Foundation
import SwiftUI

enum PolicyNewsCategory: String, CaseIterable, Sendable {
    case semiconductor
    case interestRate
    case energy
    case macro
    case finance
    case ai

    var title: String {
        switch self {
        case .semiconductor:
            return "반도체"
        case .interestRate:
            return "금리"
        case .energy:
            return "에너지"
        case .macro:
            return "거시경제"
        case .finance:
            return "금융"
        case .ai:
            return "AI"
        }
    }

    var color: Color {
        switch self {
        case .semiconductor:
            return .policyPurple
        case .interestRate:
            return .electricBlue
        case .energy:
            return .emerald
        case .macro:
            return .policyAmber
        case .finance:
            return .policyCoral
        case .ai:
            return .electricBlue
        }
    }
}

enum PolicyNewsSentiment: String, Sendable {
    case positive
    case neutral
    case caution

    var iconName: String {
        switch self {
        case .positive:
            return "arrow.up.right"
        case .neutral:
            return "minus"
        case .caution:
            return "arrow.down.right"
        }
    }

    var color: Color {
        switch self {
        case .positive:
            return .emeraldLight
        case .neutral:
            return .electricBlue
        case .caution:
            return .policyCoral
        }
    }
}

struct PolicyNewsItem: Identifiable, Equatable, Sendable {
    let id: String
    let category: PolicyNewsCategory
    let publishedAt: Date
    let title: String
    let summary: String
    let sourceName: String
    let sourceURL: URL?
    let relatedTickers: [String]
    let sentiment: PolicyNewsSentiment
}

struct PolicyNewsInsight: Equatable, Sendable {
    let articleID: String
    let headline: String
    let generatedAt: Date
    let sourceName: String
    let sourceURL: URL?
    let articleSummary: [String]
    let portfolioHeadline: String
    let portfolioBullets: [String]
    let actionChecklist: [String]
    let riskNotes: [String]
    let disclaimer: String
}

extension PolicyNewsItem {
    var relativePublishedText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: publishedAt, relativeTo: Date())
    }
}

extension PolicyNewsInsight {
    var generatedAtText: String {
        Self.generatedFormatter.string(from: generatedAt)
    }

    private static let generatedFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M/d HH:mm"
        return formatter
    }()
}
