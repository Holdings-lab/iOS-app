import SwiftUI

enum PolSignalFlowMockData {
    static let vixText = "18.7"
    static let vixChangeText = "+2.1"
    static let vixCaption = "변동성 경계. 반도체 발표 전 포지션을 먼저 확인하세요."

    static let events: [PolSignalEvent] = [
        PolSignalEvent(
            id: 101,
            feedTab: .myImpact,
            category: "반도체",
            institution: "미 상무부",
            dDay: "D-1",
            title: "CHIPS 보조금 2차 배분안 발표",
            verdictKind: .adjust,
            verdict: "반도체 노출을 3%p 낮춰 볼 시점",
            reason: "SOXX와 SMH 합산 비중이 높아 발표 직후 변동성에 직접 노출돼요.",
            expectedImpact: "보조금 규모가 예상보다 작으면 반도체 ETF 단기 흔들림 가능",
            aiSummary: "보조금 총액보다 집행 조건이 핵심입니다. 조건이 까다로우면 반도체 ETF의 기대 수혜가 약해질 수 있어요.",
            ctaTitle: "조정 제안 보기",
            exposures: [
                PolSignalExposure(ticker: "SOXX", weightText: "12%", color: PSColor.tagSemi),
                PolSignalExposure(ticker: "SMH", weightText: "8%", color: PSColor.primary),
                PolSignalExposure(ticker: "005930", weightText: "7%", color: PSColor.success)
            ],
            scenarios: [
                PolSignalScenario(
                    code: "A",
                    probability: 54,
                    title: "조건부 호재",
                    outcome: "반도체 ETF 보합권",
                    note: "총액은 크지만 집행 조건이 붙어 단기 상승폭이 제한될 수 있어요."
                ),
                PolSignalScenario(
                    code: "B",
                    probability: 32,
                    title: "예상 상회",
                    outcome: "SOXX 1~3거래일 강세",
                    note: "수혜 기업 범위가 넓으면 반도체 ETF 전체에 매수세가 붙을 수 있어요."
                ),
                PolSignalScenario(
                    code: "C",
                    probability: 14,
                    title: "집행 지연",
                    outcome: "반도체 단기 조정",
                    note: "일정이 밀리면 이미 오른 종목부터 차익 실현이 나올 수 있어요."
                )
            ],
            weakeningCondition: "발표 총액이 예상치를 넘고 집행 일정이 30일 이내로 확정되면 축소 판단은 약해져요.",
            sourceSummary: "상무부는 첨단 패키징과 생산 설비 투자 조건을 함께 공개할 예정입니다. 시장은 총액보다 지급 속도와 대상 기업 범위를 확인하고 있습니다.",
            checkSchedule: "5월 16일 22:30 발표 확인",
            accentColor: PSColor.tagSemi
        ),
        PolSignalEvent(
            id: 102,
            feedTab: .myImpact,
            category: "금리",
            institution: "미 연준",
            dDay: "D-2",
            title: "FOMC 의사록 공개와 6월 인하 힌트",
            verdictKind: .review,
            verdict: "달러와 성장주를 함께 점검",
            reason: "달러 예금과 성장 ETF가 동시에 반응해 포트폴리오 방향이 엇갈릴 수 있어요.",
            expectedImpact: "인하 힌트가 약하면 달러 강세, 성장주 변동성 확대 가능",
            aiSummary: "파월 발언보다 위원들의 물가 표현이 중요합니다. 물가 우려가 반복되면 위험자산 기대가 낮아질 수 있어요.",
            ctaTitle: "시나리오 보기",
            exposures: [
                PolSignalExposure(ticker: "USD", weightText: "15%", color: PSColor.warn),
                PolSignalExposure(ticker: "QQQ", weightText: "9%", color: PSColor.primary),
                PolSignalExposure(ticker: "SOXX", weightText: "12%", color: PSColor.tagSemi)
            ],
            scenarios: [
                PolSignalScenario(code: "A", probability: 50, title: "동결 장기화", outcome: "달러 방어 유지", note: "달러 자산 평가는 버티지만 성장주는 눌릴 수 있어요."),
                PolSignalScenario(code: "B", probability: 30, title: "완화 힌트", outcome: "성장 ETF 반등", note: "장기금리가 내려가면 QQQ와 SOXX에 우호적이에요."),
                PolSignalScenario(code: "C", probability: 20, title: "물가 경계 강화", outcome: "위험자산 축소", note: "현금 비중을 유지하는 편이 변동성 방어에 유리해요.")
            ],
            weakeningCondition: "의사록에서 고용 둔화와 인하 논의가 동시에 확인되면 달러 방어 판단은 약해져요.",
            sourceSummary: "시장 참여자는 의사록의 물가 표현, 고용 둔화 언급, 6월 정책 경로 힌트를 함께 보고 있습니다.",
            checkSchedule: "5월 17일 03:00 의사록 공개",
            accentColor: PSColor.primary
        ),
        PolSignalEvent(
            id: 103,
            feedTab: .breaking,
            category: "환율",
            institution: "서울 외환시장",
            dDay: "오늘",
            title: "원달러 환율 1,380원 재돌파",
            verdictKind: .watch,
            verdict: "달러 노출은 유지, 추가 매수는 보류",
            reason: "이미 달러 자산 15%를 들고 있어 환율 급등을 따라 살 필요는 낮아요.",
            expectedImpact: "달러 예금 평가는 개선, 국내 성장주는 압박 가능",
            aiSummary: "환율 상승은 방어에는 좋지만 추격 매수 신호는 아닙니다. 기존 달러 비중이 완충 역할을 하고 있어요.",
            ctaTitle: "영향 분석 보기",
            exposures: [
                PolSignalExposure(ticker: "USD", weightText: "15%", color: PSColor.warn),
                PolSignalExposure(ticker: "069500", weightText: "10%", color: PSColor.success)
            ],
            scenarios: [
                PolSignalScenario(code: "A", probability: 55, title: "1,380원 안착", outcome: "달러 방어 유효", note: "달러 예금 평가액이 국내 자산 흔들림을 일부 상쇄해요."),
                PolSignalScenario(code: "B", probability: 25, title: "빠른 되돌림", outcome: "달러 추가 매수 불리", note: "고점 매수 리스크가 커져 기존 비중 유지가 낫습니다."),
                PolSignalScenario(code: "C", probability: 20, title: "1,400원 접근", outcome: "국내 위험자산 압박", note: "국내 주식 ETF 변동성을 다시 점검해야 해요.")
            ],
            weakeningCondition: "외환 당국 구두 개입과 미국 금리 하락이 동시에 나오면 환율 상승 판단은 약해져요.",
            sourceSummary: "원달러 환율은 미국 금리 경계와 국내 수급 영향으로 상승했습니다. 시장은 1,380원 안착 여부를 보고 있습니다.",
            checkSchedule: "오늘 장 마감 환율 확인",
            accentColor: PSColor.warn
        ),
        PolSignalEvent(
            id: 104,
            feedTab: .learning,
            category: "학습",
            institution: "PolSignal",
            dDay: "읽기",
            title: "정책 신호가 ETF 비중으로 번역되는 방식",
            verdictKind: .watch,
            verdict: "뉴스 제목보다 내 노출 비중을 먼저 봐야 해요",
            reason: "같은 뉴스라도 보유 비중이 낮으면 행동으로 이어질 필요가 작아요.",
            expectedImpact: "정책 → 섹터 → 티커 → 내 비중 순서로 영향도를 계산",
            aiSummary: "정책은 방향을 만들고, 보유 비중은 행동의 크기를 정합니다. PolSignal은 이 두 정보를 분리해서 보여줘요.",
            ctaTitle: "영향 분석 보기",
            exposures: [
                PolSignalExposure(ticker: "SOXX", weightText: "예시", color: PSColor.tagSemi)
            ],
            scenarios: [
                PolSignalScenario(code: "A", probability: 60, title: "직접 노출", outcome: "행동 검토", note: "관련 티커 비중이 크면 상세 판단으로 이동합니다."),
                PolSignalScenario(code: "B", probability: 30, title: "간접 노출", outcome: "관찰 유지", note: "섹터 연관만 있으면 알림 강도를 낮춥니다."),
                PolSignalScenario(code: "C", probability: 10, title: "무관", outcome: "읽기만", note: "보유 자산과 연결되지 않으면 행동 제안은 만들지 않아요.")
            ],
            weakeningCondition: "내 보유 자산과 티커 연결이 없으면 행동 제안은 생성하지 않아요.",
            sourceSummary: "정책 신호는 키워드가 아니라 보유 자산과의 연결 강도, 비중, 변동성으로 다시 계산됩니다.",
            checkSchedule: "상시 학습 콘텐츠",
            accentColor: PSColor.success
        )
    ]

