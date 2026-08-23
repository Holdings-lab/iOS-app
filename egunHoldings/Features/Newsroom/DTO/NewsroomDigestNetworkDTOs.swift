import Foundation

// MARK: - 뉴스룸 네트워크 DTO
//
// 서버 계약: `com.project.server.dto.NewsroomDto` (api-server, 2026-07 뉴스룸 API 신설).
// 목록/상세가 별도 엔드포인트다 — 예전의 "한 번에 다 담긴 다이제스트 + 폴링" 계약은 폐기됐다.
//   GET /api/users/{userId}/newsroom          → NewsroomBriefingResponseDTO
//   GET /api/users/{userId}/newsroom/{ticker} → NewsroomTickerDetailResponseDTO
// 공통 엔벨로프 `APIResponse<T>`의 `result`에 담겨 온다.

nonisolated enum NewsroomBriefingTypeDTO: String, Decodable, Sendable {
    case hero = "Hero"
    case compact = "Compact"
    case quiet = "Quiet"
}

nonisolated struct NewsroomBriefingResponseDTO: Decodable, Sendable {
    let header: NewsroomHeaderDTO
    let section: NewsroomSectionDTO?
    let holdings: [NewsroomHoldingBriefingDTO]?
    let footer: NewsroomTabFooterDTO?
    let emptyState: NewsroomEmptyStateDTO?
    let errorState: NewsroomErrorStateDTO?

    func toDomain() -> NewsroomBriefing {
        NewsroomBriefing(
            title: header.title,
            asOfAt: header.asOfAt,
            subtitle: header.subtitle,
            holdings: (holdings ?? []).map { $0.toDomain() },
            footerMessage: footer?.message,
            emptyState: emptyState?.toDomain(),
            errorState: errorState?.toDomain()
        )
    }
}

nonisolated struct NewsroomHeaderDTO: Decodable, Sendable {
    let title: String
    let asOfAt: Date?
    let subtitle: String
}

nonisolated struct NewsroomSectionDTO: Decodable, Sendable {
    let title: String
    let itemCount: Int
}

nonisolated struct NewsroomHoldingBriefingDTO: Decodable, Sendable {
    let ticker: String
    let name: String
    let weightPct: Double
    let briefingType: NewsroomBriefingTypeDTO
    let dailyChangePct: Double?
    let totalAssetImpactPct: Double?
    let headline: String?
    let summary: String?
    let detailPath: String?

    func toDomain() -> NewsroomHoldingBriefing {
        NewsroomHoldingBriefing(
            ticker: ticker,
            name: name,
            weightPercent: weightPct,
            briefingType: NewsroomBriefingType(dto: briefingType),
            dailyChangePercent: dailyChangePct,
            totalAssetImpactPercent: totalAssetImpactPct,
            headline: headline,
            summary: summary,
            detailPath: detailPath
        )
    }
}

nonisolated struct NewsroomTabFooterDTO: Decodable, Sendable {
    let message: String
}

nonisolated struct NewsroomEmptyStateDTO: Decodable, Sendable {
    let code: String
    let title: String
    let description: String
    let buttonLabel: String

    func toDomain() -> NewsroomEmptyState {
        NewsroomEmptyState(code: code, title: title, description: description, buttonLabel: buttonLabel)
    }
}

nonisolated struct NewsroomErrorStateDTO: Decodable, Sendable {
    let title: String
    let summary: String
    let buttonLabel: String

    func toDomain() -> NewsroomErrorState {
        NewsroomErrorState(title: title, summary: summary, buttonLabel: buttonLabel)
    }
}

// MARK: - 상세

