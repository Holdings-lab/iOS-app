import SwiftUI

struct TodayMockData {

    nonisolated static let policyEvents: [TodayPolicyEvent] = [
        TodayPolicyEvent(
            id: 1,
            title: "한은 기준금리 결정",
            institution: "한국은행 금통위",
            dDay: "오늘",
            date: "5/5",
            status: .announced,
            color: PSColor.electricBlue,
            myExposure: 61,
            relatedAssets: ["채권 ETF", "은행주", "TIGER 국채3년"],
            summary: "금통위가 기준금리를 3.00%에서 2.75%로 25bp 인하 결정. 총재는 추가 인하에 신중한 입장을 표명.",
            direction: .mixed,
            evidence: [
                "시장 인하 기대 78% → 이미 반영, 추가 랠리 여지 제한",
                "채권 ETF 12% 보유 중 → 인하 후 비중 조정 타이밍"
            ],
            counterEvidence: "총재가 '추가 인하 신중' 발언 시 채권 시장 되돌림 가능",
            invalidationConditions: ["예상 외 동결", "총재 추가 인하 부정 발언"],
            sources: ["한국은행", "블룸버그"],
            verified: true,
            updatedAt: "오전 11:24",
            impactFlow: ImpactFlow(steps: ["금통위 결정", "시장 금리 반응", "채권 ETF", "내 포트폴리오"]),
            timelag: "즉시~1거래일",
            confidence: 75
        ),
        TodayPolicyEvent(
            id: 2,
            title: "미국 반도체 보조금 2차 발표",
            institution: "미 상무부 CHIPS 오피스",
            dDay: "D-1",
            date: "5/6",
            status: .scheduled,
            color: PSColor.purple,
            myExposure: 28,
            relatedAssets: ["SOXX", "삼성전자", "반도체 ETF"],
            summary: "미 상무부가 CHIPS법 2차 보조금 패키지를 발표 예정. 총액 5.2조 달러 수준으로 전망.",
            direction: .positive,
            evidence: [
                "5.2조 달러 규모 → 예상치 상회 시 반도체 섹터 랠리",
                "SOXX 보유 중 → 직접 수혜 가능"
            ],
            counterEvidence: "총액 미달 또는 집행 일정 지연 시 실망 매도 가능",
            invalidationConditions: ["보조금 총액 4조 달러 미만", "발표 연기"],
            sources: ["블룸버그", "로이터"],
            verified: false,
            updatedAt: "오전 9:40",
            impactFlow: ImpactFlow(steps: ["보조금 발표", "반도체 섹터", "SOXX·삼성전자", "내 포트폴리오"]),
            timelag: "발표 후 즉시",
            confidence: 68
        ),
        TodayPolicyEvent(
            id: 3,
            title: "미 FOMC 5월 회의 결과",
            institution: "미국 연방준비제도",
            dDay: "D-2",
            date: "5/7",
            status: .scheduled,
            color: PSColor.yellow,
            myExposure: 45,
            relatedAssets: ["달러 예금", "SOXX", "KODEX 200"],
            summary: "5월 FOMC에서 기준금리 동결이 유력하며 파월 의장의 6월 인하 시사 발언이 핵심 변수.",
            direction: .mixed,
            evidence: [
                "달러 예금 15% → 환율 변동에 직접 노출",
                "파월 인하 시사 시 위험자산 선호 증가"
            ],
            counterEvidence: "매파 발언 시 달러 강세 + 채권 약세 동시 충격",
            invalidationConditions: ["긴급 금리 인상", "파월 연내 인하 불가 발언"],
            sources: ["연방준비제도", "블룸버그"],
            verified: false,
            updatedAt: "오전 8:00",
            impactFlow: ImpactFlow(steps: ["FOMC 결정", "달러 환율", "국내 시장", "내 포트폴리오"]),
            timelag: "발표 즉시",
            confidence: 82
        ),
        TodayPolicyEvent(
            id: 4,
            title: "친환경 전력망 투자 로드맵",
            institution: "산업통상자원부·환경부",
            dDay: "D-5",
            date: "5/10",
            status: .scheduled,
            color: PSColor.emerald,
            myExposure: 17,
            relatedAssets: ["ICLN", "KODEX 신재생에너지"],
            summary: "정부가 2030년까지 친환경 전력망에 40조원 투자 로드맵을 발표 예정.",
            direction: .positive,
            evidence: [
                "예산 집행 상반기 확정 시 관련 ETF 선반영 가능",
                "신재생에너지 장기 수혜 섹터"
            ],
            counterEvidence: "예산 집행 지연 또는 규모 축소 가능성",
            invalidationConditions: ["예산 삭감", "발표 취소"],
            sources: ["산업통상자원부", "환경부"],
            verified: false,
            updatedAt: "오전 7:00",
            impactFlow: ImpactFlow(steps: ["로드맵 발표", "친환경 섹터", "ICLN·신재생ETF", "내 포트폴리오"]),
            timelag: "발표 후 1~3일",
            confidence: 55
        )
    ]

