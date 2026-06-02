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

    // MARK: - State A — 빅테크 (FOMC 주간)

    static let bigTechDetail = SignalThemeDetail(
        theme: .bigTech,
        verdict: .review,
        prediction: SignalPrediction(
            returnPct: -0.8,
            directionLabel: "하락 예상",
            currentPriceText: "$456.20",
            predictedPriceText: "$452.30",
            priceDeltaText: "3.90"
        ),
        signalCards: [
            SignalThemeDetailCard(
                intensity: .veryHigh,
                title: "금리 결정이 빅테크 방향을 가를 수 있어요",
                description: "이번 주 FOMC 금리 발표가 예정돼 있어요.",
                newsTitle: "Fed, 금리 결정 앞두고 불확실성 고조"
            ),
            SignalThemeDetailCard(
                intensity: .high,
                title: "부정적 뉴스가 평소보다 빠르게 쌓이고 있어요",
                description: "최근 5일간 빅테크 관련 부정 뉴스가 평소의 2배예요.",
                newsTitle: "관세 리스크에 애플·엔비디아 동반 하락"
            ),
            SignalThemeDetailCard(
                intensity: .medium,
                title: "시장은 버티는데 뉴스는 흔들리고 있어요",
                description: "가격 흐름과 뉴스 분위기가 반대 방향이에요. 방향이 정해지면 빠르게 움직일 수 있어요.",
                newsTitle: nil
            )
        ],
        trendPoints: [
            SignalTrendPoint(weekLabel: "3주 전", returnPct: 0.2, verdictKind: .watch),
            SignalTrendPoint(weekLabel: "2주 전", returnPct: -0.1, verdictKind: .review),
            SignalTrendPoint(weekLabel: "지난 주", returnPct: -0.5, verdictKind: .review),
            SignalTrendPoint(weekLabel: "이번 주", returnPct: -0.8, verdictKind: .review, isCurrent: true)
        ],
        nextCheckpoints: [
            SignalCheckpoint(
                dateLabel: "5/28 (수)",
                title: "FOMC 금리 결정",
                description: "결과에 따라 이번 신호가 바뀔 수 있어요."
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
            priceDeltaText: "3.88"
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
            priceDeltaText: "0.15"
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
            priceDeltaText: "+0.07"
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
