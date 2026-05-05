import SwiftUI

struct CheckpointMockData {
    nonisolated static let policyEvents: [CheckpointPolicyEvent] = [
        CheckpointPolicyEvent(
            id: 1,
            date: "5/5",
            day: "월 (오늘)",
            title: "한은 기준금리 결정",
            institution: "한국은행 금통위",
            color: PSColor.electricBlue,
            exposure: 61,
            isToday: true,
            evidence: [
                "시장 인하 기대 78% → 이미 반영, 추가 랠리 여지 제한",
                "채권 ETF 12% 보유 중 → 인하 후 비중 조정 타이밍"
            ],
            counterEvidence: "총재가 추가 인하 신중 발언 시 채권 시장 되돌림 가능",
            verified: true,
            updatedAt: "오전 11:24",
            checkpoints: [
                CheckpointItem(
                    id: "cp1",
                    text: "3년 국채 10bp 이상 움직임",
                    metric: "국채 3년 금리",
                    baseline: "현재 3.25%",
                    importance: .high,
                    alertOn: true,
                    completed: false,
                    linkedPolicyId: 1,
                    linkedPolicyTitle: "한은 기준금리 결정",
                    relatedAssets: ["TIGER 국채3년", "KODEX 국고채"],
                    conditionMet: "채권 ETF 비중 확대 검토",
                    conditionNotMet: "현 비중 유지"
                ),
                CheckpointItem(
                    id: "cp2",
                    text: "총재 기자회견 톤 확인",
                    metric: "발언 강도",
                    baseline: "중립 예상",
                    importance: .high,
                    alertOn: false,
                    completed: false,
                    linkedPolicyId: 1,
                    linkedPolicyTitle: "한은 기준금리 결정",
                    relatedAssets: ["TIGER 국채3년", "KODEX 은행"],
                    conditionMet: "채권 비중 유지 또는 확대",
                    conditionNotMet: "채권 비중 축소 검토"
                )
            ]
        ),
        CheckpointPolicyEvent(
            id: 2,
            date: "5/6",
            day: "화",
            title: "미국 반도체 보조금 2차 발표",
            institution: "미 상무부 CHIPS 오피스",
            color: PSColor.purple,
            exposure: 28,
            isToday: false,
            evidence: [
                "예상치 상회 시 반도체 섹터 랠리 가능",
                "SOXX 보유 중 → 직접 수혜 가능"
            ],
            counterEvidence: "총액 미달 또는 집행 일정 지연 시 실망 매도 가능",
            verified: false,
            updatedAt: "오전 9:40",
            checkpoints: [
                CheckpointItem(
                    id: "cp3",
                    text: "보조금 총액 4조 달러 이상",
                    metric: "CHIPS 보조금 총액",
                    baseline: "4조 달러 임계선",
                    importance: .high,
                    alertOn: true,
                    completed: false,
                    linkedPolicyId: 2,
                    linkedPolicyTitle: "미국 반도체 보조금 2차 발표",
                    relatedAssets: ["SOXX", "삼성전자"],
                    conditionMet: "반도체 비중 확대 검토",
                    conditionNotMet: "현 비중 유지, 추격매수 자제"
                ),
                CheckpointItem(
                    id: "cp4",
                    text: "발표 후 24시간 내 ETF 반응",
                    metric: "SOXX 일중 변동률",
                    baseline: "+2% 이상 반응",
                    importance: .medium,
                    alertOn: false,
                    completed: false,
                    linkedPolicyId: 2,
                    linkedPolicyTitle: "미국 반도체 보조금 2차 발표",
                    relatedAssets: ["SOXX"],
                    conditionMet: "단기 차익실현 고려",
                    conditionNotMet: "추가 매수 타이밍 탐색"
                )
            ]
        ),
        CheckpointPolicyEvent(
            id: 3,
            date: "5/7",
            day: "수",
            title: "미 FOMC 5월 회의 결과",
            institution: "미국 연방준비제도",
            color: PSColor.yellow,
            exposure: 45,
            isToday: false,
            evidence: [
                "달러 예금 15% → 환율 변동에 직접 노출",
                "파월 인하 시사 시 위험자산 선호 증가"
            ],
            counterEvidence: "매파 발언 시 달러 강세와 채권 약세 동시 충격",
            verified: false,
            updatedAt: "오전 8:00",
            checkpoints: [
                CheckpointItem(
                    id: "cp5",
                    text: "파월 6월 인하 시사 여부",
                    metric: "FOMC 성명 + 기자회견",
                    baseline: "6월 인하 시사 여부",
                    importance: .high,
                    alertOn: true,
                    completed: false,
                    linkedPolicyId: 3,
                    linkedPolicyTitle: "미 FOMC 5월 회의 결과",
                    relatedAssets: ["달러 예금", "SOXX"],
                    conditionMet: "위험자산 비중 소폭 확대",
                    conditionNotMet: "달러 비중 유지, 방어 모드"
                )
            ]
        ),
        CheckpointPolicyEvent(
            id: 4,
            date: "5/10",
            day: "토",
            title: "친환경 전력망 투자 로드맵",
            institution: "산업통상자원부·환경부",
            color: PSColor.emerald,
            exposure: 17,
            isToday: false,
            evidence: [
                "예산 집행 상반기 확정 시 관련 ETF 선반영 가능",
                "신재생에너지 장기 수혜 섹터"
            ],
            counterEvidence: "예산 집행 지연 또는 규모 축소 가능성",
            verified: false,
            updatedAt: "오전 7:00",
            checkpoints: [
                CheckpointItem(
                    id: "cp6",
                    text: "전력망 예산 집행 상반기 확정",
                    metric: "예산 집행 일정",
                    baseline: "상반기 내 집행",
                    importance: .medium,
                    alertOn: false,
                    completed: false,
                    linkedPolicyId: 4,
                    linkedPolicyTitle: "친환경 전력망 투자 로드맵",
                    relatedAssets: ["ICLN", "KODEX 신재생에너지"],
                    conditionMet: "친환경 ETF 편입 고려",
                    conditionNotMet: "관망 유지"
                )
            ]
        )
    ]