    static let adjustmentProposal = PolSignalAdjustmentProposal(
        badgeText: "검토용 제안",
        indexText: "1/2",
        title: "반도체 단일 노출을 낮추고 현금 방어를 회복",
        currentLabel: "반도체",
        currentWeight: 42,
        proposedLabel: "반도체",
        proposedWeight: 39,
        allocationChanges: ["SOXX -3%p", "현금 +3%p"],
        reasons: [
            PolSignalAdjustmentReason(
                iconName: "exclamationmark.triangle.fill",
                title: "단일 테마 42%가 권장 35%를 초과",
                detail: "반도체 정책 발표 전 변동성이 커질 때 손실이 한쪽으로 집중될 수 있어요.",
                color: PSColor.danger
            ),
            PolSignalAdjustmentReason(
                iconName: "calendar.badge.clock",
                title: "CHIPS 발표가 D-1로 가까움",
                detail: "결과 확인 전 일부 현금을 확보하면 발표 후 대응 선택지가 늘어납니다.",
                color: PSColor.primary
            ),
            PolSignalAdjustmentReason(
                iconName: "shield.lefthalf.filled",
                title: "현금 방어 비중 10% 회복",
                detail: "초보 투자자는 방향 예측보다 손실 폭 관리가 먼저입니다.",
                color: PSColor.success
            )
        ],
        effects: [
            PolSignalAdjustmentEffect(title: "변동성", value: "-1.2%", color: PSColor.success),
            PolSignalAdjustmentEffect(title: "확증 점수", value: "+3", color: PSColor.primary),
            PolSignalAdjustmentEffect(title: "다시 볼", value: "5/16", color: PSColor.warn)
        ],
        helperText: "대응을 실행하지 않아도 기록만 남길 수 있어요"
    )

