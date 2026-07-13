# 뉴스룸 Mock 데이터 레퍼런스

> 작성일 2026-07-12 · `MockNewsroomDigestRepository` 구현용
> 스키마: `뉴스룸-uiux-가이드.md` §4.1 / 화면 매핑: `뉴스룸-화면-인터랙션-상세.md`
> 시나리오 3종은 화면 상태를 전부 커버한다: ①조용한 기본 상태 ②혼재 ③alert. Mock은 이 JSON을 Swift 모델로 옮긴 것이어야 하며, 문구는 카피 톤 체크(상세 가이드 §6)를 통과한 상태다 — 임의로 더 자극적으로 바꾸지 말 것.

---

## 0. 전제: Mock 포트폴리오

자산 영향 표시("내 자산의 12% · 총자산 기준 -0.25%")는 페이로드가 아니라 보유 정보에서 계산되므로, Mock 자산 프로필도 함께 고정한다:

| 종목 | 비중 |
|---|---|
| QQQ | 35% |
| NVDA | 12% |
| AAPL | 18% |
| MSFT | 9% |
| 현금 등 | 26% |

---

## 1. 시나리오 A — calm · 전 종목 조용 (가장 자주 보이는 기본 화면)

검증 포인트: 조용 로우 3변형(quietDays 1/3/12), 시장 스토리 섹션 숨김, 종료 마커 heartbeat.

```json
{
  "generatedAt": "2026-07-10T06:00:00+09:00",
  "severity": "calm",
  "caution": null,
  "briefing": {
    "message": "시장은 조용한 하루였어요. 보유 종목에 새로운 소식이 없었어요.",
    "tappable": false
  },
  "marketStory": null,
  "tickerDigests": [
    { "ticker": "QQQ",  "hasNews": false, "quietDays": 12, "summary": null, "newFacts": [], "articles": [] },
    { "ticker": "AAPL", "hasNews": false, "quietDays": 3,  "summary": null, "newFacts": [], "articles": [] },
    { "ticker": "NVDA", "hasNews": false, "quietDays": 1,  "summary": null, "newFacts": [], "articles": [] },
    { "ticker": "MSFT", "hasNews": false, "quietDays": 5,  "summary": null, "newFacts": [], "articles": [] }
  ],
  "learningCards": [
    { "id": "drawdown-history", "title": "하락은 얼마나 자주 올까 — 드로다운의 역사", "readMinutes": 3, "tags": ["drawdown"] },
    { "id": "concentration-risk", "title": "한 종목에 몰려 있으면 생기는 일", "readMinutes": 2, "tags": ["concentration"] }
  ],
  "endMarker": "52일째 큰 변동 없이 지나가는 중"
}
```

조용 로우 표시 문구 규칙: `"{quietDays}일째 특이사항 없음 · 지켜보고 있어요"`. quietDays 1이면 `"오늘은 특이사항 없음 · 지켜보고 있어요"`.

---

## 2. 시나리오 B — calm · 일부 종목만 뉴스 (혼재)

검증 포인트: 히어로/컴팩트/조용 카드 동시 렌더, 정렬(high → low → quiet), 시장 스토리 노출, 학습 카드 태그 매칭, 상세 화면 전체 플로우.