    nonisolated static let decisionItems: [CheckpointDecisionItem] = [
        CheckpointDecisionItem(
            id: "d1",
            title: "금통위 코멘트 톤 확인",
            reason: "금리 인하는 가격에 반영되어 있고 기자회견 문구가 다음 방향을 결정합니다.",
            relatedAssets: ["TIGER 국채3년", "KODEX 은행"],
            validUntil: "장 마감 전",
            invalidationCondition: "예상 외 동결 또는 매파 발언",
            type: .confirm,
            color: PSColor.electricBlue,
            linkedPolicyId: 1
        ),
        CheckpointDecisionItem(
            id: "d2",
            title: "반도체 보조금 총액 확인 후 판단",
            reason: "발표 전 기대감만으로 추격하기보다 총액과 집행 속도를 확인합니다.",
            relatedAssets: ["SOXX", "삼성전자"],
            validUntil: "내일 발표 직후",
            invalidationCondition: "보조금 총액 4조 달러 미만",
            type: .wait,
            color: PSColor.purple,
            linkedPolicyId: 2
        ),
        CheckpointDecisionItem(
            id: "d3",
            title: "FOMC 전 달러 비중 유지",
            reason: "파월 발언 전까지 환율 변동성이 커질 수 있어 방어 비중을 유지합니다.",
            relatedAssets: ["달러 예금", "SOXX"],
            validUntil: "5/7 FOMC까지",
            invalidationCondition: "6월 인하 강한 시사",
            type: .defend,
            color: PSColor.red,
            linkedPolicyId: 3
        ),
        CheckpointDecisionItem(
            id: "d4",
            title: "친환경 ETF 편입 시뮬레이션",
            reason: "정책 수혜 가능성은 있으나 예산 확정 전 실제 편입보다 모의 반영이 적절합니다.",
            relatedAssets: ["ICLN", "KODEX 신재생에너지"],
            validUntil: "5/10 발표 후",
            invalidationCondition: "예산 집행 일정 지연",
            type: .simulate,
            color: PSColor.emerald,
            linkedPolicyId: 4
        )
    ]
}
