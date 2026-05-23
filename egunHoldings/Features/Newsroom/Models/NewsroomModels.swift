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

enum NewsroomFeedMode: String, CaseIterable, Identifiable {
    case news
    case content

    var id: String { rawValue }

    var title: String {
        switch self {
        case .news:
            return "뉴스"
        case .content:
            return "콘텐츠"
        }
    }

    var subtitle: String {
        switch self {
        case .news:
            return "실시간 속보와 보유 종목 관련 기사"
        case .content:
            return "투자를 이해하기 위한 학습 피드"
        }
    }
}

enum NewsroomNewsFilter: String, CaseIterable, Identifiable {
    case latest
    case holdings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .latest:
            return "실시간 속보"
        case .holdings:
            return "보유 종목 뉴스"
        }
    }
}

struct NewsroomPolicySummaryRequest: Identifiable, Equatable {
    let id = UUID()
    let policyTitle: String
    let relatedAssets: [String]
}

struct NewsroomMarketTicker: Identifiable, Equatable, Hashable {
    let id: String
    let title: String
    let price: String
    let changeText: String
    let isPositive: Bool
    let category: PolicyNewsCategory
    let sparkline: [CGFloat]
}

enum NewsroomMarketQuoteGroup: String, CaseIterable, Identifiable {
    case indexCurrency
    case bond
    case commodity
    case crypto

    var id: String { rawValue }

    var title: String {
        switch self {
        case .indexCurrency:
            return "지수·환율"
        case .bond:
            return "채권"
        case .commodity:
            return "원자재"
        case .crypto:
            return "가상자산"
        }
    }
}

enum NewsroomMarketQuoteRegion: String, CaseIterable, Identifiable {
    case all
    case domestic
    case overseas

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "전체"
        case .domestic:
            return "국내"
        case .overseas:
            return "해외"
        }
    }
}

struct NewsroomMarketQuote: Identifiable, Equatable {
    let id: String
    let name: String
    let valueText: String
    let changeText: String
    let isPositive: Bool
    let group: NewsroomMarketQuoteGroup
    let region: NewsroomMarketQuoteRegion
    let sparkline: [CGFloat]
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

enum NewsroomLearningContentData {
    static let items: [NewsroomLearningContent] = [
        NewsroomLearningContent(
            id: "weekly-investment-points",
            author: "이번 주 투자 포인트",
            publishedText: "1일 전",
            title: "5월 둘째 주, 투자할 때 고려할 점은?",
            summary: "이번 주에는 물가 지표, 금리 발언, 반도체 보조금 일정이 함께 움직입니다.",
            category: .macro,
            readTimeText: "3분",
            commentCount: 11,
            heroSystemImage: "calendar.badge.clock"
        ),
        NewsroomLearningContent(
            id: "semiconductor-cycle",
            author: "지금 뜨는 주식이슈",
            publishedText: "1일 전",
            title: "삼성전자 투자할 때 알아야 하는 반도체 사이클",
            summary: "메모리 반도체 산업은 호황과 불황이 반복되는 사이클 산업입니다.",
            category: .semiconductor,
            readTimeText: "5분",
            commentCount: 8,
            heroSystemImage: "memorychip.fill"
        ),
        NewsroomLearningContent(
            id: "rate-growth-stock",
            author: "투자 기초 노트",
            publishedText: "2일 전",
            title: "금리 인하는 왜 성장주에 영향을 줄까?",
            summary: "할인율, 미래 현금흐름, 달러 흐름을 알면 금리 뉴스의 의미가 보입니다.",
            category: .interestRate,
            readTimeText: "4분",
            commentCount: 5,
            heroSystemImage: "chart.line.uptrend.xyaxis"
        ),
        NewsroomLearningContent(
            id: "etf-rebalance-guide",
            author: "ETF 리밸런싱 가이드",
            publishedText: "3일 전",
            title: "ETF 비중은 언제 다시 맞춰야 할까?",
            summary: "목표 비중과 실제 비중의 차이를 기준으로 과도한 매매를 줄이는 방법입니다.",
            category: .finance,
            readTimeText: "4분",
            commentCount: 4,
            heroSystemImage: "chart.pie.fill"
        )
    ]
}

enum NewsroomMarketData {
    static let tickers: [NewsroomMarketTicker] = [
        NewsroomMarketTicker(
            id: "usdkrw",
            title: "환율",
            price: "1,493.16",
            changeText: "+1.3%",
            isPositive: true,
            category: .macro,
            sparkline: [0.44, 0.48, 0.46, 0.52, 0.57, 0.55, 0.61, 0.66]
        ),
        NewsroomMarketTicker(
            id: "nasdaq",
            title: "Nasdaq Futures",
            price: "29,154.50",
            changeText: "-0.92%",
            isPositive: false,
            category: .semiconductor,
            sparkline: [0.72, 0.70, 0.62, 0.58, 0.64, 0.51, 0.47, 0.45]
        ),
        NewsroomMarketTicker(
            id: "soxx",
            title: "SOXX",
            price: "241.80",
            changeText: "+1.18%",
            isPositive: true,
            category: .semiconductor,
            sparkline: [0.42, 0.48, 0.47, 0.58, 0.63, 0.61, 0.70, 0.76]
        ),
        NewsroomMarketTicker(
            id: "us10y",
            title: "US 10Y",
            price: "4.18",
            changeText: "-0.04",
            isPositive: false,
            category: .interestRate,
            sparkline: [0.66, 0.64, 0.61, 0.59, 0.55, 0.57, 0.51, 0.48]
        ),
        NewsroomMarketTicker(
            id: "oil",
            title: "Crude Oil",
            price: "74.92",
            changeText: "+0.83%",
            isPositive: true,
            category: .energy,
            sparkline: [0.48, 0.52, 0.51, 0.58, 0.63, 0.60, 0.67, 0.72]
        ),
        NewsroomMarketTicker(
            id: "vix",
            title: "VIX",
            price: "18.85",
            changeText: "+2.56%",
            isPositive: true,
            category: .macro,
            sparkline: [0.34, 0.40, 0.36, 0.42, 0.51, 0.57, 0.55, 0.62]
        ),
        NewsroomMarketTicker(
            id: "xlf",
            title: "XLF",
            price: "52.31",
            changeText: "-0.21%",
            isPositive: false,
            category: .finance,
            sparkline: [0.60, 0.62, 0.58, 0.54, 0.57, 0.51, 0.48, 0.46]
        ),
        NewsroomMarketTicker(
            id: "aiq",
            title: "AIQ",
            price: "42.08",
            changeText: "+0.64%",
            isPositive: true,
            category: .ai,
            sparkline: [0.40, 0.45, 0.49, 0.46, 0.52, 0.59, 0.61, 0.68]
        )
    ]

