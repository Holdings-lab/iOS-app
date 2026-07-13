import Foundation

// Today 탭은 4개 섹션을 각각 별도 GET으로 조회한다. 모든 필드는 옵셔널이며,
// 누락 시 toDomain(fallback:)에서 mock fallback으로 대체된다.

// MARK: - GET /api/users/{id}/daily-briefing (Section 1)

nonisolated struct TodayDailyBriefingResponseDTO: Decodable {
    let isAccountLinked: Bool
    let dailyChangePct: Double?
    let drawdownPct: Double?
    let status: String?
    let message: String?

    func toDomain(fallback: TodayBriefing) -> TodayBriefing {
        TodayBriefing(
            todayChangePercent: dailyChangePct ?? fallback.todayChangePercent,
            drawdownFromPeakPercent: drawdownPct ?? fallback.drawdownFromPeakPercent,
            severity: TodayDTOMapper.severity(from: status, fallback: fallback.severity),
            message: message ?? fallback.message
        )
    }
}

// MARK: - GET /api/users/{id}/holdings (Section 2)

nonisolated struct TodayHoldingsResponseDTO: Decodable {
    let isAccountLinked: Bool
    let holdings: [TodayHoldingDTO]?

    func toDomain(fallback: [TodayHolding]) -> [TodayHolding] {
        guard let holdings else { return fallback }
        return holdings.map { $0.toDomain() }
    }
}

nonisolated struct TodayHoldingDTO: Decodable {
    let ticker: String
    let name: String
    let weightPct: Double

    func toDomain() -> TodayHolding {
        // 서버는 섹터 분류를 내려주지 않아, 종목별로 고유한 색이 배정되도록 ticker를 category로 사용한다.
        TodayHolding(id: ticker, name: name, ticker: ticker, category: ticker, weight: Int(weightPct.rounded()))
    }
}

// MARK: - GET /api/users/{id}/goal (Section 3)

nonisolated struct TodayGoalResponseDTO: Decodable {
    let isAccountLinked: Bool
    let goalLabel: String?
    let progressPct: Double?
    let scheduleStatus: String?
    let scheduleNote: String?

    func toDomain(fallback: TodayGoalProgress?) -> TodayGoalProgress? {
        guard isAccountLinked, let goalLabel, let progressPct, let scheduleStatus else {
            return nil
        }

        return TodayGoalProgress(
            goalLabel: goalLabel,
            progressPercent: Int(progressPct.rounded()),
            status: TodayDTOMapper.goalStatus(from: scheduleStatus, fallback: fallback?.status ?? .justStarted),
            scheduleDeltaText: scheduleNote ?? ""
        )
    }
}

// MARK: - GET /api/users/{id}/holdings-news (Section 4)

nonisolated struct TodayHoldingsNewsResponseDTO: Decodable {
    // `basis`는 isAccountLinked로 100% 결정되는 파생값이라(연동 시 holdings+interests, 미연동 시
    // interests) 별도로 저장하지 않고 디코딩만 허용한다. 헤더 문구는 isAccountLinked를 그대로 재사용한다.
    let items: [TodayNewsItemDTO]?

    func toDomain(fallback: [TodayNewsItem]) -> [TodayNewsItem] {
        guard let items else { return fallback }
        return items.map { $0.toDomain() }
    }
}

nonisolated struct TodayNewsItemDTO: Decodable {
    let id: String
    let ticker: String?
    let headline: String
    let aiSummary: String

    func toDomain() -> TodayNewsItem {
        TodayNewsItem(id: id, title: headline, summary: aiSummary, ticker: ticker)
    }
}

nonisolated private enum TodayDTOMapper {
    static func severity(from value: String?, fallback: TodayBriefingSeverity) -> TodayBriefingSeverity {
        switch value {
        case "NORMAL": return .calm
        case "WATCH": return .watch
        case "ALERT": return .alert
        default: return fallback
        }
    }

    static func goalStatus(from value: String, fallback: TodayGoalStatus) -> TodayGoalStatus {
        switch value {
        case "JUST_STARTED": return .justStarted
        case "AHEAD": return .ahead
        case "ON_TRACK": return .onTrack
        case "BEHIND": return .behind
        default: return fallback
        }
    }
}
