import Combine
import SwiftUI

enum PolSignalRoute: Hashable {
    case list
    case detail(Int)
    case adjustment
    case policyReader(Int)
}

enum PolSignalFeedTab: String, CaseIterable, Identifiable {
    case myImpact = "내 영향"
    case learning = "학습"

    var id: String { rawValue }
}

enum PolSignalVerdictKind {
    case review   // 점검 — 행동 전 확인 필요
    case watch    // 관망 — 지금은 조치 불필요
    case adjust   // 조정 — 능동적 리밸런싱 권장

    var label: String {
        switch self {
        case .review: return "점검"
        case .watch:  return "관망"
        case .adjust: return "조정"
        }
    }

    var accent: Color {
        switch self {
        case .review: return PSColor.danger
        case .watch:  return PSColor.warn
        case .adjust: return PSColor.primary
        }
    }

    var tint: Color {
        switch self {
        case .review: return PSColor.dangerBg
        case .watch:  return PSColor.warnBg
        case .adjust: return PSColor.primarySoft
        }
    }
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
    let verdictKind: PolSignalVerdictKind
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

struct PolSignalPolicyReading: Identifiable, Hashable {
    let id: Int
    let dDay: String
    let institution: String
    let title: String
    let keywords: [String]
    let readingLens: String
    let lensApplication: String
    let whatHappened: String
    let typicalFlow: [String]
    let readMinutes: Int
    let relevantKeywords: [String]
}

struct PolSignalAnalysisPayload: Identifiable, Hashable {
    let eventId: Int
    let analysisVersion: String

    var id: String {
        "\(eventId)-\(analysisVersion)"
    }
}

extension Notification.Name {
    static let polSignalAnalysisPayloadReceived = Notification.Name("PolSignalAnalysisPayloadReceived")
}

@MainActor
final class PushAnalysisCoordinator: ObservableObject {
    @Published var presentedAnalysis: PolSignalAnalysisPayload?

    func present(_ payload: PolSignalAnalysisPayload) {
        presentedAnalysis = payload
    }

    func dismiss() {
        presentedAnalysis = nil
    }
}

extension PolSignalEvent {
    var timeText: String {
        switch feedTab {
        case .myImpact:
            return "09:20"
        case .learning:
            return "4분"
        }
    }

    var analysisState: String {
        switch feedTab {
        case .myImpact:
            return "영향 분석 완료"
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