```json
{
  "generatedAt": "2026-07-11T06:00:00+09:00",
  "severity": "calm",
  "caution": null,
  "briefing": {
    "message": "조용한 편이었어요. 보유 종목 중 2개에 새로운 소식이 있어요.",
    "tappable": false
  },
  "marketStory": {
    "headline": "연준 의사록, 9월 금리 인하 가능성 시사로 해석돼",
    "summary": "6월 FOMC 의사록 공개 후 위원 다수가 하반기 인하 여지를 언급한 것으로 보도됐어요. 시장 반응은 제한적이었어요.",
    "storyline": "연준은 올해 3월과 6월 금리를 동결했고, 시장은 9월 첫 인하를 예상해 왔어요. 이번 의사록은 그 예상을 크게 바꾸지 않았어요.",
    "updatedAt": "2026-07-11T06:00:00+09:00"
  },
  "tickerDigests": [
    {
      "ticker": "NVDA",
      "hasNews": true,
      "quietDays": 0,
      "materiality": "high",
      "headline": "엔비디아, 2분기 실적 발표 — 데이터센터 매출 예상 상회 보도",
      "summary": "엔비디아가 2분기 실적을 발표했어요. 데이터센터 부문 매출이 시장 예상을 웃돌았다는 보도가 이어졌고, 다음 분기 가이던스는 예상 범위 안이었어요.",
      "newFacts": [
        "데이터센터 매출이 시장 컨센서스를 상회했다고 발표",
        "3분기 가이던스는 애널리스트 예상 범위 내로 제시"
      ],
      "storyline": null,
      "articles": [
        { "title": "Nvidia tops data center revenue estimates in Q2", "source": "Reuters", "publishedAt": "2026-07-10T22:10:00+09:00", "url": "https://example.com/nvda-1" },
        { "title": "Nvidia earnings: what analysts are watching next", "source": "Barron's", "publishedAt": "2026-07-11T01:30:00+09:00", "url": "https://example.com/nvda-2" },
        { "title": "Nvidia guidance lands in line with expectations", "source": "Yahoo Finance", "publishedAt": "2026-07-11T02:05:00+09:00", "url": "https://example.com/nvda-3" }
      ]
    },
    {
      "ticker": "AAPL",
      "hasNews": true,
      "quietDays": 0,
      "materiality": "low",
      "headline": "애플, 인도 생산 비중 확대 계획 보도",
      "summary": "애플이 인도 내 생산 비중을 늘리는 방안을 검토 중이라는 보도가 있었어요. 회사의 공식 발표는 아직 없어요.",
      "newFacts": ["인도 생산 비중 확대 검토 보도 (공식 발표 아님)"],
      "storyline": null,
      "articles": [
        { "title": "Apple weighs expanding India production share", "source": "Reuters", "publishedAt": "2026-07-10T18:40:00+09:00", "url": "https://example.com/aapl-1" }
      ]
    },
    { "ticker": "QQQ",  "hasNews": false, "quietDays": 13, "summary": null, "newFacts": [], "articles": [] },
    { "ticker": "MSFT", "hasNews": false, "quietDays": 6,  "summary": null, "newFacts": [], "articles": [] }
  ],
  "learningCards": [
    { "id": "earnings-season", "title": "실적 시즌 읽는 법 — 가이던스가 더 중요한 이유", "readMinutes": 3, "tags": ["earnings"] },
    { "id": "rates-growth", "title": "금리가 성장주에 미치는 영향", "readMinutes": 2, "tags": ["rates"] }
  ],
  "endMarker": "오늘 브리핑은 여기까지예요"
}
```

상세 화면 검증용 참고값 (NVDA 헤더): 오늘 +1.8% → "내 자산의 12% · 총자산 기준 +0.22%". 번역 인라인 확장 Mock 텍스트:

> "실적이 예상보다 좋았다는 뜻이에요. 다만 다음 분기 전망은 '깜짝 놀랄 수준'이 아니라 '예상대로'였어요. 당신 자산에서 엔비디아는 12%를 차지하고 있어요. 오늘 발표로 달라진 사실은 위 두 가지가 전부예요."

(전망·권유 없음 — 이 톤이 기준선이다.)

---

## 3. 시나리오 C — alert · 큰 변동일

검증 포인트: 브리핑 카드 alert 변형(+base rate), caution 문구, 변동 큰 종목 우선 정렬, 시장 스토리 히어로 고정, 종료 마커 톤 변화, 레이아웃 구조가 calm과 동일함(전면 경고 화면 없음).

