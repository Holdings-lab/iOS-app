import Foundation
import SwiftUI

// MARK: - Events

nonisolated struct TodayEventsResponseDTO: Decodable {
    let dateSegments: [String]?
    let categories: [String]?
    let items: [TodayEventItemDTO]?
}

nonisolated struct TodayEventItemDTO: Decodable {
    let eventId: Int?
    let timeText: String?
    let title: String?
    let statusText: String?
    let tags: [String]?
    let importanceStars: Int?
    let countdownText: String?
    let relatedAssets: [String]?
    let alertEnabled: Bool?
    let sourceURL: String?
    let sourceUrl: String?
    let source_url: String?
    let articleURL: String?
    let articleUrl: String?
    let article_url: String?
    let url: String?
    let link: String?
}

extension TodayEventsResponseDTO {
    func toSignalEvents(fallback: [PolSignalEvent]) -> [PolSignalEvent] {
        let mapped = (items ?? []).enumerated().map { index, item in
            item.toSignalEvent(index: index, fallback: fallback[safe: index] ?? fallback.first)
        }

        return mapped.isEmpty ? fallback : mapped
    }
}

extension TodayEventItemDTO {
    func toSignalEvent(index: Int, fallback: PolSignalEvent?) -> PolSignalEvent {
        let fallback = fallback ?? PolSignalFlowMockData.events[safe: index] ?? PolSignalFlowMockData.events[0]
        let keywords = normalizedList(tags)
        let assets = normalizedList(relatedAssets)
        let sourceURL = signalSourceURL
        let sourceName = sourceURL?.host?.replacingOccurrences(of: "www.", with: "")
        let verdictKind = Self.verdictKind(
            statusText: statusText,
            importanceStars: importanceStars,
            fallback: fallback.verdictKind
        )
        let exposures = Self.exposures(from: assets, fallback: fallback.exposures)
        let keywordText = keywords.prefix(3).joined(separator: ", ")
        let assetText = assets.prefix(3).joined(separator: ", ")

        return PolSignalEvent(
            id: eventId ?? fallback.id,
            feedTab: assets.isEmpty ? .learning : .myImpact,
            category: keywords.first ?? fallback.category,
            institution: sourceName ?? fallback.institution,
            dDay: countdownText ?? timeText ?? fallback.dDay,
            title: title ?? fallback.title,
            verdictKind: verdictKind,
            verdict: statusText ?? fallback.verdict,
            reason: Self.reasonText(keywords: keywords, fallback: fallback.reason),
            expectedImpact: Self.impactText(assets: assets, fallback: fallback.expectedImpact),
            aiSummary: Self.summaryText(
                statusText: statusText,
                keywords: keywordText,
                assets: assetText,
                fallback: fallback.aiSummary
            ),
            ctaTitle: fallback.ctaTitle,
            exposures: exposures,
            scenarios: fallback.scenarios,
            weakeningCondition: fallback.weakeningCondition,
            sourceSummary: sourceURL?.absoluteString ?? fallback.sourceSummary,
            checkSchedule: timeText ?? fallback.checkSchedule,
            accentColor: verdictKind.accent,
            prescription: fallback.prescription
        )
    }

    private var signalSourceURL: URL? {
        [sourceURL, sourceUrl, source_url, articleURL, articleUrl, article_url, url, link]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
            .flatMap(URL.init(string:))
    }

    private static func verdictKind(
        statusText: String?,
        importanceStars: Int?,
        fallback: PolSignalVerdictKind
    ) -> PolSignalVerdictKind {
        let normalized = statusText?.lowercased() ?? ""

        if normalized.contains("adjust") || normalized.contains("조정") || normalized.contains("대응") {
            return .adjust
        }

        if normalized.contains("watch") || normalized.contains("관망") || normalized.contains("대기") {
            return .watch
        }

        if normalized.contains("review") || normalized.contains("점검") || normalized.contains("주의") {
            return .review
        }

        guard let importanceStars else {
            return fallback
        }

        if importanceStars >= 4 {
            return .review
        }

        if importanceStars >= 3 {
            return .watch
        }

        return fallback
    }

    private static func reasonText(keywords: [String], fallback: String) -> String {
        guard !keywords.isEmpty else {
            return fallback
        }

        return "서버 이벤트 태그에서 \(keywords.prefix(3).joined(separator: ", ")) 키워드가 감지됐어요."
    }

    private static func impactText(assets: [String], fallback: String) -> String {
        guard !assets.isEmpty else {
            return fallback
        }

        return "\(assets.prefix(3).joined(separator: ", "))와 연결된 정책 이벤트예요. 보유 자산 영향은 상세 화면에서 함께 점검합니다."
    }

    private static func summaryText(
        statusText: String?,
        keywords: String,
        assets: String,
        fallback: String
    ) -> String {
        let parts = [
            statusText,
            keywords.isEmpty ? nil : "주요 키워드: \(keywords)",
            assets.isEmpty ? nil : "관련 자산: \(assets)"
        ].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !parts.isEmpty else {
            return fallback
        }

        return parts.joined(separator: "\n")
    }

    private static func exposures(from assets: [String], fallback: [PolSignalExposure]) -> [PolSignalExposure] {
        let mapped = assets.prefix(4).map { asset in
            PolSignalExposure(
                ticker: asset,
                weightText: "관심",
                color: color(for: asset)
            )
        }

        return mapped.isEmpty ? fallback : mapped
    }

    private static func color(for asset: String) -> Color {
        let normalized = asset.lowercased()

        if normalized.contains("반도체") || normalized.contains("semi") || normalized.contains("chip") || normalized.contains("soxx") {
            return PSColor.tagSemi
        }

        if normalized.contains("친환경") || normalized.contains("energy") || normalized.contains("green") || normalized.contains("icln") {
            return PSColor.success
        }

        if normalized.contains("금융") || normalized.contains("bank") || normalized.contains("xlf") {
            return PSColor.warn
        }

        return PSColor.primary
    }

    private func normalizedList(_ values: [String]?) -> [String] {
        (values ?? [])
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