    static let assetSummary = PolSignalAssetSummary(
        totalAssetText: "₩134,829,500",
        returnBadgeText: "+1.2%",
        returnColor: PSColor.success,
        composition: [
            PolSignalThemeExposure(title: "반도체", percent: 42, color: PSColor.primary),
            PolSignalThemeExposure(title: "금리·채권", percent: 24, color: PSColor.textFaint),
            PolSignalThemeExposure(title: "친환경", percent: 18, color: PSColor.success),
            PolSignalThemeExposure(title: "현금", percent: 16, color: PSColor.border)
        ],
        riskAlerts: [
            PolSignalRiskAlert(severity: .red, title: "반도체 단일 노출 42%", detail: "권장 35%를 초과해 발표 이벤트 전 변동성 위험이 큽니다."),
            PolSignalRiskAlert(severity: .yellow, title: "환율 변동성 +12%", detail: "달러 자산은 방어가 되지만 추가 매수는 신중해야 합니다.")
        ],
        themeExposures: [
            PolSignalThemeExposure(title: "반도체", percent: 42, color: PSColor.primary),
            PolSignalThemeExposure(title: "금리·채권", percent: 24, color: PSColor.textFaint),
            PolSignalThemeExposure(title: "친환경", percent: 18, color: PSColor.success),
            PolSignalThemeExposure(title: "환율", percent: 15, color: PSColor.warn),
            PolSignalThemeExposure(title: "현금", percent: 16, color: PSColor.border)
        ]
    )

    static var todayTopEvents: [PolSignalEvent] {
        Array(events.prefix(3))
    }

    static func event(id: Int) -> PolSignalEvent {
        events.first { $0.id == id } ?? events[0]
    }
}
