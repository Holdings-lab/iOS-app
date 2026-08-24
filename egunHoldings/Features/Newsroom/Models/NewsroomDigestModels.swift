import Foundation

// MARK: - 뉴스룸 목록

/// `GET /newsroom` 1회 응답을 그대로 옮긴 도메인 모델.
/// 서버가 이미 briefingType(Hero/Compact/Quiet)과 정렬 순서를 결정해서 주므로,
/// 예전처럼 클라이언트가 hasNews/비중으로 재정렬하거나 히어로를 골라내지 않는다.
nonisolated struct NewsroomBriefing: Equatable, Sendable {
    let title: String
    let asOfAt: Date?
    let subtitle: String
    let holdings: [NewsroomHoldingBriefing]
    let footerMessage: String?
    let emptyState: NewsroomEmptyState?
    let errorState: NewsroomErrorState?

    var asOfAtText: String? {
        asOfAt.map { NewsroomDigestDateFormat.asOfAtText(for: $0) }
    }
}

nonisolated enum NewsroomBriefingType: Equatable, Sendable {
    case hero
    case compact
    case quiet
}

nonisolated struct NewsroomHoldingBriefing: Identifiable, Equatable, Hashable, Sendable {
    let ticker: String
    let name: String
    let weightPercent: Double
    let briefingType: NewsroomBriefingType
    let dailyChangePercent: Double?
    let totalAssetImpactPercent: Double?
    let headline: String?
    let summary: String?
    let detailPath: String?

    var id: String { ticker }
}

nonisolated struct NewsroomEmptyState: Equatable, Sendable {
    let code: String
    let title: String
    let description: String
    let buttonLabel: String
}

nonisolated struct NewsroomErrorState: Equatable, Sendable {
    let title: String
    let summary: String
    let buttonLabel: String
}

// MARK: - 뉴스룸 상세

/// `GET /newsroom/{ticker}` 응답. 목록과 달리 aiJudgement/summary/sources는 상세에서만 온다 —
/// 목록 화면에서 이 값들을 미리 채워둘 방법이 없다(서버가 안 준다).
nonisolated struct NewsroomTickerDetail: Equatable, Sendable {
    let stock: NewsroomStockMeta
    let headline: String
    let imageURL: URL?
    let aiJudgement: NewsroomAIJudgement?
    let summaryBody: String?
    let findings: [String]
    let sources: [NewsroomSourceItem]
    let asOfAt: Date?
    let aiNotice: String?

    var asOfAtText: String? {
        asOfAt.map { NewsroomDigestDateFormat.asOfAtText(for: $0) }
    }

    /// 브리핑만 교체한 사본. 배치가 비는 날 대비용 캐시 병합 결과로 바꿔 끼우는 용도라
    /// 응답에 실려 온 값을 그대로 쓰지 않는다. 자세한 규칙은
    /// `NewsroomAIJudgementStore.resolve(incoming:for:)`에 있다.
    func replacingAIJudgement(_ judgement: NewsroomAIJudgement?) -> NewsroomTickerDetail {
        NewsroomTickerDetail(
            stock: stock,
            headline: headline,
            imageURL: imageURL,
            aiJudgement: judgement,
            summaryBody: summaryBody,
            findings: findings,
            sources: sources,
            asOfAt: asOfAt,
            aiNotice: aiNotice
        )
    }
}

