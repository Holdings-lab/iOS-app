import Foundation

nonisolated enum TodayDashboardBuilder {
    /// 오늘 등락(%)은 실제 스냅샷 값이 있으면 파싱해 반영하되, 고점 대비 낙폭/심각도/문구는
    /// 아직 실계산 로직이 없어 항상 fallback(mock)을 그대로 사용한다.
    static func makeBriefing(
        from snapshot: PortfolioSnapshot,
        fallback: TodayBriefing
    ) -> TodayBriefing {
        TodayBriefing(
            todayChangePercent: parsePercent(snapshot.changePercentText) ?? fallback.todayChangePercent,
            drawdownFromPeakPercent: fallback.drawdownFromPeakPercent,
            severity: fallback.severity,
            message: fallback.message
        )
    }

    private static func parsePercent(_ text: String) -> Double? {
        let normalized = text
            .replacingOccurrences(of: "%", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return Double(normalized)
    }
}
