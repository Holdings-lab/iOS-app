import SwiftUI

enum PolSignalRoute: Hashable {
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
            return .trendDown
        case .yellow:
            return .warning
        }
    }

    var background: Color {
        switch severity {
        case .red:
            return Color.trendDown.opacity(0.08)
        case .yellow:
            return Color.warningBg
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
