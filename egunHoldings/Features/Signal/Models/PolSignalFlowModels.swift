import SwiftUI

enum PolSignalRoute: Hashable {
    case list
    case detail(Int)
    case adjustment
    case policyReader(Int)
    /// Today 탭 "왜 그런지 알아보기" 진입용 — 테마별 상세 분석 화면.
    case themeDetail(PortfolioThemeSignal.Theme)
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

    var sentimentLabel: String {
        switch self {
        case .review: return "조심하세요"
        case .watch:  return "지켜봐요"
        case .adjust: return "대응하세요"
        }
    }

    /// Today Top 3 처방 카드 전용 색.
    /// 초보자 시그널 의미(파랑=차분 / 주황=주의 / 빨강=대응)에 맞춰
    /// 다른 화면용 accent·tint와 의도적으로 다르게 매핑합니다.
    var sentimentForeground: Color {
        switch self {
        case .watch:  return PSColor.primary
        case .review: return PSColor.warn
        case .adjust: return PSColor.danger
        }
    }

    var sentimentSoft: Color {
        switch self {
        case .watch:  return PSColor.primarySoft
        case .review: return PSColor.warnBg
        case .adjust: return PSColor.dangerBg
        }
    }

    /// 처방 블록 아이콘 색. 대응(.adjust)은 행동 유도를 위해 의도적으로 success(green).
    var prescriptionIconColor: Color {
        switch self {
        case .watch:  return PSColor.primary
        case .review: return PSColor.warn
        case .adjust: return PSColor.success
        }
    }
}

/// Today Top 3 펼침 카드의 처방 데이터 (금융 초보자용 평어 카피).
struct TodayDecisionPrescription: Equatable {
    /// 평이한 말로 쓴 상황 요약 (티커·전문용어 금지, 최대 2줄).
    let summary: String
    /// 동사형 액션 한 문장. (예: "반도체 비중을 줄이세요")
    let action: String
    /// "지금 N%" 표시용 현재 비중. nil이면 delta 행 숨김.
    let nowPercent: String?
    /// "목표 N%" / "권장 N%" / "유지 N%" 등 자유 텍스트.
    let goalLabel: String?
    /// 백엔드가 LLM으로 생성한 설명 텍스트.
    /// nil = 아직 로드 전(skeleton 상태).
    let narrative: String?
}

/// ThemeExpansionContent 내 내러티브 로딩 상태.
enum NarrativeLoadState: Equatable {
    case idle       // 요청 전
    case loading    // 백엔드 응답 대기 중
    case loaded     // 수신 완료
    case error      // 수신 실패 — 재시도 버튼 표시
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
    let prescription: TodayDecisionPrescription?
}

nonisolated struct PolSignalPolicyKeywordLink: Identifiable, Hashable {
    let kw: String
    let why: String

    var id: String {
        "\(kw)-\(why)"
    }
}

nonisolated struct PolSignalPolicyReading: Identifiable, Hashable {
    let id: Int
    let date: String
    let institution: String
    let sourceURL: URL?
    let title: String
    let keywords: [String]
    let whatHappened: String
    let aiSummary: [String]
    let keywordLinks: [PolSignalPolicyKeywordLink]
    let followUps: [String]
    let readMinutes: Int
}

struct PolSignalAnalysisPayload: Identifiable, Hashable {
    let eventId: Int
    let analysisVersion: String

    var id: String {
        "\(eventId)-\(analysisVersion)"
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

// MARK: - PortfolioThemeSignal

/// Today 탭 Top 3에서 카드 단위로 쓰이는 포트폴리오 테마 신호.
/// 기존 PolSignalEvent(이벤트 단위)와 달리, 테마 수준 집계 값을 담는다.
struct PortfolioThemeSignal: Identifiable {

    enum Theme: String {
        case bigTech       = "빅테크"
        case semiconductor = "반도체"
        case financials    = "금융"
        case greenEnergy   = "친환경"

        var displayName: String { rawValue }

        var sfSymbol: String {
            switch self {
            case .bigTech:       return "desktopcomputer"
            case .semiconductor: return "cpu.fill"
            case .financials:    return "banknote.fill"
            case .greenEnergy:   return "leaf.fill"
            }
        }

        var iconColor: Color {
            switch self {
            case .bigTech:       return PSColor.primary
            case .semiconductor: return PSColor.tagSemi
            case .financials:    return PSColor.warn
            case .greenEnergy:   return PSColor.success
            }
        }

        /// 백엔드 API 요청 및 캐시 키 생성에 사용.
        var tickerId: String {
            switch self {
            case .bigTech:       return "QQQ"
            case .semiconductor: return "SOXX"
            case .financials:    return "XLF"
            case .greenEnergy:   return "ICLN"
            }
        }
    }

    let id: UUID
    let theme: Theme
    /// 사용자의 현재 테마 비중 (퍼센트 정수).
    let myExposurePercent: Int
    /// nil이면 이번 주 신호 없음 상태.
    let verdictKind: PolSignalVerdictKind?
    /// 초보자용 처방 카피. verdictKind != nil 일 때만 존재.
    let prescription: TodayDecisionPrescription?
    /// 신호 없음 상태에서 표시할 다음 예정 이벤트 레이블.
    let nextEventLabel: String?
    /// "왜 그런지 알아보기" 탭 시 Signal 탭으로 이동할 eventId.
    let relatedEventId: Int?
}

// MARK: -

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
