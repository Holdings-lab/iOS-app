import Foundation

/// 뉴스룸 다이제스트 Mock 픽스처 — `뉴스룸-mock-데이터-레퍼런스.md`의 JSON을 Swift 모델로 옮긴 것.
/// 네트워크 레이어와 완전히 분리된 순수 데이터. 문구는 카피 톤 체크를 통과한 상태이므로
/// 임의로 더 자극적으로 바꾸지 말 것.
///
/// Mock 포트폴리오 전제 (§0): QQQ 35% · AAPL 18% · NVDA 12% · MSFT 9% · 현금 등 26%
nonisolated enum NewsroomDigestMockData {

    // MARK: - 공통

    /// generatedAt 06:00 KST 형태 유지 (기준 시각 라인 렌더 검증용). 날짜는 오늘 기준 상대 생성.
    static var generatedAt: Date {
        Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: Date()) ?? Date()
    }

    static let nextUpdateText = "다음 업데이트는 내일 아침이에요"

    private static func hoursBeforeGeneration(_ hours: Double) -> Date {
        generatedAt.addingTimeInterval(-hours * 3600)
    }

    // MARK: - 시나리오 A: calm · 전 종목 조용 (가장 자주 보이는 기본 화면)
    // 검증 포인트: 조용 로우 변형(quietDays 1/3/5/12), 시장 스토리 섹션 숨김, 종료 마커 heartbeat.

    static var calmAllQuiet: NewsroomDigest {
        NewsroomDigest(
            generatedAt: generatedAt,
            nextUpdateText: nextUpdateText,
            severity: .calm,
            briefingHeadline: "시장은 조용한 하루였어요",
            briefingMessage: "보유 종목에 새로운 소식이 없었어요.",
            cautionText: nil,
            baseRateText: nil,
            portfolioTodayChangePercent: 0.1,
            marketStory: nil,
            tickerDigests: [
                quiet(ticker: "QQQ", name: "Invesco QQQ Trust", weight: 35, quietDays: 12),
                quiet(ticker: "AAPL", name: "Apple Inc.", weight: 18, quietDays: 3),
                quiet(ticker: "NVDA", name: "NVIDIA", weight: 12, quietDays: 1),
                quiet(ticker: "MSFT", name: "Microsoft", weight: 9, quietDays: 5)
            ],
            learningCards: [
                NewsroomConceptCards.drawdownHistory,
                NewsroomConceptCards.concentrationRisk
            ],
            heartbeatText: "52일째 큰 변동 없이 지나가는 중"
        )
    }

    // MARK: - 시나리오 B: calm · 일부 종목만 뉴스 (혼재)
    // 검증 포인트: 히어로/컴팩트/조용 동시 렌더, 정렬(high → low → quiet), 시장 스토리 노출,
    // 학습 카드 태그 매칭, 상세 화면 전체 플로우 (NVDA 헤더: 오늘 +1.8% → 총자산 기준 +0.22%).

    static var calmMixed: NewsroomDigest {
        NewsroomDigest(
            generatedAt: generatedAt,
            nextUpdateText: nextUpdateText,
            severity: .calm,
            briefingHeadline: "조용한 편이었어요",
            briefingMessage: "보유 종목 중 2개에 새로운 소식이 있어요.",
            cautionText: nil,
            baseRateText: nil,
            portfolioTodayChangePercent: 0.3,
            marketStory: NewsroomMarketStory(
                headline: "연준 의사록, 9월 금리 인하 가능성 시사로 해석돼",
                summary: "6월 FOMC 의사록 공개 후 위원 다수가 하반기 인하 여지를 언급한 것으로 보도됐어요. 시장 반응은 제한적이었어요.",
                storyline: "연준은 올해 3월과 6월 금리를 동결했고, 시장은 9월 첫 인하를 예상해 왔어요. 이번 의사록은 그 예상을 크게 바꾸지 않았어요.",
                translationText: nil,
                updatedAt: generatedAt,
                topicCategories: [.interestRate, .macro]
            ),
            tickerDigests: [
                NewsroomTickerDigest(
                    ticker: "NVDA",
                    name: "NVIDIA",
                    hasNews: true,
                    quietDays: 0,
                    materiality: .high,
                    priceChangePercent: 1.8,
                    portfolioWeightPercent: 12,
                    headline: "엔비디아, 2분기 실적 발표 — 데이터센터 매출 예상 상회 보도",
                    summary: "엔비디아가 2분기 실적을 발표했어요. 데이터센터 부문 매출이 시장 예상을 웃돌았다는 보도가 이어졌고, 다음 분기 가이던스는 예상 범위 안이었어요.",
                    newFacts: [
                        "데이터센터 매출이 시장 컨센서스를 상회했다고 발표",
                        "3분기 가이던스는 애널리스트 예상 범위 내로 제시"
                    ],
                    // 번역 톤 기준선 (레퍼런스 §2) — 전망·권유 없음.
                    translationText: "실적이 예상보다 좋았다는 뜻이에요. 다만 다음 분기 전망은 '깜짝 놀랄 수준'이 아니라 '예상대로'였어요. 당신 자산에서 엔비디아는 12%를 차지하고 있어요. 오늘 발표로 달라진 사실은 위 두 가지가 전부예요.",
                    topicCategories: [.ai],
                    articles: [
                        NewsroomDigestArticle(
                            id: "nvda-1",
                            title: "Nvidia tops data center revenue estimates in Q2",
                            source: "Reuters",
                            publishedAt: hoursBeforeGeneration(7.8),
                            url: URL(string: "https://example.com/nvda-1")
                        ),
                        NewsroomDigestArticle(
                            id: "nvda-2",
                            title: "Nvidia earnings: what analysts are watching next",
                            source: "Barron's",
                            publishedAt: hoursBeforeGeneration(4.5),
                            url: URL(string: "https://example.com/nvda-2")
                        ),
                        NewsroomDigestArticle(
                            id: "nvda-3",
                            title: "Nvidia guidance lands in line with expectations",
                            source: "Yahoo Finance",
                            publishedAt: hoursBeforeGeneration(3.9),
                            url: URL(string: "https://example.com/nvda-3")
                        )
                    ]
                ),
                NewsroomTickerDigest(
                    ticker: "AAPL",
                    name: "Apple Inc.",
                    hasNews: true,
                    quietDays: 0,
                    materiality: .low,
                    priceChangePercent: nil,
                    portfolioWeightPercent: 18,
                    headline: "애플, 인도 생산 비중 확대 계획 보도",
                    summary: "애플이 인도 내 생산 비중을 늘리는 방안을 검토 중이라는 보도가 있었어요. 회사의 공식 발표는 아직 없어요.",
                    newFacts: ["인도 생산 비중 확대 검토 보도 (공식 발표 아님)"],
                    translationText: nil,
                    topicCategories: [.macro],
                    articles: [
                        NewsroomDigestArticle(
                            id: "aapl-1",
                            title: "Apple weighs expanding India production share",
                            source: "Reuters",
                            publishedAt: hoursBeforeGeneration(11.3),
                            url: URL(string: "https://example.com/aapl-1")
                        )
                    ]
                ),
                quiet(ticker: "QQQ", name: "Invesco QQQ Trust", weight: 35, quietDays: 13),
                quiet(ticker: "MSFT", name: "Microsoft", weight: 9, quietDays: 6)
            ],
            learningCards: [
                NewsroomConceptCards.earningsSeason,
                NewsroomConceptCards.ratesGrowth
            ],
            heartbeatText: nil
        )
    }

    // MARK: - 시나리오 C: alert · 큰 변동일
    // 검증 포인트: alert 브리핑(+base rate), caution 문구, 변동 큰 종목 우선 정렬,
    // 종료 마커 톤 변화, 레이아웃 구조가 calm과 동일함 (전면 경고 화면 없음).
    // 톤 주의: "폭락·충격·비상" 없음 — "하락", "약세"까지만. 숫자는 기사에 있는 것만.

    static var alert: NewsroomDigest {
        NewsroomDigest(
            generatedAt: generatedAt,
            nextUpdateText: nextUpdateText,
            severity: .alert,
            briefingHeadline: "오늘 무슨 일이 있었나",
            briefingMessage: "물가 지표가 예상을 웃돌면서 나스닥이 3.2% 내렸어요.",
            cautionText: "며칠간 변동성이 커질 수 있는 구간이에요. 이런 구간은 지난 4년간 40번 넘게 있었고, 대부분 며칠 안에 지나갔어요.",
            baseRateText: "이 정도 하락은 지난 4년간 30번 이상 있었던 수준이에요.",
            portfolioTodayChangePercent: -1.8,
            marketStory: NewsroomMarketStory(
                headline: "6월 CPI 예상 상회 — 금리 인하 기대 후퇴로 기술주 약세",
                summary: "6월 소비자물가가 시장 예상을 웃돌았어요. 9월 금리 인하 기대가 줄어들면서 금리에 민감한 기술주 중심으로 매도세가 나왔다는 분석이 보도됐어요.",
                storyline: "시장은 연내 두 차례 인하를 가격에 반영해 왔어요. 이번 지표로 그 시점이 늦춰질 수 있다는 우려가 커졌어요.",
                translationText: nil,
                updatedAt: generatedAt,
                topicCategories: [.macro, .interestRate]
            ),
            tickerDigests: [
                NewsroomTickerDigest(
                    ticker: "QQQ",
                    name: "Invesco QQQ Trust",
                    hasNews: true,
                    quietDays: 0,
                    materiality: .high,
                    priceChangePercent: -3.2,
                    portfolioWeightPercent: 35,
                    headline: "나스닥100, 물가 지표 여파로 3.2% 하락 마감",
                    summary: "CPI 발표 이후 지수 전반이 약세였어요. 특히 반도체와 대형 기술주의 낙폭이 컸다고 보도됐어요.",
                    newFacts: [
                        "6월 CPI 전년 대비 상승률이 예상치 상회",
                        "나스닥100 지수 -3.2% 마감"
                    ],
                    translationText: nil,
                    topicCategories: [.macro, .interestRate],
                    articles: [
                        NewsroomDigestArticle(
                            id: "qqq-1",
                            title: "Nasdaq slides 3.2% as CPI tops forecasts",
                            source: "Reuters",
                            publishedAt: hoursBeforeGeneration(0.8),
                            url: URL(string: "https://example.com/qqq-1")
                        ),
                        NewsroomDigestArticle(
                            id: "qqq-2",
                            title: "Hot inflation print pushes rate-cut bets back",
                            source: "Yahoo Finance",
                            publishedAt: hoursBeforeGeneration(0.3),
                            url: URL(string: "https://example.com/qqq-2")
                        )
                    ]
                ),
                // 회사 고유 뉴스 없이 시장 요인으로 빠진 종목 — 그 사실 자체가 핵심 정보라
                // headline에 "새 소식은 없어"를 포함한다 (불안한 보유자에게 가장 안심이 되는 한 줄).
                NewsroomTickerDigest(
                    ticker: "NVDA",
                    name: "NVIDIA",
                    hasNews: true,
                    quietDays: 0,
                    materiality: .high,
                    priceChangePercent: -5.1,
                    portfolioWeightPercent: 12,
                    headline: "엔비디아, 금리 우려 속 5.1% 하락 — 회사 관련 새 소식은 없어",
                    summary: "오늘 하락은 회사 자체 뉴스가 아니라 시장 전체의 금리 우려에 따른 것으로 보도됐어요. 엔비디아에 대한 새로운 사실은 확인되지 않았어요.",
                    newFacts: ["회사 고유의 신규 이슈 없음 — 시장 전반 요인으로 분류"],
                    translationText: nil,
                    topicCategories: [.semiconductor, .macro],
                    articles: [
                        NewsroomDigestArticle(
                            id: "nvda-4",
                            title: "Chip stocks lead declines amid rate worries",
                            source: "Reuters",
                            publishedAt: hoursBeforeGeneration(0.7),
                            url: URL(string: "https://example.com/nvda-4")
                        )
                    ]
                ),
                quiet(ticker: "AAPL", name: "Apple Inc.", weight: 18, quietDays: 1),
                quiet(ticker: "MSFT", name: "Microsoft", weight: 9, quietDays: 7)
            ],
            learningCards: [
                NewsroomConceptCards.cpiExplained,
                // alert 날 우선 매칭 — 공포의 순간에 가장 필요한 개념.
                NewsroomConceptCards.panicSellCost
            ],
            heartbeatText: "이런 날일수록 천천히 보세요"
        )
    }

    // MARK: - Helpers

    private static func quiet(ticker: String, name: String, weight: Int, quietDays: Int) -> NewsroomTickerDigest {
        NewsroomTickerDigest(
            ticker: ticker,
            name: name,
            hasNews: false,
            quietDays: quietDays,
            materiality: nil,
            priceChangePercent: nil,
            portfolioWeightPercent: weight,
            headline: nil,
            summary: nil,
            newFacts: [],
            translationText: nil,
            topicCategories: [],
            articles: []
        )
    }
}

