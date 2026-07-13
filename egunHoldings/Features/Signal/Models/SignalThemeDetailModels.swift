import SwiftUI

// MARK: - SignalThemeDetail
//
// Signal 탭 진입 시("왜 그런지 알아보기" 또는 Signal 탭 직접 진입) 표시되는
// 테마 단위 상세 데이터. 4개 섹션을 채우기 위한 도메인 모델.
//
//  ① 예측 수치       — SignalPrediction
//  ② 이번 주 신호     — [SignalThemeDetailCard]
//  ③ 최근 4주 흐름   — [SignalTrendPoint]
//  ④ 다음 체크포인트  — [SignalCheckpoint]

struct SignalThemeDetail {
    let theme: PortfolioThemeSignal.Theme
    let verdict: PolSignalVerdictKind?
    let prediction: SignalPrediction
    let signalCards: [SignalThemeDetailCard]
    let trendPoints: [SignalTrendPoint]
    let nextCheckpoints: [SignalCheckpoint]
}

// MARK: - SignalPrediction (① 예측 수치)

/// 5거래일 후 예상 수익률 및 가격.
struct SignalPrediction {
    /// 예상 수익률 (%). 음수 = 하락, 양수 = 상승.
    let returnPct: Double
    /// "하락 예상" / "상승 예상" / "횡보 예상" / "강한 하락 예상" 등.
    let directionLabel: String
    /// 현재가 표시 텍스트. 예: "$456.20"
    let currentPriceText: String
    /// 예상가 표시 텍스트. 예: "$452.30"
    let predictedPriceText: String
    /// 가격 변동 절대값 (괄호 안 표시용). 예: "3.90" or "+0.07"
    let priceDeltaText: String
    /// 예측 기준일 표시. 예: "5/28 (목) 기준"
    let asOfDateLabel: String
    /// 예측 대상일 표시. 예: "6/1 (월) 예상"
    let targetDateLabel: String

    enum Direction {
        case up, down, flat

        var arrowSymbol: String {
            switch self {
            case .up:   return "▲"
            case .down: return "▼"
            case .flat: return "●"
            }
        }

        var color: Color {
            switch self {
            case .up:   return PSColor.success
            case .down: return PSColor.danger
            case .flat: return PSColor.textFaint
            }
        }
    }

    /// returnPct 부호 기반 자동 방향. ±0.1% 미만은 횡보로 처리.
    var direction: Direction {
        if returnPct > 0.1 { return .up }
        if returnPct < -0.1 { return .down }
        return .flat
    }

    /// "▼ -0.8%" 같은 표시 텍스트.
    var returnDisplayText: String {
        let sign = returnPct >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", returnPct))%"
    }
}

// MARK: - SignalThemeDetailCard (② 이번 주 눈에 띄는 신호)

/// "이번 주 눈에 띄는 신호" 섹션의 카드 1건.
/// Phase 1.5 — LLM 생성 함의 문장 + 대표 뉴스 제목 포함.
struct SignalThemeDetailCard: Identifiable {
    let id: UUID
    let intensity: Intensity
    /// 함의 문장 (사용자 언어). 예: "금리 결정이 빅테크 방향을 가를 수 있어요"
    let title: String
    /// 근거 + 수치. 예: "최근 5일간 빅테크 관련 부정 뉴스가 평소의 2배예요."
    let description: String
    /// 대표 뉴스 제목. Phase 1에서는 nil, Phase 1.5부터 채워짐.
    let newsTitle: String?
    /// 실제 원문 기사 URL. 있으면 "원문 보기" 링크로 렌더링.
    let newsURL: String?
    /// 출처명. 예: "Yahoo Finance", "Al Jazeera", "CNBC"
    let newsSource: String?

    enum Intensity {
        case veryHigh
        case high
        case medium

        var label: String {
            switch self {
            case .veryHigh: return "매우 높음"
            case .high:     return "높음"
            case .medium:   return "보통"
            }
        }

        var dotColor: Color {
            switch self {
            case .veryHigh: return PSColor.danger
            case .high:     return PSColor.warn
            case .medium:   return Color(hex: "F4C842")
            }
        }

        var labelColor: Color {
            switch self {
            case .veryHigh: return PSColor.danger
            case .high:     return PSColor.warn
            case .medium:   return Color(hex: "C68A00")
            }
        }
    }

    nonisolated init(
        id: UUID = UUID(),
        intensity: Intensity,
        title: String,
        description: String,
        newsTitle: String? = nil,
        newsURL: String? = nil,
        newsSource: String? = nil
    ) {
        self.id = id
        self.intensity = intensity
        self.title = title
        self.description = description
        self.newsTitle = newsTitle
        self.newsURL = newsURL
        self.newsSource = newsSource
    }
}

// MARK: - SignalTrendPoint (③ 최근 4주 신호 흐름)

/// 신호 추이 타임라인의 한 주 데이터.
struct SignalTrendPoint: Identifiable {
    let id: UUID
    /// "3주 전" / "2주 전" / "지난 주" / "이번 주"
    let weekLabel: String
    /// 예상 수익률. nil = 데이터 없음 (placeholder 표시).
    let returnPct: Double?
    /// 해당 주의 배지 종류. nil = 데이터 없음.
    let verdictKind: PolSignalVerdictKind?
    /// "이번 주" 강조 표시 여부.
    let isCurrent: Bool

    nonisolated init(
        id: UUID = UUID(),
        weekLabel: String,
        returnPct: Double?,
        verdictKind: PolSignalVerdictKind?,
        isCurrent: Bool = false
    ) {
        self.id = id
        self.weekLabel = weekLabel
        self.returnPct = returnPct
        self.verdictKind = verdictKind
        self.isCurrent = isCurrent
    }

    var returnDisplayText: String {
        guard let returnPct else { return "—" }
        let sign = returnPct >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", returnPct))%"
    }

    var dotColor: Color {
        guard let verdictKind else { return PSColor.textFaint.opacity(0.4) }
        return verdictKind.sentimentForeground
    }
}

// MARK: - SignalCheckpoint (④ 다음에 볼 이벤트)

/// 다가오는 매크로 이벤트 1건.
struct SignalCheckpoint: Identifiable {
    let id: UUID
    /// "5/28 (수)"
    let dateLabel: String
    /// "FOMC 금리 결정"
    let title: String
    /// "결과에 따라 이번 신호가 바뀔 수 있어요."
    let description: String

    nonisolated init(
        id: UUID = UUID(),
        dateLabel: String,
        title: String,
        description: String
    ) {
        self.id = id
        self.dateLabel = dateLabel
        self.title = title
        self.description = description
    }
}
