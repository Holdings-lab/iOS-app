import SwiftUI

struct HomePolicyImpactMockData {
    static let dashboard = HomePolicyDashboard(
        topPolicies: [
            HomeImpactPolicy(
                id: 1,
                title: "미국 반도체 보조금 확대안",
                dDayText: "D-1",
                summary: "반도체 설비투자 보조금이 시장 기대치를 웃돌면 SOXX와 장비 밸류체인 노출이 큰 자산이 먼저 반응할 가능성이 높아요.",
                actionHint: "발표 직후 총액보다 집행 속도와 대상 장비 범위를 먼저 확인하세요.",
                judgment: HomePolicyJudgment(
                    action: .wait,
                    relevanceSummary: "내 자산 28%가 영향권에 있어요.",
                    keyReason: "SOXX 노출이 커서 발표 직후 체감이 빠를 수 있어요.",
                    thresholdSummary: "총 지원 규모가 4조 달러 이상이면 확대 검토예요.",
                    validUntilSummary: "발표 후 24시간까지 집중 확인이 유효해요.",
                    failureSummary: "집행 시점이 3분기 이후로 밀리면 해석을 낮춰야 해요."
                ),
                meta: PolicyCardMeta(
                    status: .scheduled,
                    direction: .positive,
                    exposurePercent: 28,
                    delay: .oneMonth,
                    confidence: 82,
                    supportingEvidence: [
                        "초안 기준 세액공제율이 기존 예상보다 높아요.",
                        "장비·소재 업체 CAPEX 가이던스가 동반 상향되고 있어요.",
                        "SOXX 보유 비중이 18%라 직접 노출 구간이 분명해요."
                    ],
                    counterEvidence: "실제 집행 시점이 3분기로 밀리면 단기 랠리는 약해질 수 있어요.",
                    invalidationCondition: "총 지원 규모가 4조 달러 미만이거나, 장비 대신 제조사 직접지원 위주로 바뀌면 해석을 낮춰야 해요.",
                    updateSummary: PolicyUpdateSummary(
                        updatedAtText: "18분 전",
                        sourceText: "미 상무부 초안 + 산업부 브리핑",
                        reviewText: "최신 내용 업데이트 완료"
                    )
                ),
                transmissionPath: [
                    PolicyTransmissionStep(id: 1, title: "정책", subtitle: "반도체 보조금 확대", symbol: "building.columns.fill", color: .electricBlue),
                    PolicyTransmissionStep(id: 2, title: "변수", subtitle: "설비투자 기대와 세액공제율", symbol: "slider.horizontal.3", color: .policyPurple),
                    PolicyTransmissionStep(id: 3, title: "산업", subtitle: "장비·소재 밸류체인", symbol: "cpu.fill", color: .policyPurple),
                    PolicyTransmissionStep(id: 4, title: "ETF", subtitle: "SOXX · 반도체 장비 테마", symbol: "chart.bar.fill", color: .emerald),
                    PolicyTransmissionStep(id: 5, title: "내 자산", subtitle: "SOXX 18% + 빅테크 간접 노출", symbol: "wallet.pass.fill", color: .policyAmber)
                ],
                checkpoints: [
                    WeeklyPolicyCheckpoint(
                        id: 1,
                        title: "지원 총액",
                        metric: "발표문 총액",
                        threshold: "4조 달러 이상",
                        whyItMatters: "시장 기대 이상이면 장비주 민감도가 더 커져요.",
                        category: .policy
                    ),
                    WeeklyPolicyCheckpoint(
                        id: 2,
                        title: "SOXX 프리마켓 반응",
                        metric: "프리마켓 상승폭",
                        threshold: "2% 이상 상승 유지",
                        whyItMatters: "발표 직후 실제 수혜 해석이 가격에 반영되는지 확인해요.",
                        category: .market
                    )
                ],
                alerts: ["발표 전날 오후 6시", "발표 직후 15분", "무효화 조건 발생 시"]
            ),
            HomeImpactPolicy(
                id: 2,
                title: "한은 금리 경로 재조정",
                dDayText: "오늘",
                summary: "예금, 은행 ETF, 주담대까지 동시에 걸쳐 있어서 내 지갑 기준 영향 범위가 가장 넓은 이벤트예요.",
                actionHint: "금리 인하 여부보다 코멘트에서 경기 둔화와 가계대출을 어떻게 같이 언급하는지 보세요.",
                judgment: HomePolicyJudgment(
                    action: .hedge,
                    relevanceSummary: "내 자산 61%가 금리 변화 영향권에 있어요.",
                    keyReason: "예금, 주담대, 은행 ETF가 동시에 반응할 수 있어요.",
                    thresholdSummary: "3년 국채가 10bp 이상 움직이면 해석을 다시 봐야 해요.",
                    validUntilSummary: "기자간담회 종료 후 장 마감 전까지가 핵심이에요.",
                    failureSummary: "의사록 톤이 중립적이면 적극 대응 필요가 줄어들어요."
                ),
                meta: PolicyCardMeta(
                    status: .announced,
                    direction: .mixed,
                    exposurePercent: 61,
                    delay: .oneWeek,
                    confidence: 76,
                    supportingEvidence: [
                        "정기예금 34%와 주담대 27%가 동시에 노출돼 있어요.",
                        "KODEX 은행 ETF가 9%라 금리 톤 변화에 즉시 반응할 수 있어요.",
                        "최근 원화 약세 구간과 겹쳐 자산 방어력 판단이 중요해졌어요."
                    ],
                    counterEvidence: "금리 동결이라도 포워드 가이던스가 중립이면 실제 자산 변동은 제한적일 수 있어요.",
                    invalidationCondition: "의사록이 중립적이고 시장금리 변동 폭이 10bp 미만이면 적극 해석을 줄여야 해요.",
                    updateSummary: PolicyUpdateSummary(
                        updatedAtText: "42분 전",
                        sourceText: "한은 기자간담회 + 국고채 시장 반응",
                        reviewText: "핵심 근거 검토 완료"
                    )
                ),
                transmissionPath: [
                    PolicyTransmissionStep(id: 1, title: "정책", subtitle: "기준금리 톤 변화", symbol: "building.columns.fill", color: .electricBlue),
                    PolicyTransmissionStep(id: 2, title: "변수", subtitle: "예적금 금리 · 은행 마진", symbol: "banknote.fill", color: .policyAmber),
                    PolicyTransmissionStep(id: 3, title: "산업", subtitle: "은행 · 성장주 밸류에이션", symbol: "building.2.fill", color: .emerald),
                    PolicyTransmissionStep(id: 4, title: "ETF", subtitle: "KODEX 은행 ETF", symbol: "chart.bar.fill", color: .policyPurple),
                    PolicyTransmissionStep(id: 5, title: "내 자산", subtitle: "정기예금 · 주담대 · 은행 ETF", symbol: "wallet.pass.fill", color: .policyCoral)
                ],
                checkpoints: [
                    WeeklyPolicyCheckpoint(
                        id: 3,
                        title: "가계대출 언급",
                        metric: "기자간담회 문구",
                        threshold: "강한 경계 유지",
                        whyItMatters: "금리보다 대출 규제 해석이 더 오래갈 수 있어요.",
                        category: .policy
                    ),
                    WeeklyPolicyCheckpoint(
                        id: 4,
                        title: "시장금리",
                        metric: "3년 국채",
                        threshold: "10bp 이상 하락",
                        whyItMatters: "예금/대출 조건 재조정 가능성이 커져요.",
                        category: .market
                    )
                ],
                alerts: ["발표 직후 10분", "가계대출 코멘트 변경 시", "은행 ETF 변동성 확대 시"]
            ),
            HomeImpactPolicy(
                id: 3,
                title: "친환경 전력망 투자 로드맵",
                dDayText: "D-3",
                summary: "ICLN은 직접 노출, 현금 비중은 간접 방어 역할을 해요. 당장 급히 매수하기보다 집행 시차를 보는 쪽이 더 중요합니다.",
                actionHint: "발표보다 실제 송전망 예산과 민간 매칭 조건이 나오는지 먼저 확인하세요.",
                judgment: HomePolicyJudgment(
                    action: .wait,
                    relevanceSummary: "내 자산 17%가 중기 정책 수혜 영향권에 있어요.",
                    keyReason: "ICLN 직접 노출은 있지만 집행 속도가 더 중요해요.",
                    thresholdSummary: "상반기 집행 확정이 나오면 해석을 한 단계 올려요.",
                    validUntilSummary: "로드맵 공개 후 일주일 안에 재점검하면 충분해요.",
                    failureSummary: "민간 매칭 비율이 낮으면 기대보다 약하게 반응할 수 있어요."
                ),
                meta: PolicyCardMeta(
                    status: .scheduled,
                    direction: .positive,
                    exposurePercent: 17,
                    delay: .threeMonths,
                    confidence: 64,
                    supportingEvidence: [
                        "ICLN 보유 비중 12%가 직접 노출 구간이에요.",
                        "전력망 투자 확대는 장기 자본집약 업종에 유리해요.",
                        "정책 지연 시에는 현금성 자산이 방어 역할을 해요."
                    ],
                    counterEvidence: "정책 방향은 좋아도 예산 승인 절차가 길어 단기 수혜는 제한적일 수 있어요.",
                    invalidationCondition: "민간 매칭 투자 비율이 낮거나, 송전망 대신 장기 연구개발만 강조되면 판단 강도를 낮춰야 해요.",
                    updateSummary: PolicyUpdateSummary(
                        updatedAtText: "1시간 전",
                        sourceText: "산업부 초안 + 전력망 투자협회",
                        reviewText: "최신 브리핑 반영 완료"
                    )
                ),
                transmissionPath: [
                    PolicyTransmissionStep(id: 1, title: "정책", subtitle: "전력망 투자 로드맵", symbol: "bolt.fill", color: .emerald),
                    PolicyTransmissionStep(id: 2, title: "변수", subtitle: "설비 CAPEX · 보조금 구조", symbol: "cable.connector", color: .policyAmber),
                    PolicyTransmissionStep(id: 3, title: "산업", subtitle: "재생에너지 · 전력 인프라", symbol: "leaf.fill", color: .policyCyan),
                    PolicyTransmissionStep(id: 4, title: "ETF", subtitle: "ICLN", symbol: "chart.bar.fill", color: .policyPurple),
                    PolicyTransmissionStep(id: 5, title: "내 자산", subtitle: "ICLN 12% + 현금 방어력", symbol: "wallet.pass.fill", color: .electricBlue)
                ],
                checkpoints: [
                    WeeklyPolicyCheckpoint(
                        id: 5,
                        title: "예산 집행 속도",
                        metric: "추경 반영 여부",
                        threshold: "상반기 집행 확정",
                        whyItMatters: "시차가 3개월에서 1개월로 당겨질 수 있어요.",
                        category: .policy
                    )
                ],
                alerts: ["발표 하루 전", "예산 확정 공시 시", "민간투자 비율 하향 시"]
            )
        ],
        policyBriefings: [
            PolicyBriefingItem(id: 1, title: "반도체 보조금 초안 요약", relatedPolicy: "미국 반도체 보조금 확대안", reason: "내 포트폴리오 노출이 28%라 총액과 집행 속도를 바로 확인해야 해요.", priority: .mustRead),
            PolicyBriefingItem(id: 2, title: "한은 기자간담회 핵심 문장", relatedPolicy: "한은 금리 경로 재조정", reason: "예금·대출·은행 ETF가 동시에 걸려 있어 해석 변화가 넓게 번져요.", priority: .mustRead),
            PolicyBriefingItem(id: 3, title: "전력망 투자 재원 구조", relatedPolicy: "친환경 전력망 투자 로드맵", reason: "ICLN은 중기 노출이라 집행 시차를 보는 게 중요해요.", priority: .mustRead),
            PolicyBriefingItem(id: 4, title: "해외 기술주 하루 수급 기사", relatedPolicy: "시장 전체", reason: "오늘 포트폴리오 변동의 핵심 원인은 정책과 환율이라 우선순위가 낮아요.", priority: .safeToIgnore),
            PolicyBriefingItem(id: 5, title: "단일 종목 루머성 기사", relatedPolicy: "개별 이슈", reason: "내 보유 자산과 직접 연결되지 않고, 무효화 가능성이 큰 단기 소음이에요.", priority: .safeToIgnore)
        ],
        changeDrivers: [
            PortfolioImpactDriver(id: 1, title: "정책 영향", sharePercent: 44, summary: "반도체 보조금 기대와 금리 톤 변화가 오늘 수익률을 끌어올렸어요.", symbol: "building.columns.fill", color: .electricBlue),
            PortfolioImpactDriver(id: 2, title: "환율 영향", sharePercent: 22, summary: "달러 강세가 SOXX 달러자산 평가액을 높였어요.", symbol: "dollarsign.arrow.circlepath", color: .policyAmber),
            PortfolioImpactDriver(id: 3, title: "시장 전체 영향", sharePercent: 21, summary: "미국 기술주 강세가 ETF 전반을 같이 밀어줬어요.", symbol: "globe.americas.fill", color: .policyPurple),
            PortfolioImpactDriver(id: 4, title: "개별 종목 영향", sharePercent: 13, summary: "은행 ETF와 ICLN은 영향이 제한적이었어요.", symbol: "chart.bar.xaxis", color: .emerald)
        ],
        checkpoints: [
            WeeklyPolicyCheckpoint(id: 10, title: "반도체 보조금 총액", metric: "발표문 총액", threshold: "4조 달러 이상이면 수혜 해석 강화", whyItMatters: "SOXX 노출 비중이 커서 체감 변동성이 커질 수 있어요.", category: .policy),
            WeeklyPolicyCheckpoint(id: 11, title: "한은 코멘트 톤", metric: "경기 둔화 vs 가계대출", threshold: "경기 둔화 강조 시 방어보다 기회", whyItMatters: "예금과 대출, 은행 ETF 해석이 동시에 바뀌어요.", category: .policy),
            WeeklyPolicyCheckpoint(id: 12, title: "전력망 예산 집행", metric: "상반기 집행 확정 여부", threshold: "미확정이면 ICLN 추격매수 보류", whyItMatters: "시차가 긴 정책은 확인 후 대응하는 편이 안전해요.", category: .policy)
        ]
    )
}
