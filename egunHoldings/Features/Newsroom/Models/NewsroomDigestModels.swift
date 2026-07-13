import Foundation
import SwiftUI

// MARK: - Digest (뉴스룸 다이제스트 — 하루 1회 생성물)

/// 뉴스룸 탭의 루트 화면 모델. severity 축은 오늘탭 `TodayBriefingSeverity`를 그대로 공유한다
/// — 뉴스룸이 별도 상태 체계를 만들지 않는다.
struct NewsroomDigest: Equatable {
    let generatedAt: Date
    /// "다음 업데이트는 내일 아침이에요" — 하루 1회 갱신이 정상임을 반복 학습시키는 문구.
    let nextUpdateText: String
    let severity: TodayBriefingSeverity
    /// 상단 상태 브리핑. calm이면 주간 톤 요약, alert면 "오늘 무슨 일이 있었나".
    let briefingHeadline: String
    let briefingMessage: String
    /// 조건 충족 시에만 브리핑 안에 노출하는 1줄. 상세 화면엔 중복 표시하지 않는다.
    let cautionText: String?
    /// 과거 유사 상황 base rate (alert 전용). 방향 예측이 아닌 사실 서술만 담는다.
    let baseRateText: String?
    /// 내 자산 전체 기준 오늘 등락 — 시장 스토리 상세의 "내 자산 전체" 헤더에 사용.
    let portfolioTodayChangePercent: Double
    /// 시장 공통(매크로) 이슈. 없으면 섹션 자체를 숨긴다.
    let marketStory: NewsroomMarketStory?
    let tickerDigests: [NewsroomTickerDigest]
    /// "이걸 이해하려면" 학습 카드 — 오늘 다이제스트의 개념 태그와 매칭돼 payload에 실려온다.
    let learningCards: [NewsroomLearningContent]
    /// 종료 마커 하단 한 줄 — "52일째 큰 변동 없이 지나가는 중" 같은 heartbeat. 없으면 기본 라인만 표시.
    let heartbeatText: String?

    /// "7월 12일 08:00 기준" — 날짜 정직성 규칙에 따라 모든 요약에 노출한다.
    var referenceText: String {
        NewsroomDigestDateFormat.referenceText(for: generatedAt)
    }

    /// 정렬: materiality high → low → 조용, 같은 그룹 안에서는 보유 비중 순.
    var sortedTickerDigests: [NewsroomTickerDigest] {
        tickerDigests.sorted { lhs, rhs in
            if lhs.sortRank != rhs.sortRank { return lhs.sortRank < rhs.sortRank }
            return lhs.portfolioWeightPercent > rhs.portfolioWeightPercent
        }
    }
}

struct NewsroomMarketStory: Equatable, Hashable {
    let headline: String
    let summary: String
    /// 지금까지의 줄거리 — 리스트 카드에서 인라인으로 펼쳐 보여준다.
    let storyline: String?
    /// "이게 무슨 뜻인가요?" 인라인 번역 콘텐츠.
    let translationText: String?
    let updatedAt: Date
    /// 학습 콘텐츠 페어링용 주제 분류
    let topicCategories: [PolicyNewsCategory]
}

enum NewsroomDigestMateriality: Equatable, Hashable {
    case high
    case low
}

struct NewsroomTickerDigest: Identifiable, Equatable, Hashable {
    let ticker: String
    let name: String
    let hasNews: Bool
    /// 새 소식이 없는 연속 일수. hasNews == true면 0.
    let quietDays: Int
    /// hasNews == false면 nil. 히어로(high)/컴팩트(low) 변형을 결정한다.
    let materiality: NewsroomDigestMateriality?
    /// 오늘 등락. 조용 로우에는 표시하지 않는다.
    let priceChangePercent: Double?
    /// 내 자산 중 비중, 예: 12
    let portfolioWeightPercent: Int
    /// 우산 제목 — 히어로 카드 큰 제목, 컴팩트 로우 한 줄, 상세 화면 제목에 공통으로 쓴다.
    /// hasNews == false면 nil.
    let headline: String?
    /// 리드 문단처럼 이어지는 요약 본문 (2~3문장). 상세 화면 전용, 없으면 문단 섹션을 생략한다.
    let summary: String?
    /// 전날 대비 새로 확인된 사실
    let newFacts: [String]
    /// "이게 무슨 뜻인가요?" 인라인 번역 콘텐츠.
    let translationText: String?
    let topicCategories: [PolicyNewsCategory]
    /// 요약의 근거 자료. 최상위 피드로 노출하지 않고 상세에서만 접근한다.
    let articles: [NewsroomDigestArticle]

    var id: String { ticker }

    /// "3일째 특이사항 없음" — 조용함은 실패가 아니라 능동 감시의 증거다.
    /// quietDays 1이면 "오늘은 특이사항 없음" (Mock 레퍼런스 §1 표기 규칙).
    var quietStatusText: String {
        quietDays <= 1 ? "오늘은 특이사항 없음" : "\(quietDays)일째 특이사항 없음"
    }

    var sortRank: Int {
        switch materiality {
        case .high: return 0
        case .low: return 1
        case nil: return 2
        }
    }

    /// 오늘 등락 × 보유 비중 — "내 총자산 기준 -0.25%"
    var portfolioImpactPercent: Double? {
        guard let priceChangePercent else { return nil }
        return priceChangePercent * Double(portfolioWeightPercent) / 100
    }
}

struct NewsroomDigestArticle: Identifiable, Equatable, Hashable {
    let id: String
    let title: String
    let source: String
    let publishedAt: Date
    let url: URL?
}

// MARK: - 상세 화면 공유 템플릿용 컨텐츠 추상화

/// 종목 다이제스트 상세와 시장 스토리 상세가 같은 템플릿을 쓰기 위한 공통 인터페이스.
enum NewsroomDetailContent: Identifiable, Equatable, Hashable {
    case ticker(NewsroomTickerDigest)
    case marketStory(NewsroomMarketStory, portfolioTodayChangePercent: Double)

    var id: String {
        switch self {
        case .ticker(let digest):
            return "ticker-\(digest.ticker)"
        case .marketStory(let story, _):
            return "market-\(story.headline)"
        }
    }
}

// MARK: - Date Formatting

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