// MARK: - 인하우스 evergreen 개념 카드 (상세 가이드 §1.5 초기 라이브러리 중 Mock 시나리오가 쓰는 6장)

nonisolated enum NewsroomConceptCards {
    static let drawdownHistory = NewsroomLearningContent(
        id: "drawdown-history",
        author: "개념 카드",
        publishedText: "",
        title: "하락은 얼마나 자주 올까 — 드로다운의 역사",
        summary: "주가지수는 역사적으로 매년 여러 차례 고점 대비 5% 안팎의 하락을 겪어 왔어요. 하락의 빈도와 회복까지 걸린 기간을 과거 데이터로 살펴보면, 지금 겪는 하락이 통계적으로 어디쯤인지 가늠할 수 있어요.",
        category: .macro,
        readTimeText: "3분",
        commentCount: 0,
        heroSystemImage: "chart.line.downtrend.xyaxis"
    )

    static let concentrationRisk = NewsroomLearningContent(
        id: "concentration-risk",
        author: "개념 카드",
        publishedText: "",
        title: "한 종목에 몰려 있으면 생기는 일",
        summary: "한 종목의 비중이 크면 그 종목의 등락이 내 자산 전체의 등락을 좌우해요. 비중과 변동성의 관계를 알면, 종목 하나의 뉴스가 내 총자산에 어느 정도 영향인지 숫자로 읽을 수 있어요.",
        category: .finance,
        readTimeText: "2분",
        commentCount: 0,
        heroSystemImage: "chart.pie.fill"
    )

    static let earningsSeason = NewsroomLearningContent(
        id: "earnings-season",
        author: "개념 카드",
        publishedText: "",
        title: "실적 시즌 읽는 법 — 가이던스가 더 중요한 이유",
        summary: "시장은 이미 지나간 분기 실적보다 회사가 제시하는 다음 분기 전망(가이던스)에 더 크게 반응하는 경우가 많아요. 실적 발표 기사에서 어떤 숫자를 순서대로 보면 되는지 정리했어요.",
        category: .ai,
        readTimeText: "3분",
        commentCount: 0,
        heroSystemImage: "doc.text.magnifyingglass"
    )

    static let ratesGrowth = NewsroomLearningContent(
        id: "rates-growth",
        author: "개념 카드",
        publishedText: "",
        title: "금리가 성장주에 미치는 영향",
        summary: "금리가 오르면 미래 이익의 현재 가치가 줄어들어 성장주 주가에 부담이 되는 경향이 있어요. 할인율이라는 개념 하나로 금리 뉴스와 기술주 등락의 연결고리를 이해할 수 있어요.",
        category: .interestRate,
        readTimeText: "2분",
        commentCount: 0,
        heroSystemImage: "percent"
    )

    static let cpiExplained = NewsroomLearningContent(
        id: "cpi-explained",
        author: "개념 카드",
        publishedText: "",
        title: "CPI가 뭐길래 시장이 움직일까",
        summary: "소비자물가지수(CPI)는 금리 결정에 가장 큰 영향을 주는 지표 중 하나예요. 예상치와 실제치의 차이가 왜 주가를 움직이는지, 발표 기사에서 어떤 숫자를 보면 되는지 정리했어요.",
        category: .macro,
        readTimeText: "2분",
        commentCount: 0,
        heroSystemImage: "cart.fill"
    )

    static let panicSellCost = NewsroomLearningContent(
        id: "panic-sell-cost",
        author: "개념 카드",
        publishedText: "",
        title: "떨어진 날 판 사람들은 어떻게 됐을까 — 패닉 셀의 역사적 비용",
        summary: "큰 하락일에 매도한 투자자와 보유를 유지한 투자자의 이후 수익률을 과거 데이터로 비교해 봤어요. 하락 직후 가장 좋은 날들이 몰려 있는 경우가 많았다는 것이 역사적 기록이에요.",
        category: .finance,
        readTimeText: "3분",
        commentCount: 0,
        heroSystemImage: "clock.arrow.circlepath"
    )
}
