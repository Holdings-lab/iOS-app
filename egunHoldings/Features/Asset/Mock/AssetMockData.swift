import SwiftUI

struct AssetMockData {
    static let dashboard = AssetDashboard(
        exposureMetrics: [
            AssetExposureMetric(id: 1, title: "반도체", percent: 42, symbol: "cpu.fill", color: .policyPurple, trend: .up),
            AssetExposureMetric(id: 2, title: "금리/채권", percent: 28, symbol: "building.columns.fill", color: .electricBlue, trend: .stable),
            AssetExposureMetric(id: 3, title: "에너지", percent: 15, symbol: "bolt.fill", color: .emerald, trend: .up),
            AssetExposureMetric(id: 4, title: "달러/환율", percent: 25, symbol: "dollarsign.circle.fill", color: .policyAmber, trend: .down)
        ],
        defenseMetrics: [
            AssetDefenseMetric(id: 1, title: "현금 비중", value: "18%", color: .electricBlue),
            AssetDefenseMetric(id: 2, title: "달러 자산 비중", value: "25%", color: .policyAmber),
            AssetDefenseMetric(id: 3, title: "한 정책에 쏠림", value: "68%", color: .policyPurple),
            AssetDefenseMetric(id: 4, title: "잦은 거래 위험", value: "낮음", color: .emerald)
        ],
        holdingRows: [
            AssetHoldingRow(
                id: 1,
                name: "SOXX",
                weight: "23.6%",
                amount: "₩3,190,000",
                tags: [
                    AssetPolicyTag(id: 1, title: "반도체 영향: 강함", color: .electricBlue),
                    AssetPolicyTag(id: 2, title: "미중 갈등 영향: 보통", color: .policyCoral)
                ]
            ),
            AssetHoldingRow(
                id: 2,
                name: "KODEX 은행",
                weight: "14.8%",
                amount: "₩2,010,000",
                tags: [
                    AssetPolicyTag(id: 3, title: "금리 영향: 강함", color: .policyCoral),
                    AssetPolicyTag(id: 4, title: "대출 규제 영향: 보통", color: .policyAmber)
                ]
            ),
            AssetHoldingRow(
                id: 3,
                name: "ICLN",
                weight: "12.4%",
                amount: "₩1,680,000",
                tags: [
                    AssetPolicyTag(id: 5, title: "에너지 영향: 강함", color: .electricBlue),
                    AssetPolicyTag(id: 6, title: "정책 지연 영향: 보통", color: .policyAmber)
                ]
            ),
            AssetHoldingRow(
                id: 4,
                name: "TIGER 국채3년",
                weight: "11.8%",
                amount: "₩1,600,000",
                tags: [
                    AssetPolicyTag(id: 7, title: "채권 영향: 강함", color: .electricBlue),
                    AssetPolicyTag(id: 8, title: "금리 하락 시 손실 영향: 보통", color: .policyCoral)
                ]
            ),
            AssetHoldingRow(
                id: 5,
                name: "GLD",
                weight: "9.2%",
                amount: "₩1,250,000",
                tags: [
                    AssetPolicyTag(id: 9, title: "달러 영향: 보통", color: .emerald),
                    AssetPolicyTag(id: 10, title: "방어자산 영향: 강함", color: .emerald)
                ]
            )
        ],
        hiddenBets: [
            HiddenAssetBet(
                id: 1,
                title: "금리 정책 중복 노출",
                assets: "KODEX은행·TIGER국채3년",
                percent: "26.6%",
                note: "금리 하락 시 두 자산이 함께 흔들릴 수 있어요.",
                color: .electricBlue
            ),
            HiddenAssetBet(
                id: 2,
                title: "반도체·미중 갈등 이중 노출",
                assets: "SOXX",
                percent: "23.6%",
                note: "수출 규제 시 보조금 효과 상쇄",
                color: .policyPurple
            )
        ],
        rebalanceModes: [
            AssetRebalanceModeRow(id: 1, title: "방어형", description: "현금 30%, 변동성 최소화", symbol: "shield.fill", color: .electricBlue),
            AssetRebalanceModeRow(id: 2, title: "균형형", description: "현 배분 유지, 소폭 조정", symbol: "target", color: .emerald),
            AssetRebalanceModeRow(id: 3, title: "기회형", description: "정책 수혜주 집중 편입", symbol: "arrow.up.right", color: .policyAmber)
        ],
        constraints: [
            AssetConstraint(id: 1, title: "단일 ETF 최대 비중", value: "25%"),
            AssetConstraint(id: 2, title: "최소 현금 비중", value: "10%"),
            AssetConstraint(id: 3, title: "수수료 상한", value: "₩50,000"),
            AssetConstraint(id: 4, title: "달러 목표 비중", value: "20~30%")
        ],
        scenarios: [
            AssetScenarioChange(id: 1, title: "기준", change: "+1.2%", detail: "반도체 +3%, 채권 유지", color: .emerald),
            AssetScenarioChange(id: 2, title: "비관", change: "-1.5%", detail: "현금 +5%, 반도체 -3%", color: .policyCoral),
            AssetScenarioChange(id: 3, title: "지연", change: "+0.3%", detail: "변경 없음", color: .mutedForeground),
            AssetScenarioChange(id: 4, title: "낙관", change: "+3.8%", detail: "에너지 +5%, 금 -3%", color: .emerald)
        ]
    )
}
