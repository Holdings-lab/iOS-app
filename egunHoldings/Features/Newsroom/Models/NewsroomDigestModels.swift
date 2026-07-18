import Foundation

// MARK: - Daily portfolio briefing

/// 뉴스룸 리스트와 상세가 함께 사용하는 하루 1회 생성 페이로드.
/// 클라이언트는 보유 종목 조합에 맞춰 이미 생성된 종목별 요약을 조립해 보여준다.
struct NewsroomDigest: Equatable {
    let generatedAt: Date
    let nextUpdateText: String
    /// 전체 배치 실패 후 이전 캐시를 보여줄 때만 true.
    let isOffline: Bool
    /// 같은 uuid가 두 개 이상의 보유 종목 피드에 겹쳤을 때만 존재한다.
    let macroIssue: NewsroomMacroIssue?
    let tickerDigests: [NewsroomTickerDigest]

    var referenceText: String {
        let base = NewsroomDigestDateFormat.referenceText(for: generatedAt)
        return isOffline ? "\(base) (오프라인)" : base
    }

    /// 새 소식 여부 → 보유 비중 → 최신 기사 순. 서버 순서에 기대지 않는다.
    var sortedTickerDigests: [NewsroomTickerDigest] {
        tickerDigests.sorted { lhs, rhs in
            if lhs.hasNews != rhs.hasNews { return lhs.hasNews && !rhs.hasNews }
            if lhs.portfolioWeightPercent != rhs.portfolioWeightPercent {
                return lhs.portfolioWeightPercent > rhs.portfolioWeightPercent
            }
            return (lhs.latestPublishedAt ?? .distantPast) > (rhs.latestPublishedAt ?? .distantPast)
        }
    }

    /// 뉴스가 있는 종목 가운데 보유 비중 상위 두 개만 히어로 카드가 된다.
    var heroTickerIDs: Set<String> {
        Set(sortedTickerDigests.filter(\.hasNews).prefix(2).map(\.id))
    }
}

struct NewsroomMacroIssue: Equatable, Hashable {
    let headline: String
    let summary: String
    let affectedTickers: [String]
}

struct NewsroomTickerDigest: Identifiable, Equatable, Hashable {
    let ticker: String
    let name: String
    let hasNews: Bool
    let quietDays: Int
    let priceChangePercent: Double?
    let portfolioWeightPercent: Int
    /// 종목 로고 URL. 없거나 로드에 실패하면 티커 이니셜 아이콘을 쓴다.
    let logoURL: URL?
    let headline: String?
    /// 리스트의 한 줄 설명. 컴팩트 로우는 이 필드만 노출한다.
    let subheadline: String?
    let summary: String?
    let newFacts: [String]
    /// 전망·변동성에 관한 정성 코멘트만 담는다.
    let aiView: String?
    /// 대표 기사의 썸네일. 없으면 확대된 종목 로고로 대체한다.
    let representativeImageURL: URL?
    let imageAttribution: String?
    let articles: [NewsroomDigestArticle]

    var id: String { ticker }

    var quietStatusText: String {
        quietDays <= 1 ? "오늘은 특이사항 없음" : "\(quietDays)일째 특이사항 없음"
    }

    var portfolioImpactPercent: Double? {
        guard let priceChangePercent else { return nil }
        return priceChangePercent * Double(portfolioWeightPercent) / 100
    }

    var latestPublishedAt: Date? {
        articles.map(\.publishedAt).max()
    }
}

struct NewsroomDigestArticle: Identifiable, Equatable, Hashable {
    let id: String
    let title: String
    let source: String
    let publishedAt: Date
    let url: URL?
}

// MARK: - Date formatting

enum NewsroomDigestDateFormat {
    nonisolated(unsafe) private static let referenceFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 HH:mm"
        return formatter
    }()

    static func referenceText(for date: Date) -> String {
        "\(referenceFormatter.string(from: date)) 기준"
    }

    static func relativeText(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
