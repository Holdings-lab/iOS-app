import Foundation

// MARK: - SignalThemeDetailMockData
//
// Signal 탭 진입 시 각 테마별 상세 데이터 mock.
// 디자인 State A~D 시연 데이터:
//   - bigTech       → State A (풍부한 데이터, FOMC 주간)
//   - semiconductor → State C (강한 경고, 모든 신호 만렙)
//   - financials    → State D 변형 (이벤트 없음)
//   - greenEnergy   → State B (평온 주간, 신호 없음)

nonisolated enum SignalThemeDetailMockData {

    static func detail(for theme: PortfolioThemeSignal.Theme) -> SignalThemeDetail {
        switch theme {
        case .bigTech:       return bigTechDetail
        case .semiconductor: return semiconductorDetail
        case .financials:    return financialsDetail
        case .greenEnergy:   return greenEnergyDetail
        }
    }

    // MARK: - State A — 빅테크 QQQ (5/28 기준, 강한 상승 예상)

    static let bigTechDetail = SignalThemeDetail(
        theme: .bigTech,
        verdict: .adjust,
        prediction: SignalPrediction(
            returnPct: 2.6,
            directionLabel: "강한 상승 예상",
            currentPriceText: "$717.54",
            predictedPriceText: "$735.20",
            priceDeltaText: "+17.66",
            asOfDateLabel: "5/28 (목) 기준",
            targetDateLabel: "6/1 (월) 예상"
        ),
        signalCards: [
            SignalThemeDetailCard(
                intensity: .veryHigh,
                title: "AI 반도체 실적이 빅테크 상승을 확인시켜줬어요",
                description: "NVIDIA가 분기 매출 $81.6B(YoY +85%)로 시장 예상을 크게 웃돌았어요. AI 데이터센터 수요가 폭발적으로 늘고 있어요.",
                newsTitle: "NVIDIA Announces Financial Results for First Quarter Fiscal 2027",
                newsURL: "https://finance.yahoo.com/markets/stocks/articles/nvidia-announces-financial-results-first-202000544.html",
                newsSource: "Yahoo Finance"
            ),
            SignalThemeDetailCard(
                intensity: .veryHigh,
                title: "미-이란 휴전 연장으로 지정학 리스크가 줄었어요",
                description: "중동 분쟁 완화로 에너지 공급 불안이 해소되면서 위험자산 선호 심리가 빠르게 회복되고 있어요.",
                newsTitle: "US and Iran reach tentative deal for 60-day truce extension, officials say",
                newsURL: "https://www.aljazeera.com/news/2026/5/28/us-and-iran-reach-tentative-deal-for-60-day-truce-extension-officials-say",
                newsSource: "Al Jazeera"
            ),
            SignalThemeDetailCard(
                intensity: .high,
                title: "미중 관세 완화가 공급망 압박을 덜었어요",
                description: "Trump-Xi 정상회담으로 미중 무역 긴장이 완화되고 미국이 엔비디아 H200 칩의 중국 수출을 허용했어요. 빅테크 공급망과 매출 기대가 함께 개선됐어요.",
                newsTitle: "Trump-Xi summit revives China tech rally hopes as U.S. clears Nvidia H200 sales",
                newsURL: "https://www.cnbc.com/2026/05/14/trump-xi-meeting-china-stocks-ai-rally.html",
                newsSource: "CNBC"
            ),
            SignalThemeDetailCard(
                intensity: .high,
                title: "기술 지표도 강한 상승 모멘텀을 확인했어요",
                description: "QQQ가 '볼린저 밴드(가격의 정상 움직임 범위)' 상단을 돌파했어요. 이 선을 뚫고 올라가면 보통 추세 상승이 이어진다는 신호로 읽혀요.",
                newsTitle: nil
            )
        ],
        trendPoints: [
            SignalTrendPoint(weekLabel: "3주 전", returnPct: 0.4, verdictKind: .watch),
            SignalTrendPoint(weekLabel: "2주 전", returnPct: 1.1, verdictKind: .watch),
            SignalTrendPoint(weekLabel: "지난 주", returnPct: 2.0, verdictKind: .review),
            SignalTrendPoint(weekLabel: "이번 주", returnPct: 2.6, verdictKind: .adjust, isCurrent: true)
        ],
        nextCheckpoints: [
            SignalCheckpoint(
                dateLabel: "6/1 (월)",
                title: "QQQ 예측 대상일",
                description: "5거래일 후 목표가 $735.20 도달 여부를 확인하세요."
            )
        ]
    )

    // MARK: - State C — 반도체 (강한 경고)

    static let semiconductorDetail = SignalThemeDetail(
        theme: .semiconductor,
        verdict: .adjust,
        prediction: SignalPrediction(
            returnPct: -2.1,
            directionLabel: "강한 하락 예상",
            currentPriceText: "$184.50",
            predictedPriceText: "$180.62",
            priceDeltaText: "3.88",
            asOfDateLabel: "5/28 (목) 기준",
            targetDateLabel: "6/1 (월) 예상"
        ),
        signalCards: [
            SignalThemeDetailCard(
                intensity: .veryHigh,
                title: "보조금 발표 결과에 따라 반도체가 크게 움직일 수 있어요",
                description: "CHIPS 2차 배분 발표가 이번 주 예정돼 있어요.",
                newsTitle: "미 상무부, 반도체 보조금 2차 배분 임박"
            ),
            SignalThemeDetailCard(
                intensity: .veryHigh,
                title: "부정 뉴스가 빠르게 쏟아지고 있어요",
                description: "최근 5일간 반도체 관련 부정 뉴스가 평소의 3배 이상이에요.",
                newsTitle: "TSMC 가이던스 하향, 공급망 우려 재점화"
            ),
            SignalThemeDetailCard(
                intensity: .veryHigh,
                title: "뉴스 분위기가 짧은 기간에 크게 흔들렸어요",
                description: "감성 지표가 평소 변동폭의 2배 넘게 움직였어요.",
                newsTitle: "반도체 업황 불확실성에 매도세 가속"
            )
        ],
        trendPoints: [
            SignalTrendPoint(weekLabel: "3주 전", returnPct: -0.3, verdictKind: .review),
            SignalTrendPoint(weekLabel: "2주 전", returnPct: -0.9, verdictKind: .review),
            SignalTrendPoint(weekLabel: "지난 주", returnPct: -1.4, verdictKind: .adjust),
            SignalTrendPoint(weekLabel: "이번 주", returnPct: -2.1, verdictKind: .adjust, isCurrent: true)
        ],
        nextCheckpoints: [
            SignalCheckpoint(
                dateLabel: "5/30 (금)",
                title: "CHIPS 2차 배분 발표",
                description: "보조금 규모와 집행 조건에 따라 변동성이 커질 수 있어요."
            )
        ]
    )

    // MARK: - State D — 금융 (이벤트 없음)

    static let financialsDetail = SignalThemeDetail(
        theme: .financials,
        verdict: .review,
        prediction: SignalPrediction(
            returnPct: -0.4,
            directionLabel: "하락 예상",
            currentPriceText: "$38.10",
            predictedPriceText: "$37.95",
            priceDeltaText: "0.15",
            asOfDateLabel: "5/28 (목) 기준",
            targetDateLabel: "6/1 (월) 예상"
        ),
        signalCards: [
            SignalThemeDetailCard(
                intensity: .high,
                title: "금리 결정이 은행 마진에 영향을 줄 수 있어요",
                description: "이번 주 FOMC 금리 발표가 예정돼 있어요.",
                newsTitle: "대형 은행들, 금리 시나리오별 가이던스 제시"
            ),
            SignalThemeDetailCard(
                intensity: .medium,
                title: "시장 흐름과 뉴스 방향이 엇갈리고 있어요",
                description: "주가는 차분한데 규제 뉴스는 늘고 있어요.",
                newsTitle: "美 금융당국, 지역은행 자본규제 재검토"
            )
        ],
        trendPoints: [
            SignalTrendPoint(weekLabel: "3주 전", returnPct: 0.3, verdictKind: .watch),
            SignalTrendPoint(weekLabel: "2주 전", returnPct: 0.1, verdictKind: .watch),
            SignalTrendPoint(weekLabel: "지난 주", returnPct: -0.2, verdictKind: .review),
            SignalTrendPoint(weekLabel: "이번 주", returnPct: -0.4, verdictKind: .review, isCurrent: true)
        ],
        nextCheckpoints: []   // 이벤트 없음 — 섹션 자체 미표시
    )

    // MARK: - State B — 친환경 (평온 주간, 신호 없음)

    static let greenEnergyDetail = SignalThemeDetail(
        theme: .greenEnergy,
        verdict: .watch,
        prediction: SignalPrediction(
            returnPct: 0.1,
            directionLabel: "횡보 예상",
            currentPriceText: "$72.40",
            predictedPriceText: "$72.47",
            priceDeltaText: "+0.07",
            asOfDateLabel: "5/28 (목) 기준",
            targetDateLabel: "6/1 (월) 예상"
        ),
        signalCards: [],   // 빈 상태 — UI에서 "이번 주는 조용한 한 주예요" 표시
        trendPoints: [
            SignalTrendPoint(weekLabel: "3주 전", returnPct: 0.0, verdictKind: .watch),
            SignalTrendPoint(weekLabel: "2주 전", returnPct: 0.1, verdictKind: .watch),
            SignalTrendPoint(weekLabel: "지난 주", returnPct: -0.1, verdictKind: .watch),
            SignalTrendPoint(weekLabel: "이번 주", returnPct: 0.1, verdictKind: .watch, isCurrent: true)
        ],
        nextCheckpoints: [
            SignalCheckpoint(
                dateLabel: "6/2 (월)",
                title: "IEA 에너지 보고서",
                description: "재생에너지 수요 전망에 따라 친환경 ETF가 영향을 받을 수 있어요."
            )
        ]
    )
}