    static let quotes: [NewsroomMarketQuote] = [
        NewsroomMarketQuote(
            id: "usdkrw",
            name: "원/달러 환율",
            valueText: "1,493.16",
            changeText: "+19.21 (1.3%)",
            isPositive: true,
            group: .indexCurrency,
            region: .domestic,
            sparkline: [0.44, 0.48, 0.46, 0.52, 0.57, 0.55, 0.61, 0.66]
        ),
        NewsroomMarketQuote(
            id: "nasdaq",
            name: "나스닥",
            valueText: "26,274.12",
            changeText: "+27.05 (0.1%)",
            isPositive: true,
            group: .indexCurrency,
            region: .overseas,
            sparkline: [0.42, 0.55, 0.62, 0.58, 0.67, 0.61, 0.52, 0.57]
        ),
        NewsroomMarketQuote(
            id: "nasdaq-futures",
            name: "나스닥 100 선물",
            valueText: "29,203",
            changeText: "-221 (0.7%)",
            isPositive: false,
            group: .indexCurrency,
            region: .overseas,
            sparkline: [0.72, 0.64, 0.59, 0.50, 0.45, 0.38, 0.34, 0.40]
        ),
        NewsroomMarketQuote(
            id: "sp500",
            name: "S&P 500",
            valueText: "7,412.84",
            changeText: "+13.91 (0.1%)",
            isPositive: true,
            group: .indexCurrency,
            region: .overseas,
            sparkline: [0.44, 0.52, 0.61, 0.58, 0.66, 0.63, 0.49, 0.55]
        ),
        NewsroomMarketQuote(
            id: "sox",
            name: "필라델피아 반도체",
            valueText: "12,081.04",
            changeText: "+305.54 (2.5%)",
            isPositive: true,
            group: .indexCurrency,
            region: .overseas,
            sparkline: [0.36, 0.44, 0.41, 0.55, 0.63, 0.68, 0.66, 0.72]
        ),
        NewsroomMarketQuote(
            id: "vix",
            name: "VIX",
            valueText: "18.69",
            changeText: "+0.31 (1.6%)",
            isPositive: true,
            group: .indexCurrency,
            region: .overseas,
            sparkline: [0.48, 0.58, 0.62, 0.54, 0.43, 0.40, 0.38, 0.45]
        ),
        NewsroomMarketQuote(
            id: "us10y",
            name: "미국 10년물",
            valueText: "4.18",
            changeText: "-0.04",
            isPositive: false,
            group: .bond,
            region: .overseas,
            sparkline: [0.66, 0.64, 0.61, 0.59, 0.55, 0.57, 0.51, 0.48]
        ),
        NewsroomMarketQuote(
            id: "gold",
            name: "금",
            valueText: "4,712.00",
            changeText: "-0.35%",
            isPositive: false,
            group: .commodity,
            region: .overseas,
            sparkline: [0.58, 0.55, 0.60, 0.51, 0.49, 0.43, 0.45, 0.40]
        ),
        NewsroomMarketQuote(
            id: "bitcoin",
            name: "비트코인",
            valueText: "80,793.90",
            changeText: "-0.30%",
            isPositive: false,
            group: .crypto,
            region: .overseas,
            sparkline: [0.62, 0.61, 0.58, 0.52, 0.49, 0.51, 0.47, 0.45]
        )
    ]
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
