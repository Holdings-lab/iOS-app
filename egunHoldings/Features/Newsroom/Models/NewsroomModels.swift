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
            return "skim"
        case .detail:
            return "detail"
        case .saved:
            return "saved"
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
