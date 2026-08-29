import SwiftUI

// MARK: - Briefing (Section 1)

enum TodayBriefingSeverity {
    case calm, watch, alert

    /// 4px left accent border color. nil = no accent (calm day).
    var accentColor: Color? {
        switch self {
        case .calm:  return nil
        case .watch: return Color.warning
        case .alert: return Color.trendDown
        }
    }

    /// Color of the large drawdown-from-peak number. On a calm day the sign of the value decides
    /// direction (negative → brand, positive → down/red, zero → default text); watch/alert always
    /// override with their own fixed color regardless of sign.
    func drawdownColor(for percent: Double) -> Color {
        switch self {
        case .calm:
            if percent > 0 { return Color.trendDown }
            if percent < 0 { return Color.brand }
            return Color.textPrimary
        case .watch: return Color.warning
        case .alert: return Color.trendDown
        }
    }
}

struct TodayBriefing {
    /// Today's intraday move, e.g. +0.4. Distinct metric from drawdownFromPeakPercent.
    let todayChangePercent: Double
    /// Distance from the historical peak, always <= 0, e.g. -9.0.
    let drawdownFromPeakPercent: Double
    let severity: TodayBriefingSeverity
    /// Always non-empty, even on a calm day — "nothing to check" is itself the daily value.
    let message: String
}

// MARK: - Holdings Top3 (Section 2)

struct TodayHolding: Identifiable {
    let id: String
    let name: String
    let ticker: String
    let category: String
    let weight: Int
}

// MARK: - Goal Progress (Section 3)

enum TodayGoalStatus {
    case justStarted, ahead, onTrack, behind

    var label: String {
        switch self {
        case .justStarted: return "아직 판단 이르러요"
        case .ahead:        return "계획보다 앞서는 중"
        case .onTrack:       return "계획대로 진행 중"
        case .behind:        return "계획보다 늦어지는 중"
        }
    }

    /// Separate color axis from TodayBriefingSeverity — must not share meaning with watch/alert.
    var color: Color {
        switch self {
        case .justStarted: return Color.textTertiary
        case .ahead:        return Color.brand
        case .onTrack:       return Color.trendUp
        case .behind:        return Color.warning
        }
    }
}

struct TodayGoalProgress {
    /// 서버가 완성된 라벨 문자열을 그대로 내려준다(e.g. "은퇴 자금 목표") — 클라이언트가 FinancialGoal
    /// enum으로 재매핑하지 않는다.
    let goalLabel: String
    let progressPercent: Int
    let status: TodayGoalStatus
    let scheduleDeltaText: String

    /// 실제 진행률은 유지하되, 막대는 카드 폭을 넘지 않도록 표시값만 제한한다.
    var clampedProgressPercent: Int {
        min(max(progressPercent, 0), 100)
    }

    var isGoalAchieved: Bool {
        progressPercent >= 100
    }

    var displayStatusLabel: String {
        isGoalAchieved ? "목표 달성" : status.label
    }

    var displayColor: Color {
        isGoalAchieved ? Color.brand : status.color
    }
}

// MARK: - News (Section 4)

struct TodayNewsItem: Identifiable {
    let id: String
    let title: String
    let summary: String
    let ticker: String?
}

// MARK: - Load State & Dashboard

enum TodayLoadState: Equatable {
    case idle
    case loading
    case loaded
    case usingFallback(message: String?)
}

struct TodayDashboard {
    let userAssetProfile: UserAssetProfile
    let portfolioSnapshot: PortfolioSnapshot
    let isAccountLinked: Bool
    let briefing: TodayBriefing
    let holdings: [TodayHolding]
    let goalProgress: TodayGoalProgress?
    let newsItems: [TodayNewsItem]
}
