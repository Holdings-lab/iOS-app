import SwiftUI

struct SignalMockData {
    static let actionQueue: [PolicyActionQueueItem] = [
        PolicyActionQueueItem(
            id: 1,
            dateRange: "3월 4주차",
            title: "반도체 보조금 발표 전 포지션 점검",
            summary: "SOXX 보유 비중이 높아 발표 당일 변동성 영향을 크게 받을 수 있어요.",
            recommendedAction: "발표 전날 목표 비중을 정하고, 당일에는 분할매수/분할매도로 대응하세요.",
            isHoldingMatched: true,
            color: .policyPurple
        ),
        PolicyActionQueueItem(
            id: 2,
            dateRange: "4월 1주차",
            title: "금리 이벤트 대비 현금 비중 관리",
            summary: "한은·미국 지표가 연속으로 있어 은행 ETF와 성장주가 번갈아 흔들릴 수 있어요.",
            recommendedAction: "리스크 완충을 위해 현금성 비중 5~10%를 유지해두는 전략이 유효해요.",
            isHoldingMatched: true,
            color: .electricBlue
        ),
        PolicyActionQueueItem(
            id: 3,
            dateRange: "4월 2주차",
            title: "클린에너지 리밸런싱 후보 확인",
            summary: "에너지 정책 후속안이 예정되어 ICLN 민감도가 높아질 수 있어요.",
            recommendedAction: "기존 보유 ETF와 상관관계를 비교해 보조 포지션으로만 편입하세요.",
            isHoldingMatched: true,
            color: .emerald
        )
    ]

    static let matches: [PolicyETFMatch] = [
        PolicyETFMatch(
            id: 1,
            policy: "반도체 보조금 2차 배분",
            etf: "SOXX (반도체 ETF)",
            score: 92,
            history: "최근 12개 유사 정책 구간(1개월) 평균 +5.2%",
            symbol: "cpu.fill",
            color: .policyPurple
        ),
        PolicyETFMatch(
            id: 2,
            policy: "한은 기준금리 동결",
            etf: "KODEX 은행 ETF",
            score: 74,
            history: "과거 금리 동결 후 1개월 평균 +1.8%",
            symbol: "building.columns.fill",
            color: .electricBlue
        ),
        PolicyETFMatch(
            id: 3,
            policy: "탄소중립 로드맵 수정안",
            etf: "ICLN (클린에너지 ETF)",
            score: 87,
            history: "에너지 정책 발표 이후 1개월 평균 +3.7%",
            symbol: "bolt.fill",
            color: .emerald
        )
    ]
    
    static let simulatorAllocations: [SimulatorETFAllocation] = [
        SimulatorETFAllocation(
            id: 1,
            ticker: "SOXX",
            name: "반도체 ETF",
            currentWeight: 34,
            recommendedWeight: 32,
            expectedMonthlyReturn: 5.2,
            heldShares: 12,
            unitPrice: 238,
            unitPriceCurrency: .usd,
            color: .policyPurple
        ),
        SimulatorETFAllocation(
            id: 2,
            ticker: "ICLN",
            name: "클린에너지 ETF",
            currentWeight: 27,
            recommendedWeight: 28,
            expectedMonthlyReturn: 3.7,
            heldShares: 95,
            unitPrice: 18.6,
            unitPriceCurrency: .usd,
            color: .emerald
        ),
        SimulatorETFAllocation(
            id: 3,
            ticker: "KODEX 은행",
            name: "은행 ETF",
            currentWeight: 21,
            recommendedWeight: 24,
            expectedMonthlyReturn: 1.8,
            heldShares: 190,
            unitPrice: 10_200,
            unitPriceCurrency: .krw,
            color: .electricBlue
        )
    ]

    static let simulatorContent = SimulatorContent(
        title: "투자 시뮬레이터",
        subtitle: "보유 중인 전체 ETF를 직접 리밸런싱해보세요",
        disclaimer: "과거 데이터 기반 시뮬레이션이며, 실제 수익을 보장하지 않습니다.",
        ctaTitle: "한 달 리밸런싱 안 적용하기",
        etfPoolAmount: 5_280_000,
        feeRatePercent: 0.12,
        cashKRWAmount: 1_200_000,
        cashUSDAmount: 600
    )

    static let rebalancingScoreConfig = RebalancingScoreConfig(
        singleETFWeightCapPercent: 45,
        minimumCashReservePercent: 10,
        recommendedCashReserveRange: .init(min: 10, max: 25),
        reserveExpectedMonthlyReturn: 0.2,
        baseDownturnPenalty: 2.4,
        turnoverPenaltyPerPercent: 0.03,
        concentrationPenaltyStart: 3500,
        concentrationPenaltyDivisor: 500,
        cashDeficitPenaltyPerPercent: 0.06,
        netBaseScore: 60,
        netImprovementWeight: 14,
        turnoverPenaltyStart: 15,
        turnoverPenaltyWeight: 0.8,
        netConcentrationPenaltyStart: 3600,
        netConcentrationPenaltyDivisor: 25,
        netCashDeficitPenaltyPerPercent: 0.9,
        diversificationGoodMin: 70,
        diversificationWarningMin: 40,
        netEffectGoodMin: 70,
        netEffectWarningMin: 45
    )
}