/// AI 판단 블록. 서버가 headline(결론 한 줄)과 reason(근거 문단)을 분리해서 주므로
/// 화면도 둘을 다르게 다룬다 — headline은 항상 노출하고, 분량이 큰 reason은 접어 둔다.
///
/// 예측 모델은 매일 새로 도는데(뉴스 요약과 같은 주기), 그중 하루라도 배치가 비어서
/// 이번 응답에 값이 안 실려 올 수 있다. 그런 날엔 화면이 통째로 비지 않도록
/// 로컬에 캐시해 두고(그래서 Codable) `generatedAt`으로 신선도를 판단한다.
/// "다음 브리핑 예정일" 같은 필드는 없다 — 정해진 주기로 예약 발행되는 게 아니라서다.
nonisolated struct NewsroomAIJudgement: Equatable, Sendable, Codable {
    let title: String?
    let headline: String
    let reason: String?
    let alignment: NewsroomAIAlignment?
    let usedNewsURLs: [URL]
    let disclaimer: String?
    /// 이 브리핑이 생성된 시각. 캐시와 응답 중 무엇이 최신인지 가르는 기준이다.
    let generatedAt: Date?

    var titleText: String { title ?? "AI는 이렇게 판단했어요" }
    var disclaimerText: String { disclaimer ?? "본 내용은 투자 판단의 근거가 아닙니다." }

    var hasReason: Bool {
        guard let reason else { return false }
        return !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var generatedAtText: String? {
        generatedAt.map { NewsroomDigestDateFormat.briefingDateText(for: $0) }
    }
}

/// 뉴스 논조와 모델 신호의 방향성. 서버가 새 값을 추가해도 디코딩이 깨지지 않도록
/// 매핑되지 않는 값은 nil로 두고, 그 경우 화면에서 칩을 아예 그리지 않는다.
nonisolated enum NewsroomAIAlignment: Equatable, Sendable, Codable {
    case positive
    case negative
    case mixed
    case neutral

    init?(rawValue: String) {
        switch rawValue.uppercased() {
        case "POSITIVE", "BULLISH":
            self = .positive
        case "NEGATIVE", "BEARISH":
            self = .negative
        case "MIXED":
            self = .mixed
        case "NEUTRAL", "FLAT":
            self = .neutral
        default:
            return nil
        }
    }

    var label: String {
        switch self {
        case .positive:
            return "긍정 신호"
        case .negative:
            return "부정 신호"
        case .mixed:
            return "혼조"
        case .neutral:
            return "중립"
        }
    }

    /// 캐시 표현. 서버 어휘를 그대로 쓰므로 저장본을 눈으로 확인하기 쉽고,
    /// 매핑 규칙이 바뀌어도 `init?(rawValue:)` 한 곳만 고치면 된다.
    private var storageValue: String {
        switch self {
        case .positive:
            return "POSITIVE"
        case .negative:
            return "NEGATIVE"
        case .mixed:
            return "MIXED"
        case .neutral:
            return "NEUTRAL"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        guard let alignment = NewsroomAIAlignment(rawValue: rawValue) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown alignment: \(rawValue)"
            )
        }
        self = alignment
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(storageValue)
    }
}

nonisolated struct NewsroomStockMeta: Equatable, Sendable {
    let ticker: String
    let name: String
    let dailyChangePercent: Double?
    let weightPercent: Double?
    let totalAssetImpactPercent: Double?
}

nonisolated struct NewsroomSourceItem: Identifiable, Equatable, Sendable {
    let newsId: String?
    let title: String
    let publisher: String
    /// 서버가 ISO8601 파싱에 실패하면 원본 문자열을 그대로 내려주므로 Date로 강제하지 않는다.
    let publishedAtRaw: String?
    let url: URL?

    var id: String { newsId ?? url?.absoluteString ?? title }

    /// 최선 노력 상대 시간 텍스트. 파싱 실패 시 원본 문자열을, 그것도 없으면 nil을 준다.
    var publishedAtRelativeText: String? {
        guard let publishedAtRaw else { return nil }
        guard let date = NewsroomDigestDateFormat.parseISO8601(publishedAtRaw) else {
            return publishedAtRaw
        }
        return NewsroomDigestDateFormat.relativeText(for: date)
    }
}

// MARK: - Date formatting

nonisolated enum NewsroomDigestDateFormat {
    private static let asOfAtFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 HH:mm"
        return formatter
    }()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .short
        return formatter
    }()

    /// 브리핑 날짜는 뉴스 기준시각과 달리 "며칠에 나왔나"만 의미가 있어(시각은 배치 시간일 뿐이다)
    /// 시:분을 떼고 날짜만 보여준다.
    private static let briefingDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter
    }()

    static func asOfAtText(for date: Date) -> String {
        "\(asOfAtFormatter.string(from: date)) 기준"
    }

    static func briefingDateText(for date: Date) -> String {
        briefingDateFormatter.string(from: date)
    }

    static func relativeText(for date: Date) -> String {
        relativeFormatter.localizedString(for: date, relativeTo: Date())
    }

    static func parseISO8601(_ value: String) -> Date? {
        NetworkJSONCoding.parseISO8601(value)
    }
}