nonisolated struct NewsroomTickerDetailResponseDTO: Decodable, Sendable {
    let stock: NewsroomStockMetaDTO
    let headline: String
    let imageUrl: String?
    let aiJudgement: NewsroomAIJudgementDTO?
    let summary: NewsroomDetailSummaryDTO?
    let sources: [NewsroomSourceItemDTO]?
    let footer: NewsroomDetailFooterDTO?

    func toDomain() -> NewsroomTickerDetail {
        NewsroomTickerDetail(
            stock: stock.toDomain(),
            headline: headline,
            imageURL: imageUrl.flatMap(URL.init(string:)),
            aiJudgement: aiJudgement?.toDomain(),
            summaryBody: summary?.body,
            findings: summary?.findings ?? [],
            sources: (sources ?? []).map { $0.toDomain() },
            asOfAt: footer?.asOfAt,
            aiNotice: footer?.aiNotice
        )
    }
}

nonisolated struct NewsroomStockMetaDTO: Decodable, Sendable {
    let ticker: String
    let name: String
    let dailyChangePct: Double?
    let weightPct: Double?
    let totalAssetImpactPct: Double?

    func toDomain() -> NewsroomStockMeta {
        NewsroomStockMeta(
            ticker: ticker,
            name: name,
            dailyChangePercent: dailyChangePct,
            weightPercent: weightPct,
            totalAssetImpactPercent: totalAssetImpactPct
        )
    }
}

/// AI 판단 블록.
///
/// 서버가 문자열 한 줄만 주던 이전 스키마와 객체를 주는 현재 스키마가 한동안 공존할 수 있어
/// 둘 다 받아들인다 — 문자열이 오면 headline만 채운 형태로 취급한다.
/// `used_news_url`은 이 블록만 snake_case라서(모델 출력이 그대로 실려 나온다) 키를 명시한다.
nonisolated struct NewsroomAIJudgementDTO: Decodable, Sendable {
    let title: String?
    let headline: String
    let reason: String?
    let alignment: String?
    let usedNewsURLs: [String]?
    let disclaimer: String?

    private enum CodingKeys: String, CodingKey {
        case title
        case headline
        case reason
        case alignment
        case usedNewsURLs = "used_news_url"
        case disclaimer
    }

    init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer(), let text = try? single.decode(String.self) {
            title = nil
            headline = text
            reason = nil
            alignment = nil
            usedNewsURLs = nil
            disclaimer = nil
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        headline = try container.decode(String.self, forKey: .headline)
        reason = try container.decodeIfPresent(String.self, forKey: .reason)
        alignment = try container.decodeIfPresent(String.self, forKey: .alignment)
        usedNewsURLs = try container.decodeIfPresent([String].self, forKey: .usedNewsURLs)
        disclaimer = try container.decodeIfPresent(String.self, forKey: .disclaimer)
    }

    func toDomain() -> NewsroomAIJudgement {
        NewsroomAIJudgement(
            title: title,
            headline: headline,
            reason: reason,
            alignment: alignment.flatMap(NewsroomAIAlignment.init(rawValue:)),
            usedNewsURLs: (usedNewsURLs ?? []).compactMap(URL.init(string:)),
            disclaimer: disclaimer
        )
    }
}

nonisolated struct NewsroomDetailSummaryDTO: Decodable, Sendable {
    let body: String?
    let findings: [String]?
}

nonisolated struct NewsroomSourceItemDTO: Decodable, Sendable {
    let newsId: String?
    let title: String
    let publisher: String
    /// 서버가 항상 ISO8601로 못 줄 수 있어(원문 파싱 실패 시 원본 문자열 그대로 폴백) 문자열로 받고
    /// 화면에서 최선 노력으로 파싱한다 — 여기서 Date로 강제하면 그 경우 전체 디코딩이 깨진다.
    let publishedAt: String?
    let url: String?

    func toDomain() -> NewsroomSourceItem {
        NewsroomSourceItem(
            newsId: newsId,
            title: title,
            publisher: publisher,
            publishedAtRaw: publishedAt,
            url: url.flatMap(URL.init(string:))
        )
    }
}

nonisolated struct NewsroomDetailFooterDTO: Decodable, Sendable {
    let asOfAt: Date?
    let aiNotice: String?
}

private nonisolated extension NewsroomBriefingType {
    init(dto: NewsroomBriefingTypeDTO) {
        switch dto {
        case .hero: self = .hero
        case .compact: self = .compact
        case .quiet: self = .quiet
        }
    }
}
