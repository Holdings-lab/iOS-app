import Foundation
import SwiftUI

enum NewsroomDigestMode: String, CaseIterable, Identifiable, Equatable {
    case oneMinute = "1분 요약"
    case detail = "자세히"
    case saved = "저장됨"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .oneMinute:
            return "1분 안에 읽기"
        case .detail:
            return "근거와 시나리오"
        case .saved:
            return "나중에 보기"
        }
    }

    var badgeText: String {
        switch self {
        case .oneMinute:
            return "요약"
        case .detail:
            return "분석"
        case .saved:
            return "보관"
        }
    }
}

enum NewsroomInsightMode: Equatable {
    case quick
    case detail

    var title: String {
        switch self {
        case .quick:
            return "1분 요약"
        case .detail:
            return "자세히 분석"
        }
    }

    var loadingMessage: String {
        switch self {
        case .quick:
            return "빠른 판단에 필요한 내용만 정리하고 있어요"
        case .detail:
            return "정책 배경과 자산별 영향을 분석하고 있어요"
        }
    }

    var subtitle: String {
        switch self {
        case .quick:
            return "결론과 행동만 먼저"
        case .detail:
            return "근거와 시나리오까지"
        }
    }

    var readingTimeText: String {
        switch self {
        case .quick:
            return "1분 안에 읽기"
        case .detail:
            return "3분 분석"
        }
    }
}

extension NewsroomDigestMode {
    var insightMode: NewsroomInsightMode {
        switch self {
        case .oneMinute:
            return .quick
        case .detail, .saved:
            return .detail
        }
    }
}

struct NewsroomPolicySummaryRequest: Identifiable, Equatable {
    let id = UUID()
    let policyTitle: String
    let relatedAssets: [String]
}

enum NewsroomRelevanceLevel: Equatable {
    case high
    case medium
    case low

    var badgeText: String {
        switch self {
        case .high:
            return "high"
        case .medium:
            return "medium"
        case .low:
            return "low"
        }
    }
}

struct NewsroomAssetTag: Identifiable {
    let title: String
    let color: Color

    var id: String { title }
}

extension PolicyNewsItem {
    var newsroomRelevanceLevel: NewsroomRelevanceLevel {
        switch id {
        case "semiconductor-subsidy-round2", "bok-rate-hold-preview":
            return .high
        case "energy-transition-roadmap", "pce-cooling-watch", "bank-deposit-rate-cut":
            return .medium
        case "ai-export-guidance", "shipping-carbon-levy":
            return .low
        default:
            if !relatedTickers.isEmpty {
                return .high
            }

            return sentiment == .caution ? .medium : .low
        }
    }

    var newsroomAccentColor: Color {
        switch category {
        case .semiconductor:
            return .policyPurple
        case .interestRate:
            return .electricBlue
        case .energy:
            return .emerald
        case .macro:
            return .policyAmber
        case .finance:
            return .policyCoral
        case .ai:
            return .policyCyan
        }
    }

    var newsroomDirectionColor: Color {
        switch sentiment {
        case .positive:
            return .emerald
        case .neutral:
            return .policyAmber
        case .caution:
            return .policyCoral
        }
    }

    var newsroomDecisionTitle: String {
        switch sentiment {
        case .positive:
            return "분할 매수 고려"
        case .neutral:
            return "확인 후 유지"
        case .caution:
            return "추격 매수 보류"
        }
    }

    var newsroomDecisionDescription: String {
        switch sentiment {
        case .positive:
            return "수혜 가능성은 있지만 원문 숫자와 집행 시점을 확인한 뒤 나눠서 접근하는 편이 적절해요."
        case .neutral:
            return "즉시 비중을 바꿀 근거는 약해요. 발표 문구와 시장 반응을 확인해도 늦지 않아요."
        case .caution:
            return "가격 변동이 먼저 커질 수 있어요. 확정 숫자 전까지는 점검이 우선이에요."
        }
    }

    var newsroomDecisionSummary: String {
        switch sentiment {
        case .positive:
            return "\(category.title) 이슈는 내 관련 자산에 우호적이지만, 바로 크게 늘리기보다 분할 접근이 적절해요."
        case .neutral:
            return "\(category.title) 이슈는 이미 일부 반영된 재료라 지금은 유지하면서 확인할 숫자를 보는 편이 좋아요."
        case .caution:
            return "\(category.title) 이슈는 변동성을 키울 수 있어 추격 매수보다 원문과 후속 숫자 확인이 먼저예요."
        }
    }

