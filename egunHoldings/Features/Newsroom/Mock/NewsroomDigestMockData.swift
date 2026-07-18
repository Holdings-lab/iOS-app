import Foundation

/// 새 뉴스룸 스펙의 리스트·상세·오프라인 상태를 검증하는 순수 Mock 데이터.
nonisolated enum NewsroomDigestMockData {
    static var generatedAt: Date {
        Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: Date()) ?? Date()
    }

    static let nextUpdateText = "다음 업데이트는 내일 아침이에요"

    private static func hoursBeforeGeneration(_ hours: Double) -> Date {
        generatedAt.addingTimeInterval(-hours * 3600)
    }

    static var calmAllQuiet: NewsroomDigest {
        NewsroomDigest(
            generatedAt: generatedAt,
            nextUpdateText: nextUpdateText,
            isOffline: false,
            macroIssue: nil,
            tickerDigests: [
                quiet(ticker: "QQQ", name: "Invesco QQQ Trust", weight: 35, quietDays: 12),
                quiet(ticker: "AAPL", name: "Apple", weight: 18, quietDays: 3),
                quiet(ticker: "NVDA", name: "NVIDIA", weight: 12, quietDays: 1),
                quiet(ticker: "MSFT", name: "Microsoft", weight: 9, quietDays: 5)
            ]
        )
    }

    static var calmMixed: NewsroomDigest {
        NewsroomDigest(
            generatedAt: generatedAt,
            nextUpdateText: nextUpdateText,
            isOffline: false,
            macroIssue: nil,
            tickerDigests: [
                nvidia,
                apple,
                microsoft,
                quiet(ticker: "QQQ", name: "Invesco QQQ Trust", weight: 35, quietDays: 13)
            ]
        )
    }

    /// 같은 금리 기사가 QQQ·AAPL·MSFT 피드에 겹친 날의 예외 배너 시나리오.
    static var alert: NewsroomDigest {
        NewsroomDigest(
            generatedAt: generatedAt,
            nextUpdateText: nextUpdateText,
            isOffline: false,
            macroIssue: NewsroomMacroIssue(
                headline: "금리 인하 기대 변화가 보유 기술주 전반에 반영됐어요",
                summary: "같은 금리 관련 보도가 QQQ, AAPL, MSFT 피드에 함께 나타났어요. 개별 종목 이슈와 분리해 포트폴리오 공통 흐름으로 정리했어요.",
                affectedTickers: ["QQQ", "AAPL", "MSFT"]
            ),
            tickerDigests: [
                nvidia,
                apple,
                microsoft,
                quiet(ticker: "QQQ", name: "Invesco QQQ Trust", weight: 35, quietDays: 2)
            ]
        )
    }

    static var cachedOffline: NewsroomDigest {
        NewsroomDigest(
            generatedAt: generatedAt.addingTimeInterval(-24 * 3600),
            nextUpdateText: "연결되면 최신 브리핑을 확인할게요",
            isOffline: true,
            macroIssue: calmMixed.macroIssue,
            tickerDigests: calmMixed.tickerDigests
        )
    }

    private static var nvidia: NewsroomTickerDigest {
        NewsroomTickerDigest(
            ticker: "NVDA",
            name: "NVIDIA",
            hasNews: true,
            quietDays: 0,
            priceChangePercent: 1.8,
            portfolioWeightPercent: 12,
            logoURL: nil,
            headline: "엔비디아, 데이터센터 매출 예상 상회 속 다음 분기 전망 제시",
            subheadline: "실적은 예상을 웃돌았고 다음 분기 가이던스는 예상 범위 안이었어요.",
            summary: "엔비디아가 2분기 실적을 발표했어요. 데이터센터 부문 매출이 시장 예상을 웃돌았다는 보도가 이어졌고, 다음 분기 가이던스는 예상 범위 안이었어요.",
            newFacts: [
                "데이터센터 매출이 시장 컨센서스를 상회했다고 발표",
                "3분기 가이던스는 애널리스트 예상 범위 내로 제시"
            ],
            aiView: "뉴스 분위기는 긍정적이지만 실적 발표 직후에는 변동성이 커질 수 있는 구간이에요.",
            representativeImageURL: nil,
            imageAttribution: nil,
            articles: [
                article(id: "nvda-1", title: "Nvidia tops data center revenue estimates in Q2", source: "Reuters", hoursAgo: 7.8),
                article(id: "nvda-2", title: "Nvidia guidance lands in line with expectations", source: "Yahoo Finance", hoursAgo: 3.9)
            ]
        )
    }

    private static var apple: NewsroomTickerDigest {
        NewsroomTickerDigest(
            ticker: "AAPL",
            name: "Apple",
            hasNews: true,
            quietDays: 0,
            priceChangePercent: -0.6,
            portfolioWeightPercent: 18,
            logoURL: nil,
            headline: "애플, 인도 생산 비중 확대 계획 보도",
            subheadline: "공급망 다변화 움직임이 이어졌지만 회사의 공식 발표는 아직 없어요.",
            summary: "애플이 인도 내 생산 비중을 늘리는 방안을 검토 중이라는 보도가 있었어요. 회사의 공식 발표는 아직 없어요.",
            newFacts: ["인도 생산 비중 확대를 검토 중이라는 보도가 나왔어요"],
            aiView: "공급망 다변화는 장기 이슈라서 단일 보도만으로 단기 방향을 판단하기는 어려워요.",
            representativeImageURL: nil,
            imageAttribution: nil,
            articles: [
                article(id: "aapl-1", title: "Apple weighs expanding India production share", source: "Reuters", hoursAgo: 11.3)
            ]
        )
    }

    private static var microsoft: NewsroomTickerDigest {
        NewsroomTickerDigest(
            ticker: "MSFT",
            name: "Microsoft",
            hasNews: true,
            quietDays: 0,
            priceChangePercent: 0.2,
            portfolioWeightPercent: 9,
            logoURL: nil,
            headline: "마이크로소프트, 클라우드 인프라 투자 계획 재확인",
            subheadline: "AI 수요 대응을 위한 데이터센터 투자가 이어질 예정이에요.",
            summary: "마이크로소프트가 클라우드와 AI 수요 대응을 위한 인프라 투자 계획을 재확인했어요.",
            newFacts: [],
            aiView: "투자 확대는 수요 기대와 비용 부담을 함께 봐야 하는 신호예요.",
            representativeImageURL: nil,
            imageAttribution: nil,
            articles: [
                article(id: "msft-1", title: "Microsoft reiterates cloud infrastructure plans", source: "Bloomberg", hoursAgo: 5.2)
            ]
        )
    }

    private static func quiet(
        ticker: String,
        name: String,
        weight: Int,
        quietDays: Int
    ) -> NewsroomTickerDigest {
        NewsroomTickerDigest(
            ticker: ticker,
            name: name,
            hasNews: false,
            quietDays: quietDays,
            priceChangePercent: nil,
            portfolioWeightPercent: weight,
            logoURL: nil,
            headline: nil,
            subheadline: nil,
            summary: nil,
            newFacts: [],
            aiView: nil,
            representativeImageURL: nil,
            imageAttribution: nil,
            articles: []
        )
    }

    private static func article(
        id: String,
        title: String,
        source: String,
        hoursAgo: Double
    ) -> NewsroomDigestArticle {
        NewsroomDigestArticle(
            id: id,
            title: title,
            source: source,
            publishedAt: hoursBeforeGeneration(hoursAgo),
            url: URL(string: "https://example.com/\(id)")
        )
    }
}
