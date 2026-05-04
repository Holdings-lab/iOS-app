import SwiftUI

struct AssetExposureMockData {
    static let dashboard = AssetExposureDashboard(
        summaryItems: [
            PolicyExposureSummaryItem(id: 1, title: "반도체 투자정책", exposurePercent: 28, summary: "SOXX와 빅테크 간접 노출이 겹쳐 있어요.", color: .policyPurple),
            PolicyExposureSummaryItem(id: 2, title: "금리 인하 경로", exposurePercent: 61, summary: "예금·대출·은행 ETF가 같이 노출돼 있어요.", color: .electricBlue),
            PolicyExposureSummaryItem(id: 3, title: "친환경 에너지", exposurePercent: 17, summary: "ICLN이 직접 노출 구간이에요.", color: .emerald),
            PolicyExposureSummaryItem(id: 4, title: "달러 강세", exposurePercent: 24, summary: "달러 현금과 미국 ETF 평가액에 영향을 줘요.", color: .policyAmber)
        ],
        holdingRows: [
            HoldingPolicyExposureRow(
                id: 1,
                holdingName: "SOXX",
                holdingWeightPercent: 18,
                exposures: [
                    PolicyExposureChip(id: 1, title: "반도체 보조금", exposureText: "높음", color: .policyPurple),
                    PolicyExposureChip(id: 2, title: "달러 강세", exposureText: "중간", color: .policyAmber)
                ],
                note: "정책 집행 속도에 따라 체감 변동성이 커질 수 있어요."
            ),
            HoldingPolicyExposureRow(
                id: 2,
                holdingName: "ICLN",
                holdingWeightPercent: 12,
                exposures: [
                    PolicyExposureChip(id: 3, title: "친환경 정책", exposureText: "높음", color: .emerald),
                    PolicyExposureChip(id: 4, title: "정책 지연", exposureText: "중간", color: .policyCoral)
                ],
                note: "방향보다 예산 집행 시차가 더 중요해요."
            ),
            HoldingPolicyExposureRow(
                id: 3,
                holdingName: "KODEX 은행 ETF",
                holdingWeightPercent: 9,
                exposures: [
                    PolicyExposureChip(id: 5, title: "금리 경로", exposureText: "높음", color: .electricBlue),
                    PolicyExposureChip(id: 6, title: "가계대출 규제", exposureText: "중간", color: .policyAmber)
                ],
                note: "금리보다 규제 코멘트에 더 민감할 수 있어요."
            ),
            HoldingPolicyExposureRow(
                id: 4,
                holdingName: "정기예금",
                holdingWeightPercent: 34,
                exposures: [
                    PolicyExposureChip(id: 7, title: "금리 인하", exposureText: "높음", color: .electricBlue),
                    PolicyExposureChip(id: 8, title: "방어력", exposureText: "높음", color: .emerald)
                ],
                note: "정책 충격을 흡수하는 핵심 버퍼예요."
            ),
            HoldingPolicyExposureRow(
                id: 5,
                holdingName: "주택담보대출",
                holdingWeightPercent: 27,
                exposures: [
                    PolicyExposureChip(id: 9, title: "금리 경로", exposureText: "높음", color: .policyCoral),
                    PolicyExposureChip(id: 10, title: "가계대출 규제", exposureText: "중간", color: .policyAmber)
                ],
                note: "정책 해석이 틀리면 생활 현금흐름이 먼저 흔들려요."
            )
        ],
        hiddenBets: [
            HiddenPolicyBet(id: 1, title: "반도체 정책 중복 베팅", overlapPercent: 31, summary: "SOXX와 빅테크 간접 노출을 합치면 단일 ETF보다 정책 집중도가 더 높아요.", color: .policyPurple),
            HiddenPolicyBet(id: 2, title: "금리 경로 과민 구간", overlapPercent: 70, summary: "예금·대출·은행 ETF가 같은 금리 해석에 동시에 반응해요.", color: .electricBlue)
        ],
        defenseReadiness: [
            DefenseReadinessItem(id: 1, title: "현금/달러 방어력", value: "양호", summary: "정책 충격이 와도 2주 방어 버퍼는 있어요.", color: .emerald),
            DefenseReadinessItem(id: 2, title: "정책 집중도", value: "주의", summary: "반도체와 금리 경로에 노출이 몰려 있어요.", color: .policyAmber),
            DefenseReadinessItem(id: 3, title: "과매매 위험", value: "낮음", summary: "지금은 리밸런싱보다 체크포인트 관리가 먼저예요.", color: .electricBlue)
        ],
        noTradeZone: NoTradeZoneNote(
            title: "노트레이드 존",
            summary: "지금 포트폴리오는 굳이 손대지 않아도 되는 구간이 일부 있어요.",
            bullets: [
                "현금/달러 합산 비중이 최소 방어선 10%를 넘어요.",
                "단일 ETF 최대 비중도 아직 45% 아래예요.",
                "정책 이벤트가 연속이라, 발표 전 잦은 조정보다 발표 후 모의 반영이 더 유리해요."
            ]
        ),
        constraints: [
            RebalanceConstraint(id: 1, title: "단일 ETF 최대 비중", value: "45%"),
            RebalanceConstraint(id: 2, title: "최소 현금 비중", value: "10%"),
            RebalanceConstraint(id: 3, title: "수수료 상한", value: "월 0.25%"),
            RebalanceConstraint(id: 4, title: "달러 비중 목표", value: "12~18%")
        ],
        scenarioVariants: [
            RebalanceScenarioVariant(id: 1, title: "기준", suggestedChange: "SOXX +2%", note: "정책 예정대로, 환율 보합", color: .electricBlue),
            RebalanceScenarioVariant(id: 2, title: "비관", suggestedChange: "현금 +5%", note: "PCE와 금리 톤 모두 보수적", color: .policyCoral),
            RebalanceScenarioVariant(id: 3, title: "지연", suggestedChange: "ICLN -2%", note: "전력망 예산 집행 지연", color: .policyAmber),
            RebalanceScenarioVariant(id: 4, title: "낙관", suggestedChange: "SOXX +4%", note: "보조금 총액 상향 + 집행 속도 개선", color: .emerald)
        ],
        executionPlan: [
            RebalanceExecutionStep(id: 1, title: "1단계", detail: "발표 전에는 비중 대신 체크포인트만 저장"),
            RebalanceExecutionStep(id: 2, title: "2단계", detail: "발표 후 24시간 안에 모의 반영으로 수수료와 환전액 확인"),
            RebalanceExecutionStep(id: 3, title: "3단계", detail: "실행 시엔 SOXX +2%, 현금 -2% 범위에서만 움직이기")
        ],
        whyCard: RebalanceWhyCard(
            supportingLines: [
                "반도체 노출은 확대 여지가 있지만 아직 과도하지 않아요.",
                "현금/달러 방어선이 있어 정책 충격을 흡수할 수 있어요.",
                "모의 반영을 먼저 하면 과매매를 줄일 수 있어요."
            ],
            opposingLine: "금리 코멘트가 예상보다 매파적이면 은행 ETF와 대출 부담이 동시에 악화될 수 있어요.",
            projectedExposureChange: "리밸런싱 후 반도체 정책 노출 +4%p, 금리 노출 -3%p"
        )
    )
}