    var newsroomDecisionIconName: String {
        switch sentiment {
        case .positive:
            return "cart.badge.plus"
        case .neutral:
            return "pause.circle.fill"
        case .caution:
            return "hand.raised.fill"
        }
    }

    var newsroomDecisionColor: Color {
        switch sentiment {
        case .positive:
            return Color.emerald
        case .neutral:
            return Color.electricBlue
        case .caution:
            return Color.policyCoral
        }
    }

    var newsroomSourceTimeText: String {
        "\(sourceName) · \(relativePublishedText)"
    }

    var newsroomAssetTags: [NewsroomAssetTag] {
        let tickerTags = relatedTickers.map { ticker in
            NewsroomAssetTag(title: ticker, color: newsroomAccentColor)
        }

        if !tickerTags.isEmpty {
            return tickerTags
        }

        return [
            NewsroomAssetTag(title: category.title, color: newsroomAccentColor),
            NewsroomAssetTag(title: newsroomRelevanceLevel.badgeText, color: .electricBlue)
        ]
    }

    var newsroomRelationText: String {
        if !relatedTickers.isEmpty {
            return "\(relatedTickers.joined(separator: " · ")) 노출이 있어 먼저 볼 가치가 있어요."
        }

        return "내 자산 직접 관련도는 낮지만 오늘 시장 맥락을 이해하는 데 필요해요."
    }

    var newsroomCapsuleText: String {
        summary
    }

    var newsroomQuickPoints: [String] {
        [
            newsroomAssetImpactText,
            "확인 기준: \(newsroomCheckConditionText)",
            newsroomRelevanceLevel == .high ? "내 보유자산과 직접 연결된 기사예요." : "시장 맥락용으로 짧게만 확인하면 돼요."
        ]
    }

    var newsroomAssetImpactText: String {
        switch id {
        case "semiconductor-subsidy-round2":
            return "SOXX 비중이 높다면 보조금 집행 속도에 따라 반도체 노출이 먼저 움직일 수 있어요."
        case "bok-rate-hold-preview":
            return "KODEX 은행과 국채 ETF가 금리 문구에 서로 다른 방향으로 반응할 수 있어요."
        case "energy-transition-roadmap":
            return "ICLN 보유분은 수혜 기대가 있지만 실제 예산 배정 산업을 확인해야 해요."
        case "pce-cooling-watch":
            return "성장주 추격보다 발표 숫자 확인이 먼저라 보유 비중 조정은 서두르지 않아도 돼요."
        case "bank-deposit-rate-cut":
            return "금융주보다 예금 금리와 대출 조건 변화가 체감 자산에 더 직접적으로 닿을 수 있어요."
        default:
            return relatedTickers.isEmpty
                ? "현재 포트폴리오와 직접 연결되는 보유자산은 적어 우선순위가 낮아요."
                : newsroomRelationText
        }
    }

    var newsroomCheckConditionText: String {
        switch category {
        case .semiconductor:
            return "보조금 총액, 실제 집행일, SOXX 거래대금 증가 여부"
        case .interestRate:
            return "금리 결정문 문구, 인하 시점 힌트, 원달러 환율 반응"
        case .energy:
            return "예산 배정 산업, 전력망 투자 비중, 후속 입법 일정"
        case .macro:
            return "PCE 전월 대비, 근원 물가, 미국 10년물 금리"
        case .finance:
            return "예금 금리 변경일, 은행 순이자마진, 대출 금리 고시"
        case .ai:
            return "규제 적용 국가, 시행 시점, 대형 플랫폼 영향 범위"
        }
    }

    var newsroomWhyIgnoreText: String {
        switch id {
        case "ai-export-guidance":
            return "현재 보유자산 중 AI 소프트웨어나 클라우드 플랫폼 직접 비중이 낮아 당장 포트폴리오 영향은 제한적이에요."
        case "shipping-carbon-levy":
            return "해운, 물류, 원자재 운송 관련 ETF를 직접 보유하지 않아 우선 확인 대상에서는 뒤로 밀려요."
        default:
            return "현재 보유종목과 직접 연결되는 티커가 적고, 가격에 반영되기까지 확인해야 할 중간 변수가 많아요."
        }
    }
}
