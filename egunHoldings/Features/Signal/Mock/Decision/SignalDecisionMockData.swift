import SwiftUI

nonisolated struct SignalDecisionMockData {
    static let dashboard = SignalDecisionDashboard(
        actionOptions: [
            PolicyActionOption(
                id: 1,
                lane: .increase,
                title: "반도체 보조금 집행 속도 확인 후 SOXX 비중 소폭 확대",
                reason: "총액보다 집행 속도가 빨라질 때 장비 밸류체인에 먼저 자금이 붙을 가능성이 높아요.",
                affectedAssets: ["SOXX", "미국 달러 현금"],
                effectiveWindow: "발표 후 24시간",
                recommendation: "먼저 모의 반영으로 2~3% 확대 시 수수료와 달러 비중 변화를 확인하세요.",
                meta: PolicyCardMeta(
                    status: .scheduled,
                    direction: .positive,
                    exposurePercent: 28,
                    delay: .oneMonth,
                    confidence: 79,
                    supportingEvidence: [
                        "장비업체 수주잔고가 이미 반등하고 있어요.",
                        "정책 집행 시차가 짧아지면 ETF 수급이 먼저 움직일 수 있어요.",
                        "현재 SOXX 비중이 기준보다 2% 낮아 추가 여지가 있어요."
                    ],
                    counterEvidence: "제조사 직접지원 위주면 장비 ETF 반응은 약할 수 있어요.",
                    invalidationCondition: "집행 시점이 3분기 이후로 밀리면 즉시 확대 논리를 접어야 해요.",
                    updateSummary: PolicyUpdateSummary(updatedAtText: "12분 전", sourceText: "상무부 초안 + 산업 캘린더", reviewText: "사람 검수 완료")
                )
            ),
            PolicyActionOption(
                id: 2,
                lane: .reduce,
                title: "금리 코멘트가 매파적이면 은행 ETF 비중 일부 축소",
                reason: "가계대출 규제가 강조되면 은행주 반등 폭보다 변동성 부담이 커질 수 있어요.",
                affectedAssets: ["KODEX 은행 ETF"],
                effectiveWindow: "기자간담회 종료 전까지",
                recommendation: "축소 전 예금 금리 매력과 현금 방어력을 같이 비교하세요.",
                meta: PolicyCardMeta(
                    status: .announced,
                    direction: .negative,
                    exposurePercent: 9,
                    delay: .oneWeek,
                    confidence: 68,
                    supportingEvidence: [
                        "금리 동결보다 대출 규제 톤이 더 중요해졌어요.",
                        "은행 ETF는 시장 기대와 다른 코멘트에 민감해요.",
                        "포트폴리오 전체에서는 방어 목적이 약해졌어요."
                    ],
                    counterEvidence: "예상보다 완화적이면 은행 ETF가 단기 방어 자산으로 다시 부각될 수 있어요.",
                    invalidationCondition: "3년 국채 금리가 10bp 이상 하락하지 않으면 축소 강도를 낮춰야 해요.",
                    updateSummary: PolicyUpdateSummary(updatedAtText: "33분 전", sourceText: "한은 기자간담회", reviewText: "검수 진행 중")
                )
            ),
            PolicyActionOption(
                id: 3,
                lane: .hedge,
                title: "정책 지연 시 현금·달러 비중을 헤지 버퍼로 유지",
                reason: "친환경 전력망 정책은 방향보다 집행 지연 리스크가 커서 현금이 좋은 헤지예요.",
                affectedAssets: ["원화 현금", "달러 현금", "ICLN"],
                effectiveWindow: "이번 달 내내",
                recommendation: "최소 현금 10% 아래로 내려가면 먼저 달러 현금부터 보강하세요.",
                meta: PolicyCardMeta(
                    status: .scheduled,
                    direction: .mixed,
                    exposurePercent: 17,
                    delay: .threeMonths,
                    confidence: 74,
                    supportingEvidence: [
                        "예산 승인 절차가 길어질 가능성이 높아요.",
                        "ICLN은 정책 지연 시 되돌림이 큰 편이에요.",
                        "현재 현금/달러 합산 비중이 방어선 역할을 해요."
                    ],
                    counterEvidence: "예산 확정이 예상보다 빠르면 현금 유지가 기회비용이 될 수 있어요.",
                    invalidationCondition: "상반기 집행이 확정되면 헤지 강도를 줄이고 기회형 모드로 전환하세요.",
                    updateSummary: PolicyUpdateSummary(updatedAtText: "1시간 전", sourceText: "산업부 초안", reviewText: "AI 요약 + 사람 확인")
                )
            ),
            PolicyActionOption(
                id: 4,
                lane: .wait,
                title: "지금은 아무것도 안 하기",
                reason: "PCE 발표 전엔 방향성보다 해석 오류 비용이 더 커서 과매매를 줄이는 편이 유리해요.",
                affectedAssets: ["전체 포트폴리오"],
                effectiveWindow: "PCE 발표 전까지",
                recommendation: "오늘은 수량 조정 대신 체크포인트만 저장하고, 발표 후 모의 반영으로 다시 보세요.",
                meta: PolicyCardMeta(
                    status: .scheduled,
                    direction: .mixed,
                    exposurePercent: 100,
                    delay: .immediate,
                    confidence: 83,
                    supportingEvidence: [
                        "이번 주엔 정책 이벤트가 연속으로 붙어 있어요.",
                        "수수료와 환전 비용이 누적되면 순효과가 약해져요.",
                        "이미 현금/달러 방어선이 최소 기준을 넘어요."
                    ],
                    counterEvidence: "반도체 보조금이 매우 강하게 나오면 대기 전략이 뒤늦게 느껴질 수 있어요.",
                    invalidationCondition: "보조금 총액이 예상치를 크게 웃돌고 달러가 안정되면 대기 전략을 끝내세요.",
                    updateSummary: PolicyUpdateSummary(updatedAtText: "방금", sourceText: "정책 캘린더 통합", reviewText: "사람 검수 완료")
                )
            )
        ],
        transmissionMatches: [
            PolicyTransmissionMatch(
                id: 1,
                policyTitle: "반도체 보조금 확대",
                assetName: "SOXX",
                summary: "단순 테마 매칭이 아니라 설비투자와 장비 매출로 이어지는 전달경로가 선명해요.",
                factors: [
                    TransmissionMatchFactor(id: 1, title: "매출 노출", detail: "장비·소재 매출이 직접적으로 늘어날 가능성이 커요."),
                    TransmissionMatchFactor(id: 2, title: "지역 노출", detail: "미국 내 생산 확대 정책과 지역적으로 맞물려 있어요."),
                    TransmissionMatchFactor(id: 3, title: "원가 구조", detail: "보조금이 CAPEX 부담을 낮춰 투자 의사결정을 앞당겨요.")
                ],
                meta: PolicyCardMeta(
                    status: .scheduled,
                    direction: .positive,
                    exposurePercent: 28,
                    delay: .oneMonth,
                    confidence: 88,
                    supportingEvidence: [
                        "장비주 선행지표가 이미 반등 중이에요.",
                        "정책 문안에 세액공제와 직접보조가 같이 포함돼 있어요.",
                        "SOXX는 장비 비중이 높아 전달경로가 뚜렷해요."
                    ],
                    counterEvidence: "정책 대상이 제조사 중심이면 ETF 체감 효과가 약할 수 있어요.",
                    invalidationCondition: "장비 CAPEX 가이던스가 동반 상향되지 않으면 확신도를 낮춰야 해요.",
                    updateSummary: PolicyUpdateSummary(updatedAtText: "21분 전", sourceText: "정책 문안 + 장비주 가이던스", reviewText: "사람 검수 완료")
                )
            ),
            PolicyTransmissionMatch(
                id: 2,
                policyTitle: "한은 금리 경로 재조정",
                assetName: "KODEX 은행 ETF",
                summary: "금리 그 자체보다 가계대출 톤이 은행 마진과 밸류에이션에 영향을 줘요.",
                factors: [
                    TransmissionMatchFactor(id: 4, title: "금리 민감도", detail: "순이자마진 기대 변화가 ETF 방향성을 바꿔요."),
                    TransmissionMatchFactor(id: 5, title: "규제 노출", detail: "가계대출 관리 강화 여부가 은행주 할인율에 반영돼요."),
                    TransmissionMatchFactor(id: 6, title: "환율 민감도", detail: "외국인 수급이 붙을 때 환율 안정이 필요해요.")
                ],
                meta: PolicyCardMeta(
                    status: .announced,
                    direction: .mixed,
                    exposurePercent: 9,
                    delay: .oneWeek,
                    confidence: 72,
                    supportingEvidence: [
                        "기자간담회 문구 변화가 핵심이에요.",
                        "국내 채권시장이 먼저 반응하고 있어요.",
                        "은행 ETF는 정책 해석 차이에 민감해요."
                    ],
                    counterEvidence: "시장 컨센서스와 거의 같으면 전달경로가 약해질 수 있어요.",
                    invalidationCondition: "금리와 가계대출 관련 코멘트가 모두 중립이면 관망 전환이 맞아요.",
                    updateSummary: PolicyUpdateSummary(updatedAtText: "39분 전", sourceText: "한은 기자간담회", reviewText: "검수 진행 중")
                )
            )
        ],
        scenarios: [
            PolicyScenarioSnapshot(id: 1, title: "기준", portfolioBias: "균형형 유지", targetPositioning: "SOXX +2%, 현금 12%", note: "정책은 예정대로 진행되고 환율은 현재 수준 유지", accentColor: .electricBlue),
            PolicyScenarioSnapshot(id: 2, title: "낙관", portfolioBias: "기회형", targetPositioning: "SOXX +4%, ICLN +2%, 현금 10%", note: "보조금 총액이 기대 이상이고 집행 시차가 짧아질 때", accentColor: .emerald),
            PolicyScenarioSnapshot(id: 3, title: "비관", portfolioBias: "방어형", targetPositioning: "은행 ETF -3%, 현금 +5%", note: "PCE와 금리 톤이 모두 보수적으로 나오면", accentColor: .policyCoral),
            PolicyScenarioSnapshot(id: 4, title: "정책 지연", portfolioBias: "헤지 우선", targetPositioning: "ICLN -2%, 달러 현금 +3%", note: "전력망 예산 집행이 미뤄질 때", accentColor: .policyAmber)
        ],
        ledgers: [
            DecisionEvidenceLedger(
                id: 1,
                title: "반도체 확대 판단 장부",
                supportingEvidence: [
                    "초안상 세액공제율 상향",
                    "장비 CAPEX 선행지표 반등",
                    "SOXX 노출이 직접적"
                ],
                counterEvidence: "실집행이 지연되면 단기 과열만 남을 수 있어요.",
                sourceText: "미 상무부 초안 · 업계 가이던스",
                updatedAtText: "18분 전",
                expiresAtText: "발표 후 24시간까지 유효"
            ),
            DecisionEvidenceLedger(
                id: 2,
                title: "아무것도 안 하기 장부",
                supportingEvidence: [
                    "이번 주 이벤트가 연속으로 겹쳐 있어요.",
                    "현재 현금 비중이 최소 기준을 넘어요.",
                    "수수료와 환전 비용이 누적되면 순효과가 약해져요."
                ],
                counterEvidence: "정책이 매우 강하게 나오면 기회비용이 생길 수 있어요.",
                sourceText: "정책 캘린더 · 포트폴리오 노출도 분석",
                updatedAtText: "방금",
                expiresAtText: "PCE 발표 전까지 유효"
            )
        ]
    )
}
