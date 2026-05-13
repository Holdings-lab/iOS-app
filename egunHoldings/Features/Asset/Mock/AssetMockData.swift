import SwiftUI

struct AssetMockData {
    static let dashboard = AssetDashboard(
        totalAssetAmount: "₩38,297,509",
        totalProfitSummary: "+₩13,317,275 (+53.3%)",
        totalProfitColor: .policyCoral,
        weeklyAdjustmentNotice: nil,
        accounts: [
            AssetAccount(
                id: 1,
                brokerName: "키움증권",
                accountName: "위탁종합",
                accountNumber: "5797993410",
                totalAmount: "₩33,297,509",
                cashAmount: "₩607,376",
                profitSummary: "+64.1%",
                profitColor: .policyCoral,
                symbol: "building.columns.fill",
                tint: .policyPurple,
                policyTags: [
                    AssetPolicyTag(id: 101, title: "반도체 영향: 강함", color: .electricBlue),
                    AssetPolicyTag(id: 102, title: "성장주 영향: 강함", color: .electricBlue)
                ],
                holdings: [
                    AssetHoldingRow(
                        id: 101,
                        name: "QQQ 인베스코 ETF",
                        weight: "10주",
                        amount: "₩10,444,326",
                        tags: [
                            AssetPolicyTag(id: 1011, title: "성장주 영향: 강함", color: .electricBlue),
                            AssetPolicyTag(id: 1012, title: "금리 영향: 보통", color: .policyCoral)
                        ]
                    ),
                    AssetHoldingRow(
                        id: 102,
                        name: "엔비디아",
                        weight: "22주",
                        amount: "₩7,256,929",
                        tags: [
                            AssetPolicyTag(id: 1021, title: "반도체 영향: 강함", color: .electricBlue),
                            AssetPolicyTag(id: 1022, title: "미중 갈등 영향: 보통", color: .policyCoral)
                        ]
                    ),
                    AssetHoldingRow(
                        id: 103,
                        name: "마이크로소프트",
                        weight: "9주",
                        amount: "₩5,410,648",
                        tags: [
                            AssetPolicyTag(id: 1031, title: "AI 영향: 강함", color: .electricBlue),
                            AssetPolicyTag(id: 1032, title: "성장주 영향: 보통", color: .electricBlue)
                        ]
                    )
                ],
                exposureMetrics: [
                    AssetExposureMetric(id: 101, title: "반도체", percent: 48, symbol: "cpu.fill", color: .electricBlue, trend: .up),
                    AssetExposureMetric(id: 102, title: "성장주", percent: 36, symbol: "sparkles", color: .electricBlue, trend: .up),
                    AssetExposureMetric(id: 103, title: "금리/채권", percent: 16, symbol: "building.columns.fill", color: .policyCoral, trend: .stable)
                ],
                hiddenBets: [
                    HiddenAssetBet(
                        id: 101,
                        title: "반도체·성장주 동시 노출",
                        assets: "QQQ·엔비디아·마이크로소프트",
                        percent: "48%",
                        note: "금리와 수출 규제 뉴스에 같이 반응할 가능성이 커요.",
                        color: .electricBlue
                    )
                ]
            ),
            AssetAccount(
                id: 2,
                brokerName: "토스증권",
                accountName: "해외주식",
                accountNumber: "2038419201",
                totalAmount: "₩5,000,000",
                cashAmount: "₩1,000,000",
                profitSummary: "+12.3%",
                profitColor: .policyCoral,
                symbol: "wallet.pass.fill",
                tint: .electricBlue,
                policyTags: [
                    AssetPolicyTag(id: 201, title: "채권 영향: 강함", color: .electricBlue),
                    AssetPolicyTag(id: 202, title: "방어자산 영향: 보통", color: .emerald)
                ],
                holdings: [
                    AssetHoldingRow(
                        id: 201,
                        name: "TIGER 국채3년",
                        weight: "11.8%",
                        amount: "₩1,600,000",
                        tags: [
                            AssetPolicyTag(id: 2011, title: "채권 영향: 강함", color: .electricBlue),
                            AssetPolicyTag(id: 2012, title: "금리 하락 시 손실 영향: 보통", color: .policyCoral)
                        ]
                    ),
                    AssetHoldingRow(
                        id: 202,
                        name: "GLD",
                        weight: "9.2%",
                        amount: "₩1,250,000",
                        tags: [
                            AssetPolicyTag(id: 2021, title: "달러 영향: 보통", color: .emerald),
                            AssetPolicyTag(id: 2022, title: "방어자산 영향: 강함", color: .emerald)
                        ]
                    )
                ],
                exposureMetrics: [
                    AssetExposureMetric(id: 201, title: "금리/채권", percent: 44, symbol: "building.columns.fill", color: .electricBlue, trend: .stable),
                    AssetExposureMetric(id: 202, title: "달러/환율", percent: 31, symbol: "dollarsign.circle.fill", color: .policyAmber, trend: .down),
                    AssetExposureMetric(id: 203, title: "방어자산", percent: 25, symbol: "shield.fill", color: .emerald, trend: .stable)
                ],
                hiddenBets: [
                    HiddenAssetBet(
                        id: 201,
                        title: "금리와 달러가 함께 작동",
                        assets: "TIGER국채3년·GLD",
                        percent: "31%",
                        note: "금리 발표와 환율 변동을 함께 확인해야 해요.",
                        color: .policyAmber
                    )
                ]
            )
        ],
        exposureMetrics: [
            AssetExposureMetric(id: 1, title: "반도체", percent: 42, symbol: "cpu.fill", color: .electricBlue, trend: .up),
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
                name: "QQQ 인베스코 ETF",
                weight: "10주",
                amount: "₩10,444,326",
                tags: [
                    AssetPolicyTag(id: 1, title: "성장주 영향: 강함", color: .electricBlue),
                    AssetPolicyTag(id: 2, title: "금리 영향: 보통", color: .policyCoral)
                ]
            ),
            AssetHoldingRow(
                id: 2,
                name: "엔비디아",
                weight: "22주",
                amount: "₩7,256,929",
                tags: [
                    AssetPolicyTag(id: 3, title: "반도체 영향: 강함", color: .electricBlue),
                    AssetPolicyTag(id: 4, title: "미중 갈등 영향: 보통", color: .policyCoral)
                ]
            ),
            AssetHoldingRow(
                id: 3,
                name: "마이크로소프트",
                weight: "9주",
                amount: "₩5,410,648",
                tags: [
                    AssetPolicyTag(id: 5, title: "AI 영향: 강함", color: .electricBlue),
                    AssetPolicyTag(id: 6, title: "성장주 영향: 보통", color: .electricBlue)
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
                title: "반도체·성장주 동시 노출",
                assets: "QQQ·엔비디아·마이크로소프트",
                percent: "42%",
                note: "금리와 수출 규제 뉴스에 같이 반응할 가능성이 커요.",
                color: .electricBlue
            ),
            HiddenAssetBet(
                id: 2,
                title: "금리·달러 방어 노출",
                assets: "TIGER국채3년·GLD",
                percent: "28%",
                note: "금리 발표와 환율 변동을 함께 확인해야 해요.",
                color: .policyAmber
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
