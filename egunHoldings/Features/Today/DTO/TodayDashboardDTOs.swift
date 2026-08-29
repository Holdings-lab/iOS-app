import Foundation

// Today 탭은 4개 섹션을 각각 별도 GET으로 조회한다. 모든 필드는 옵셔널이며,
// 누락 시 toDomain(fallback:)에서 mock fallback으로 대체된다.

// MARK: - GET /api/users/{id}/daily-briefing (Section 1)

nonisolated struct TodayDailyBriefingResponseDTO: Decodable {
    // 실서버(2026-07 확인) 응답에는 이 필드가 아예 오지 않는다(대신 assetTotal/ratio/
    // maxDrawdownTolerance 등 문서에 없는 필드가 옴). 필수로 두면 다른 필드가 멀쩡히 와도
    // 디코딩 전체가 실패해 Mock 폴백으로 넘어가 버리므로 옵셔널로 둔다.
    let isAccountLinked: Bool?
    let dailyChangePct: Double?
    let drawdownPct: Double?
    let maxDrawdownTolerance: Double?
    let status: String?
    let message: String?

    func toDomain(fallback: TodayBriefing) -> TodayBriefing {
        let drawdown = drawdownPct ?? fallback.drawdownFromPeakPercent
        return TodayBriefing(
            todayChangePercent: dailyChangePct ?? fallback.todayChangePercent,
            drawdownFromPeakPercent: drawdown,
            severity: TodayDTOMapper.severity(from: status, fallback: fallback.severity),
            message: TodayBriefingMessage.make(
                drawdownPercent: drawdown,
                maxDrawdownTolerance: maxDrawdownTolerance,
                fallback: message ?? fallback.message
            )
        )
    }
}

nonisolated enum TodayBriefingMessage {
    static func make(
        drawdownPercent: Double,
        maxDrawdownTolerance: Double?,
        fallback: String
    ) -> String {
        guard let maxDrawdownTolerance, maxDrawdownTolerance > 0 else {
            return fallback
        }

        let drawdown = abs(min(drawdownPercent, 0))
        let tolerance = maxDrawdownTolerance
        let drawdownText = percentText(drawdown)
        let toleranceText = percentText(tolerance)

        if drawdown == 0 {
            return "포트폴리오가 현재 고점 수준이에요. 설정한 허용 낙폭 -\(toleranceText)%까지 여유가 있어요."
        }

        if drawdown < tolerance * 0.5 {
            return "최근 고점 대비 \(drawdownText)% 하락했어요. 설정한 허용 낙폭 -\(toleranceText)% 안에서 움직이고 있어요."
        }

        if drawdown < tolerance {
            return "최근 고점 대비 \(drawdownText)% 하락했어요. 설정한 허용 낙폭 -\(toleranceText)%에 가까워지고 있어요."
        }

        return "최근 고점 대비 \(drawdownText)% 하락했어요. 설정한 허용 낙폭 -\(toleranceText)%에 도달했으니 포트폴리오를 점검해 보세요."
    }

    private static func percentText(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(format: "%.1f", value)
    }
}

// MARK: - GET /api/users/{id}/holdings (Section 2)

nonisolated struct TodayHoldingsResponseDTO: Decodable {
    // 실서버(2026-07 확인) 응답은 `{ "holdings": [] }`뿐이라 이 필드가 없다. daily-briefing과
    // 동일한 이유로 옵셔널 처리 — 없으면 holdings 유무로 연동 여부를 판단한다.
    let isAccountLinked: Bool?
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
    // 실서버(UserAssetDto.GoalProgressResponse) 응답엔 isAccountLinked가 없다 — daily-briefing/
    // holdings와 동일한 이유로, 목표가 실제로 설정돼 있는지(goalLabel 등 필드 존재)로만 판단한다.
    let isAccountLinked: Bool?
    let goalLabel: String?
    let progressPct: Double?
    let scheduleStatus: String?
    let scheduleNote: String?

    func toDomain(fallback: TodayGoalProgress?) -> TodayGoalProgress? {
        guard let goalLabel, let progressPct, let scheduleStatus else {
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
