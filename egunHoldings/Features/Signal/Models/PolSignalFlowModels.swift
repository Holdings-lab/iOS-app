import SwiftUI

enum PolSignalRoute: Hashable {
    case list
    case detail(Int)
    case adjustment
}

enum PolSignalFeedTab: String, CaseIterable, Identifiable {
    case myImpact = "내 영향"
    case breaking = "속보"
    case learning = "학습"

    var id: String { rawValue }
}

struct PolSignalExposure: Identifiable {
    let id = UUID()
    let ticker: String
    let weightText: String
    let color: Color
}

struct PolSignalScenario: Identifiable {
    let id = UUID()
    let code: String
    let probability: Int
    let title: String
    let outcome: String
    let note: String
}

struct PolSignalEvent: Identifiable {
    let id: Int
    let feedTab: PolSignalFeedTab
    let category: String
    let institution: String
    let dDay: String
    let title: String
    let verdict: String
    let reason: String
    let expectedImpact: String
    let aiSummary: String
    let ctaTitle: String
    let exposures: [PolSignalExposure]
    let scenarios: [PolSignalScenario]
    let weakeningCondition: String
    let sourceSummary: String
    let checkSchedule: String
    let accentColor: Color
}

extension PolSignalEvent {
    var timeText: String {
        switch feedTab {
        case .myImpact:
            return "09:20"
        case .breaking:
            return "방금 전"
        case .learning:
            return "4분"
        }
    }

    var analysisState: String {
        switch feedTab {
        case .myImpact:
            return "영향 분석 완료"
        case .breaking:
            return "영향 분석 중"
        case .learning:
            return "내 노출 없음"
        }
    }

    var exposureSummary: String {
        exposures
            .prefix(2)
            .map { "\($0.ticker) \($0.weightText)" }
            .joined(separator: " · ")
    }

    var sourceHeadline: String {
        "\(institution) 원문 핵심 요약"
    }
}

struct PolSignalAdjustmentReason: Identifiable {
    let id = UUID()
    let iconName: String
    let title: String
    let detail: String
    let color: Color
}

struct PolSignalAdjustmentEffect: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let color: Color
}

struct PolSignalAdjustmentProposal {
    let badgeText: String
    let indexText: String
    let title: String
    let currentLabel: String
    let currentWeight: Double
    let proposedLabel: String
    let proposedWeight: Double
    let allocationChanges: [String]
    let reasons: [PolSignalAdjustmentReason]
    let effects: [PolSignalAdjustmentEffect]
    let helperText: String
}

struct PolSignalRiskAlert: Identifiable {
    enum Severity {
        case red
        case yellow
    }

    let id = UUID()
    let severity: Severity
    let title: String
    let detail: String

    var color: Color {
        switch severity {
        case .red:
            return PSColor.danger
        case .yellow:
            return PSColor.warn
        }
    }

    var background: Color {
        switch severity {
        case .red:
            return PSColor.dangerBg
        case .yellow:
            return PSColor.warnBg
        }
    }
}

struct PolSignalThemeExposure: Identifiable {
    let id = UUID()
    let title: String
    let percent: Double
    let color: Color
}

struct PolSignalAssetSummary {
    let totalAssetText: String
    let returnBadgeText: String
    let returnColor: Color
    let composition: [PolSignalThemeExposure]
    let riskAlerts: [PolSignalRiskAlert]
    let themeExposures: [PolSignalThemeExposure]
}
