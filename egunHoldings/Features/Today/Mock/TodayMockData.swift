import SwiftUI

struct TodayMockData {

    // MARK: - Holdings Top3 (Section 2)

    nonisolated static let holdings: [TodayHolding] = [
        TodayHolding(id: "h1", name: "Invesco QQQ Trust", ticker: "QQQ", category: "기술", weight: 34),
        TodayHolding(id: "h2", name: "iShares Semiconductor", ticker: "SOXX", category: "반도체", weight: 22),
        TodayHolding(id: "h3", name: "Financial Select SPDR", ticker: "XLF", category: "금융", weight: 15),
        TodayHolding(id: "h4", name: "달러 예금", ticker: "USD", category: "현금성 자산", weight: 15),
        TodayHolding(id: "h5", name: "국내 예금", ticker: "KRW", category: "현금성 자산", weight: 14)
    ]

    nonisolated static let emptyHoldings: [TodayHolding] = []

    // MARK: - Briefing (Section 1)

    nonisolated static let briefingCalm = TodayBriefing(
        todayChangePercent: 0.4,
        drawdownFromPeakPercent: -3.0,
        severity: .calm,
        message: "포트폴리오가 고점 근처를 유지하고 있어요. 오늘은 특별히 확인할 게 없어요."
    )

    nonisolated static let briefingWatch = TodayBriefing(
        todayChangePercent: -0.8,
        drawdownFromPeakPercent: -9.0,
        severity: .watch,
        message: "중기 계획 안에서 지켜볼 만한 변화라, 계획에 변화가 없는지 정도만 가볍게 살펴보세요."
    )

    nonisolated static let briefingAlert = TodayBriefing(
        todayChangePercent: -1.2,
        drawdownFromPeakPercent: -11.0,
        severity: .alert,
        message: "자금 사용 시점이 가까워 회복을 기다릴 시간이 부족할 수 있으니, 필요한 자금이 투자되어 있지 않은지 확인해보세요."
    )

    nonisolated static let briefing = briefingCalm

    // MARK: - Goal Progress (Section 3)

    nonisolated static let goalProgressJustStarted = TodayGoalProgress(
        goalLabel: "은퇴자금",
        progressPercent: 12,
        status: .justStarted,
        scheduleDeltaText: "30일 후부터 속도를 알려드려요"
    )

    nonisolated static let goalProgressAhead = TodayGoalProgress(
        goalLabel: "은퇴자금",
        progressPercent: 64,
        status: .ahead,
        scheduleDeltaText: "예정보다 2개월 빠름"
    )

    nonisolated static let goalProgressOnTrack = TodayGoalProgress(
        goalLabel: "은퇴자금",
        progressPercent: 58,
        status: .onTrack,
        scheduleDeltaText: "예정과 거의 일치"
    )

    nonisolated static let goalProgressBehind = TodayGoalProgress(
        goalLabel: "은퇴자금",
        progressPercent: 47,
        status: .behind,
        scheduleDeltaText: "예정보다 3개월 느림"
    )

    nonisolated static let goalProgress: TodayGoalProgress? = goalProgressAhead

    // MARK: - News (Section 4)

    nonisolated static let newsItems: [TodayNewsItem] = [
        TodayNewsItem(id: "art_1", title: "NVIDIA Q1 실적 발표", summary: "매출 +85%, 가이던스 상향 조정", ticker: "QQQ"),
        TodayNewsItem(id: "art_2", title: "한국은행 기준금리 동결", summary: "금리 동결 — 금융섹터 영향 제한적", ticker: "XLF"),
        TodayNewsItem(id: "art_3", title: "필라델피아 반도체 지수 강세", summary: "AI 수요 지속에 반도체 업종 전반 강세", ticker: "SOXX"),
        TodayNewsItem(id: "art_4", title: "미 국채 금리 하락", summary: "금리 하락 시 금융주 순이자마진 압박 우려", ticker: "XLF")
    ]

    nonisolated static let emptyNews: [TodayNewsItem] = []
}