```json
{
  "generatedAt": "2026-07-12T06:00:00+09:00",
  "severity": "alert",
  "caution": {
    "active": true,
    "message": "며칠간 변동성이 커질 수 있는 구간이에요. 이런 구간은 지난 4년간 40번 넘게 있었고, 대부분 며칠 안에 지나갔어요.",
    "basis": "realized_vol"
  },
  "briefing": {
    "message": "물가 지표가 예상을 웃돌면서 나스닥이 3.2% 내렸어요. 이 정도 하락은 지난 4년간 30번 이상 있었던 수준이에요.",
    "tappable": true
  },
  "marketStory": {
    "headline": "6월 CPI 예상 상회 — 금리 인하 기대 후퇴로 기술주 약세",
    "summary": "6월 소비자물가가 시장 예상을 웃돌았어요. 9월 금리 인하 기대가 줄어들면서 금리에 민감한 기술주 중심으로 매도세가 나왔다는 분석이 보도됐어요.",
    "storyline": "시장은 연내 두 차례 인하를 가격에 반영해 왔어요. 이번 지표로 그 시점이 늦춰질 수 있다는 우려가 커졌어요.",
    "updatedAt": "2026-07-12T06:00:00+09:00"
  },
  "tickerDigests": [
    {
      "ticker": "QQQ",
      "hasNews": true,
      "quietDays": 0,
      "materiality": "high",
      "headline": "나스닥100, 물가 지표 여파로 3.2% 하락 마감",
      "summary": "CPI 발표 이후 지수 전반이 약세였어요. 특히 반도체와 대형 기술주의 낙폭이 컸다고 보도됐어요.",
      "newFacts": ["6월 CPI 전년 대비 상승률이 예상치 상회", "나스닥100 지수 -3.2% 마감"],
      "storyline": null,
      "articles": [
        { "title": "Nasdaq slides 3.2% as CPI tops forecasts", "source": "Reuters", "publishedAt": "2026-07-12T05:10:00+09:00", "url": "https://example.com/qqq-1" },
        { "title": "Hot inflation print pushes rate-cut bets back", "source": "Yahoo Finance", "publishedAt": "2026-07-12T05:40:00+09:00", "url": "https://example.com/qqq-2" }
      ]
    },
    {
      "ticker": "NVDA",
      "hasNews": true,
      "quietDays": 0,
      "materiality": "high",
      "headline": "엔비디아, 금리 우려 속 5.1% 하락 — 회사 관련 새 소식은 없어",
      "summary": "오늘 하락은 회사 자체 뉴스가 아니라 시장 전체의 금리 우려에 따른 것으로 보도됐어요. 엔비디아에 대한 새로운 사실은 확인되지 않았어요.",
      "newFacts": ["회사 고유의 신규 이슈 없음 — 시장 전반 요인으로 분류"],
      "storyline": null,
      "articles": [
        { "title": "Chip stocks lead declines amid rate worries", "source": "Reuters", "publishedAt": "2026-07-12T05:20:00+09:00", "url": "https://example.com/nvda-4" }
      ]
    },
    { "ticker": "AAPL", "hasNews": false, "quietDays": 1, "summary": null, "newFacts": [], "articles": [] },
    { "ticker": "MSFT", "hasNews": false, "quietDays": 7, "summary": null, "newFacts": [], "articles": [] }
  ],
  "learningCards": [
    { "id": "cpi-explained", "title": "CPI가 뭐길래 시장이 움직일까", "readMinutes": 2, "tags": ["cpi", "rates"] },
    { "id": "panic-sell-cost", "title": "떨어진 날 판 사람들은 어떻게 됐을까 — 패닉 셀의 역사적 비용", "readMinutes": 3, "tags": ["drawdown", "behavior"] }
  ],
  "endMarker": "이런 날일수록 천천히 보세요"
}
```

alert 시나리오 톤 주의:
- 헤드라인에 "폭락·충격·비상" 없음 — "하락", "약세"까지만. 숫자는 기사에 있는 것만.
- NVDA처럼 **회사 고유 뉴스 없이 시장 요인으로 빠진 종목**은 그 사실 자체가 핵심 정보다 ("새 소식은 없어") — 불안한 보유자에게 가장 안심이 되는 한 줄이므로 headline에 포함.
- 학습 카드 "패닉 셀의 역사적 비용"은 alert 날 우선 매칭 — 공포의 순간에 가장 필요한 개념.

---

## 4. 구현 노트

- `MockNewsroomDigestRepository`는 시나리오 A/B/C를 열거형(`MockNewsroomScenario`)으로 전환 가능하게. 디버그 설정에서 전환할 수 있으면 디자인 리뷰가 쉬워진다.
- 날짜 문자열은 하드코딩 대신 "오늘 기준 상대 날짜"로 생성해도 좋으나, `generatedAt` 06:00 KST 형태는 유지 (기준 시각 라인 렌더 검증용).
- 시나리오 A의 `marketStory: null` → 섹션 숨김, `caution: null` → 문구 부재 렌더를 반드시 확인할 것 (침묵 = 부재 원칙).
- 보유 종목 0 상태와 네트워크 에러 상태는 payload가 아니라 Repository 에러/빈 응답으로 별도 재현 (상세 가이드 §4.4).
