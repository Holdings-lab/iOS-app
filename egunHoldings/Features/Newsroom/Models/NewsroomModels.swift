import Foundation
import SwiftUI

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

struct NewsroomLearningContent: Identifiable, Equatable {
    let id: String
    let author: String
    let publishedText: String
    let title: String
    let summary: String
    let category: PolicyNewsCategory
    let readTimeText: String
    let commentCount: Int
    let heroSystemImage: String
}

extension PolicyNewsCategory {
    var newsroomIconName: String {
        switch self {
        case .semiconductor:
            return "cpu.fill"
        case .interestRate:
            return "building.columns.fill"
        case .energy:
            return "bolt.fill"
        case .macro:
            return "globe.asia.australia.fill"
        case .finance:
            return "creditcard.fill"
        case .ai:
            return "sparkles"
        }
    }
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

    var newsroomIndustryLeadText: String {
        switch sentiment {
        case .positive:
            return "\(category.title) 업종에 긍정적인 재료입니다. 원문 숫자와 발표 시점을 확인하면 됩니다."
        case .neutral:
            return "\(category.title) 업종은 이미 일부 반영된 흐름입니다. 후속 수치 확인이 우선입니다."
        case .caution:
            return "\(category.title) 업종 변동성이 커질 수 있습니다. 확정 전 추격은 보류하는 편이 좋습니다."
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
}