    nonisolated static let checkpoints: [TodayCheckpoint] = [
        TodayCheckpoint(
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
        TodayCheckpoint(
            id: "cp2",
            text: "총재 기자회견 톤 확인",
            metric: "발언 강도 (매파/비둘기파)",
            baseline: "중립 예상",
            importance: .high,
            alertOn: true,
            completed: false,
            linkedPolicyId: 1,
            linkedPolicyTitle: "한은 기준금리 결정",
            relatedAssets: ["TIGER 국채3년", "KODEX 은행"],
            conditionMet: "채권 비중 유지 또는 확대",
            conditionNotMet: "채권 비중 축소 검토"
        ),
        TodayCheckpoint(
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
        TodayCheckpoint(
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
        ),
        TodayCheckpoint(
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
        ),
        TodayCheckpoint(
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

    nonisolated static let holdings: [TodayHolding] = [
        TodayHolding(
            id: "h1",
            name: "TIGER 국채3년",
            ticker: "114260",
            category: "채권 ETF",
            weight: 18,
            value: 2_439_000,
            change: 0.34,
            exposedThemes: [
                TodayThemeExposure(theme: "금리", intensity: .high, color: PSColor.electricBlue),
                TodayThemeExposure(theme: "채권", intensity: .high, color: PSColor.blueSubtle)
            ],
            color: PSColor.electricBlue
        ),
        TodayHolding(
            id: "h2",
            name: "SOXX",
            ticker: "SOXX",
            category: "반도체 ETF",
            weight: 18,
            value: 2_439_000,
            change: 1.24,
            exposedThemes: [
                TodayThemeExposure(theme: "반도체", intensity: .high, color: PSColor.purple),
                TodayThemeExposure(theme: "달러", intensity: .medium, color: PSColor.yellow)
            ],
            color: PSColor.purple
        ),
        TodayHolding(
            id: "h3",
            name: "KODEX 200",
            ticker: "069500",
            category: "국내 주식 ETF",
            weight: 22,
            value: 2_981_000,
            change: -0.18,
            exposedThemes: [
                TodayThemeExposure(theme: "금리", intensity: .medium, color: PSColor.electricBlue),
                TodayThemeExposure(theme: "환율", intensity: .medium, color: PSColor.yellow)
            ],
            color: PSColor.emerald
        ),
        TodayHolding(
            id: "h4",
            name: "삼성전자",
            ticker: "005930",
            category: "개별 주식",
            weight: 12,
            value: 1_626_000,
            change: 0.82,
            exposedThemes: [
                TodayThemeExposure(theme: "반도체", intensity: .high, color: PSColor.purple),
                TodayThemeExposure(theme: "환율", intensity: .low, color: PSColor.yellow)
            ],
            color: PSColor.cyan
        ),
        TodayHolding(
            id: "h5",
            name: "달러 예금",
            ticker: "USD",
            category: "현금성 자산",
            weight: 15,
            value: 2_032_500,
            change: 0.12,
            exposedThemes: [
                TodayThemeExposure(theme: "달러", intensity: .high, color: PSColor.yellow),
                TodayThemeExposure(theme: "금리", intensity: .medium, color: PSColor.electricBlue)
            ],
            color: PSColor.yellow
        ),
        TodayHolding(
            id: "h6",
            name: "국내 예금",
            ticker: "KRW",
            category: "현금성 자산",
            weight: 15,
            value: 2_032_500,
            change: 0.0,
            exposedThemes: [
                TodayThemeExposure(theme: "금리", intensity: .high, color: PSColor.electricBlue)
            ],
            color: PSColor.gray
        )
    ]

    nonisolated static let judgment = TodayJudgment(
        title: "반도체 ETF 비중을 오늘 점검해야 합니다",
        type: .defend,
        myExposure: 72,
        validUntil: "장 마감 전 (오후 3:30)",
        invalidationCondition: "SOXX가 -2% 이상 밀리거나 보조금 발표가 지연되면 1차 매도 확인",
        forEvidence: [
            "반도체 ETF와 성장주 합산 비중이 단일 섹터 한도를 넘었습니다",
            "오늘 보조금 발표 전 변동성 위험이 높아졌습니다",
            "현금 비중을 10% 이상으로 회복하는 방어 조정이 필요합니다"
        ],
        againstEvidence: [
            "발표가 예상보다 우호적이면 일부 상승 기회를 놓칠 수 있습니다"
        ],
        deliveryPath: "보조금 발표 지연 → 반도체 섹터 변동성 확대 → SOXX·성장주 ETF → 내 포트폴리오"
    )

    nonisolated static let portfolio = TodayPortfolioSummary(
        totalAsset: 134_820_000,
        todayChange: 1.2,
        todayChangeAmt: 1_580_000,
        cashDefense: 30,
        dollarDefense: 15,
        overtradeRisk: "낮음",
        topExposures: [
            TodayExposureItem(theme: "금리", pct: 61, color: PSColor.electricBlue),
            TodayExposureItem(theme: "반도체", pct: 28, color: PSColor.purple),
            TodayExposureItem(theme: "달러", pct: 24, color: PSColor.yellow)
        ],
        riskLevel: "주의",
        weeklySparklinePoints: [128.4, 130.1, 129.6, 131.8, 133.2, 132.5, 134.8]
    )

    nonisolated static let newsItems: [TodayNewsItem] = [
        TodayNewsItem(
            id: 1,
            title: "한은, 기준금리 25bp 인하 결정…총재 \"추가 인하 신중\"",
            source: "한국경제",
            time: "오전 10:15",
            summary: "한국은행이 기준금리를 3.00%에서 2.75%로 인하. 이창용 총재는 추가 인하에 신중한 입장 표명.",
            relatedAssets: ["TIGER 국채3년", "KODEX 은행", "달러 예금"],
            relevance: .high,
            direction: .mixed,
            myAssetImpact: "채권 ETF 단기 긍정, 은행주 중립",
            checkCondition: "3년 국채 10bp 이상 움직임 확인",
            whyIgnore: nil,
            saved: false,
            fullText: "한국은행 금융통화위원회가 오늘 기준금리를 연 3.00%에서 2.75%로 25bp 인하했다. 이창용 한은 총재는 기자회견에서 추가 인하에 대해 신중한 입장을 밝혀 시장의 연내 추가 인하 기대에 제동을 걸었다."
        ),
        TodayNewsItem(
            id: 2,
            title: "미 상무부, 반도체 보조금 2차 패키지 총액 5.2조 달러 확정 전망",
            source: "블룸버그",
            time: "오전 9:40",
            summary: "내일 발표 예정인 미 CHIPS법 2차 보조금이 5.2조 달러 규모로 확정될 것으로 보도.",
            relatedAssets: ["SOXX", "삼성전자"],
            relevance: .high,
            direction: .positive,
            myAssetImpact: "SOXX·삼성전자 긍정적 영향 예상",
            checkCondition: "보조금 총액 4조 달러 이상 확인",
            whyIgnore: nil,
            saved: true,
            fullText: "블룸버그는 미 상무부가 내일 발표할 CHIPS법 2차 보조금 패키지 총액이 5.2조 달러 수준으로 확정됐다고 보도했다."
        ),
        TodayNewsItem(
            id: 3,
            title: "원달러 환율 1,378원…인하 결정 후 소폭 상승",
            source: "연합뉴스",
            time: "오전 11:00",
            summary: "한은 금리 인하 결정 후 원달러 환율이 소폭 상승. 달러 수요 증가 요인 작용.",
            relatedAssets: ["달러 예금", "SOXX", "KODEX 200"],
            relevance: .medium,
            direction: .mixed,
            myAssetImpact: "달러 예금 평가액 소폭 증가",
            checkCondition: "환율 1,380원 돌파 여부",
            whyIgnore: nil,
            saved: false,
            fullText: "서울 외환시장에서 원달러 환율이 한은 금리 인하 결정 이후 소폭 상승하며 1,378원에 거래되고 있다."
        ),
        TodayNewsItem(
            id: 4,
            title: "삼성전자 1분기 영업이익 9.1조원…반도체 회복세 확인",
            source: "연합뉴스",
            time: "오전 8:30",
            summary: "삼성전자가 1분기 영업이익 9.1조원을 기록하며 반도체 부문 회복세를 확인.",
            relatedAssets: ["삼성전자", "SOXX"],
            relevance: .medium,
            direction: .positive,
            myAssetImpact: "삼성전자 보유분 긍정적",
            checkCondition: "2분기 가이던스 확인",
            whyIgnore: nil,
            saved: false,
            fullText: "삼성전자가 1분기 연결 기준 영업이익 9.1조원을 기록했다고 공시했다. HBM 등 고부가 메모리 판매 증가가 실적을 견인했다."
        ),
        TodayNewsItem(
            id: 5,
            title: "국내 2차전지 섹터 급락…LG에너지솔루션 -4.2%",
            source: "이데일리",
            time: "오전 10:45",
            summary: "2차전지 관련주가 급락세를 보이며 LG에너지솔루션이 4.2% 하락.",
            relatedAssets: [],
            relevance: .low,
            direction: .negative,
            myAssetImpact: "보유 종목 직접 연관 없음",
            checkCondition: "해당 없음",
            whyIgnore: "보유 종목과 직접 연관 없어 무시 가능",
            saved: false,
            fullText: "2차전지 섹터가 글로벌 전기차 수요 둔화 우려로 급락세를 보였다."
        ),
        TodayNewsItem(
            id: 6,
            title: "글로벌 채권 시장, 연준 인하 기대 소폭 조정",
            source: "로이터",
            time: "오전 7:00",
            summary: "글로벌 채권 시장에서 연준 금리 인하 기대가 소폭 후퇴하며 미 국채 금리 상승.",
            relatedAssets: ["TIGER 국채3년", "달러 예금"],
            relevance: .medium,
            direction: .mixed,
            myAssetImpact: "채권 ETF 단기 압박 가능성",
            checkCondition: "파월 FOMC 발언 톤 확인",
            whyIgnore: nil,
            saved: false,
            fullText: "글로벌 채권 시장에서 연준의 6월 금리 인하 기대가 소폭 조정되며 미 10년 국채 금리가 상승했다."
        ),
        TodayNewsItem(
            id: 7,
            title: "코스피 테마주 대장주 교체…\"단기 모멘텀 체크 필요\"",
            source: "머니투데이",
            time: "오전 9:15",
            summary: "코스피 내 테마주 주도 종목이 교체되며 단기 모멘텀 변화가 감지.",
            relatedAssets: [],
            relevance: .low,
            direction: .mixed,
            myAssetImpact: "보유 종목 연관 낮음",
            checkCondition: "해당 없음",
            whyIgnore: "단기 테마주 트레이딩 성격 — 정책 해석과 무관",
            saved: false,
            fullText: "코스피 시장에서 테마주 대장주가 교체되는 양상이 나타나고 있다."
        )
    ]

    nonisolated static let decisionLanes: [TodayDecisionLane] = [
        TodayDecisionLane(
            id: "dl1",
            type: .confirm,
            title: "금통위 코멘트 톤 확인",
            relatedAssets: ["TIGER 국채3년", "KODEX 은행"],
            validUntil: "장 마감 전"
        ),
        TodayDecisionLane(
            id: "dl2",
            type: .wait,
            title: "반도체 보조금 총액 확인 후 판단",
            relatedAssets: ["SOXX", "삼성전자"],
            validUntil: "내일 발표 직후"
        ),
        TodayDecisionLane(
            id: "dl3",
            type: .defend,
            title: "FOMC 전 달러 비중 유지",
            relatedAssets: ["달러 예금"],
            validUntil: "5/7 FOMC까지"
        ),
        TodayDecisionLane(
            id: "dl4",
            type: .simulate,
            title: "친환경 ETF 편입 시뮬레이션",
            relatedAssets: ["ICLN", "KODEX 신재생에너지"],
            validUntil: "5/10 발표 후"
        )
    ]

    nonisolated static let noActionReasons: [String] = [
        "금리 인하는 이미 78% 반영 — 추가 랠리 여지 제한",
        "반도체 보조금 발표 전 — 내일 확인 후 판단",
        "달러 비중 15%로 방어력 적정 — 변경 불필요"
    ]

    nonisolated static let noActionWatchCondition =
        "FOMC 매파 발언 또는 반도체 보조금 미달 시"
}
