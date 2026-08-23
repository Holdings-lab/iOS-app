# 뉴스룸 탭 — API·서버 연동 스펙 (클라이언트 제안)

> 작성일 2026-07-18 · 브레인스토밍 세션 캡처본 · **살아있는 문서 — 대화하면서 계속 업데이트**
> 상위 문서: `docs/product/뉴스룸-탭-스펙.md` (제품 스펙) — 이 문서는 그 스펙을 실제 API 계약으로 옮기는 구현 준비 문서다.
>
> **문서 성격:** 서버는 담당자가 따로 있다. 이 문서는 클라이언트(iOS)가 필요한 데이터·DTO를 기준으로 먼저 구상한 **제안 계약**이며, 서버팀에 공유해 함께 수정해 나간다. 아래 "결정"들은 클라이언트 제안이지 서버 확정이 아님 — 서버 협의 후 변경분은 변경 이력에 기록한다. 클라이언트는 그동안 이 계약 기준으로 DTO·Live 리포지토리를 만들되 Mock 뒤에서 개발한다.

---

## 0. 현재 상태 (2026-07-18 코드 기준)

- **클라이언트:** `NewsroomDigest` 모델·뷰 트리는 신 스펙 기준으로 구현돼 있으나 `NewsroomDigestRepositoryFactory`가 `MockNewsroomDigestRepository`를 반환 중. `LiveNewsroomDigestRepository`는 아직 없음.
- **네트워크 레이어:** `BackendEndpoint`(`/api/…`, bearer 토큰)와 `MLEndpoint`(`/ml/…`) 두 갈래가 이미 존재.
- **서버:** 뉴스룸 다이제스트 파이프라인(뉴스 수집 → dedup → Haiku 요약 → 캐시)은 미구현.

## 1. 결정 사항

| # | 항목 | 결정 | 근거 |
|---|---|---|---|
| D0 | 스펙 범위 | **API 계약만** — 서버 내부 파이프라인 설계는 별도 세션 | 클라이언트 Live 리포지토리 구현 준비가 1차 목표 |
| D1 | 생성·서빙 주체 | **백엔드 단독** (`/api`, bearer 인증) | 인증·보유 데이터 접근이 한 곳에서 해결. ⚠️ 리스크: yfinance는 Python 라이브러리라 백엔드가 자체 뉴스 소스 클라이언트를 가져야 함 — 제품 스펙 §2.5 `NewsSourceProvider` 추상화가 백엔드 책임이 됨 |
| D2 | 엔드포인트 계약 | **GET digest + POST jobs, 2개** — §2 | 단일 페이로드 아키텍처(제품 스펙 §4.3)와 정합 |
| D3 | 온보딩 즉시 생성 방식 | ~~클라 명시 POST~~ → **서버 내부 트리거** (2026-07-19 수정). 계좌 연결(`POST /brokerage-connections`) 성공 + 보유 종목 동기화 완료 시 서버가 자동으로 첫 생성. 클라는 digest GET의 `status` 필드 폴링만. POST 엔드포인트는 `failed` 재시도 전용으로 축소 | 이 앱은 수동 자산 등록이 없어 "첫 자산 등록" = 계좌 연결. 연결 직후엔 보유 동기화가 미완료일 수 있어 클라 트리거는 빈 보유 상태 생성 레이스가 있음. 서버만 동기화 완료 시점을 앎. 부수 효과: Step 7(계좌 연결)이 온보딩 중간이라 뉴스룸 첫 진입 시 이미 ready일 확률 높음 |
| D4 | 가격·비중 조립 | **서버가 페이로드에 포함** | 단일 페이로드 유지, 클라는 디코딩만. 백엔드 단독(D1) 결정과 일관 |
| D5 | 시각 표현 | **타임스탬프(ISO 8601)만 서버가 제공, 문구는 클라 생성** | 카피 가드레일·현지화가 앱 쪽 소유. `nextUpdateText` → `nextUpdateAt` 기반 계산 프로퍼티로 전환 |
| D6 | 매크로 배너 요약 생성 방식 | **배치 시점 전역 사전 생성** — §4.1 | 조회는 LLM 트리거 없음 원칙 유지. Haiku 호출 소폭 증가 감수 |
| D7 | 오늘 탭 컨벤션 정합 (2026-07-19) | ① 미연동 표현: **`isAccountLinked` 최상단 필드 채택**, `status` enum은 ready/generating/failed 3개로 축소 (no_assets 제거) ② 경로: **플랫 kebab-case** `/newsroom-digest` | 오늘 탭 계약(daily-briefing/holdings/holdings-news)과 동일 패턴 — "`isAccountLinked === false`면 다른 필드 안 보고 연결 유도 카드" 규칙을 앱 전체에서 재사용. 수동 자산 등록이 없으므로 "보유 0개" ≈ "계좌 미연동" |

## 2. 엔드포인트 계약

기존 `/api/users/{userId}/…` + bearer 컨벤션을 따른다.

```
GET  /api/users/{userId}/newsroom-digest           # 다이제스트 조회 (단일 페이로드)
POST /api/users/{userId}/newsroom-digest/retries   # failed 상태 재시도 전용 (온보딩 트리거 아님 — D3)
```

### 2.1 GET digest

- 리스트+상세 전체를 한 번에 내려준다 — 상세 화면 별도 요청 없음 (제품 스펙 §4.3).
- pull-to-refresh는 같은 GET 재호출. **LLM 파이프라인을 절대 트리거하지 않는다** (제품 스펙 §5). 클라이언트는 `generatedAt` 비교로 "이미 최신이에요" 판정.
- HTTP는 도메인 상태와 분리: 도메인 상태는 항상 `200` + `status` 필드로. `401`(인증), `5xx`(서버 오류)만 HTTP 레벨 — 클라는 "로드 실패" 상태로 처리.

**미연동 게이트 + `status` 값과 리스트 화면 4상태 매핑:**

| 응답 | 의미 | 클라 화면 (제품 스펙 §3.4) |
|---|---|---|
| `isAccountLinked: false` | 계좌 미연동 (= 보유 종목 없음) | 계좌 연결 CTA — 다른 필드는 보지 않는다 (오늘 탭과 동일 규칙) |
| `status: ready` | 캐시된 다이제스트 있음 | 정상 리스트 (isStale=true면 오프라인 표기) |
| `status: generating` | 첫 생성 진행 중 | "첫 브리핑을 준비하고 있어요" |
| `status: failed` | 첫 생성 실패, 캐시 없음 | "불러오지 못했어요" + 재시도 버튼 (재시도 = POST retries). 다음날 정기 배치가 자동 복구 |

- HTTP 자체가 실패(네트워크 단절, 5xx)한 경우도 클라는 "로드 실패"로 — `failed`와 같은 화면, 다른 원인.

### 2.2 온보딩 첫 생성 — 서버 내부 트리거 (D3)

- **클라이언트는 생성을 트리거하지 않는다.** `POST /brokerage-connections` 성공 후 보유 종목 동기화가 완료되면 서버가 내부적으로 첫 다이제스트 생성을 시작한다 (제품 스펙 §5.1 온보딩 예외의 서버 측 구현).
- 클라이언트는 뉴스룸 진입 시 GET digest 폴링만: **2초 간격, 최대 60초.** 타임아웃 시 "로드 실패" 화면으로 폴백.
- Step 7(계좌 연결)이 온보딩 중간이므로, 사용자가 나머지 온보딩을 진행하는 동안 서버가 생성을 끝내 뉴스룸 첫 진입 시 이미 `ready`일 확률이 높다.

### 2.3 POST retries

- `status: failed`일 때 재시도 버튼이 호출. 응답: `202 Accepted` + `{ "status": "generating" }`.
- **멱등:** 이미 생성 중이면 동일하게 `202`. 이미 캐시가 있으면 `200` + `{ "status": "ready" }` (no-op).

## 3. 응답 스키마 (DTO)

> **엔벨로프:** 백엔드 공통 응답 형식 `{ "isSuccess", "code", "message", "result" }`를 따르며, 아래 스키마는 `result`의 내용이다. `status`가 `generating`/`failed`/`no_assets`여도 `isSuccess: true` — 도메인 상태이지 API 실패가 아니다.

```jsonc
// GET /api/users/{userId}/newsroom-digest → 200
{
  "isAccountLinked": true,                 // false면 클라는 아래 필드를 전부 무시하고 계좌 연결 CTA (오늘 탭 공통 규칙)
  "status": "ready",                       // ready | generating | failed — isAccountLinked=true일 때만 의미
  // ↓ status == "ready" 일 때만 존재. 그 외 상태에서는 전부 null/생략.
  "generatedAt": "2026-07-18T06:00:00+09:00",
  "nextUpdateAt": "2026-07-19T06:00:00+09:00",
  "isStale": false,                        // 최신 배치 실패로 이전 캐시 서빙 중이면 true
  "macroIssue": {                          // null 가능 — 겹침 이슈 없으면 null (섹션 숨김)
    "headline": "미·중 반도체 수출 규제 확대 발표",
    "summary": "…",
    "affectedTickers": ["NVDA", "TSM"]
  },
  "tickerDigests": [
    {
      "ticker": "NVDA",
      "name": "엔비디아",
      "hasNews": true,
      "quietDays": 0,                      // hasNews=false일 때 의미 있음, 서버가 계산
      "priceChangePercent": -2.1,          // null 가능 (시세 조회 실패)
      "portfolioWeightPercent": 12,
      "logoUrl": "https://…",              // null 가능 → 클라가 이니셜 아이콘 폴백
      "headline": "…",                     // hasNews=false면 null
      "subheadline": "…",
      "summary": "…",
      "newFacts": ["…"],                   // 빈 배열 가능 — 클라는 섹션 생략
      "aiView": "…",                       // null 가능
      "representativeImage": {             // null 가능 → 클라가 로고+회사명 폴백 (§4.0)
        "url": "https://…",
        "attribution": "Reuters"
      },
      "articles": [
        {
          "id": "a3f9…",                   // 소스 제공 uuid
          "title": "…",
          "source": "Reuters",
          "publishedAt": "2026-07-18T02:14:00Z",
          "url": "https://…"
        }
      ]
    }
  ]
}
```

**클라이언트 매핑 노트:**

- `isStale` → `NewsroomDigest.isOffline`.
- `nextUpdateText`·`referenceText`는 클라 계산 프로퍼티로 전환 (D5) — 모델의 `nextUpdateText: String` 저장 프로퍼티 제거.
- 정렬·히어로 선정은 지금처럼 클라(`sortedTickerDigests`, `heroTickerIDs`)가 수행 — 서버 순서에 의존하지 않는 기존 방침 유지.
- `quietDays` ≤ 1 → "오늘은 특이사항 없음" 등 문구 규칙은 기존 모델 그대로.
- 종목 단위 수집 실패는 계약상 구분되지 않는다 — 서버가 `hasNews=false` + `quietDays`로 흡수 (제품 스펙 §2.5 원칙: 사용자는 "수집 실패"와 "조용한 날"을 구분할 필요 없음).

## 4. 계약에 영향을 주는 서버 측 제약

### 4.1 매크로 이슈 감지는 조립 시점 계산이다

제품 스펙 §2.2의 uuid 겹침 감지는 **사용자의 보유 종목 조합에 따라 결과가 달라진다.** 종목 단위 캐시(제품 스펙 §2.4)는 전역이지만, "어떤 uuid가 2개 이상 겹치는가"는 사용자별 조립 시점에만 판정 가능. 따라서:

- 종목 캐시에 기사 uuid 목록을 보존해야 한다 (응답의 `articles[].id`가 그 uuid).
- 매크로 배너 노출 여부는 요청 시 조립 단계에서 계산된다.
- **결정(D6): 배치 시점 전역 사전 생성.** 배치 때 "전역적으로 2개 이상 종목 피드에 겹친 기사"에 한해 매크로 요약(headline/summary 한국어)을 uuid별로 미리 생성·캐시한다. 조립 시엔 **사용자 보유 종목 기준으로 그 uuid가 2개 이상 겹치는지 게이팅만** 하고, 캐시된 요약을 그대로 내려준다. `affectedTickers`는 사용자 보유 종목과의 교집합만 담는다 (전역 겹침 목록이 아님 — "내 포트폴리오" 프레임 유지). 조회 경로에 LLM 호출 없음.

### 4.2 quietDays

서버가 종목별 "마지막 뉴스 날짜" 이력을 유지해야 계산 가능. 계약상 클라는 정수 하나만 받는다.

## 5. 실패·상태 시맨틱 요약

| 상황 | 서버 동작 | 계약 표현 | 클라 화면 |
|---|---|---|---|
| 특정 종목 수집 실패 | 조용 상태로 흡수 | `hasNews: false` + `quietDays` | 조용 로우 |
| 전체 배치 실패 (캐시 있음) | 이전 캐시 서빙 | `status: ready` + `isStale: true` | 정상 리스트 + "(오프라인)" 표기 |
| 온보딩 생성 실패 (캐시 없음) | 실패 기록 | `status: failed` | 로드 실패 + 재시도 (POST retries) |
| 계좌 미연동 (= 보유 없음) | — | `isAccountLinked: false` | 계좌 연결 CTA |
| 네트워크·서버 장애 | — | HTTP 5xx / 타임아웃 | 로드 실패 + 재시도 |

## 6. 미결정 항목 (Open Questions)

| 항목 | 내용 | 비고 |
|---|---|---|
| 로고 URL 소스 | 자체 에셋 서빙 vs 외부 CDN | nullable이라 계약은 확정 가능, 소스만 미정 |
| 폴링 파라미터 | 2초/60초는 잠정치 | 구현하며 조정 |
| 서버 파이프라인 상세 | 수집 소스 클라이언트, 캐시 스토리지, Haiku 프롬프트 사양 | D0에 따라 별도 세션 |

## 6.1 서버팀 확인 필요 사항 (공유 시 논의 안건)

1. **경로·컨벤션** — `/api/users/{userId}/newsroom-digest`, `…/newsroom-digest/retries`가 백엔드 라우팅 관행과 맞는지. 필드 네이밍(camelCase)·타임스탬프 포맷(ISO 8601, KST 오프셋 포함) 확인.
1-1. **온보딩 내부 트리거(D3)** — 계좌 연결 후 "보유 종목 동기화 완료" 시점을 서버가 어떻게 판정하는지(Hyphen 첫 스크래핑 완료 이벤트 등). 첫 생성 시작 조건의 정의가 서버 몫이 됨.
2. **가격·비중 조립(D4)** — 서버가 보유 정보+시세를 다이제스트 페이로드에 조립하는 게 서버 구조상 타당한지. 부담되면 "클라이언트 머지" 대안으로 되돌릴 수 있음 (계약 분리 지점).
3. **뉴스 소스(D1 리스크)** — yfinance 대체 수단(자체 클라이언트 vs 라이선스 API). 계약엔 영향 없으나 `articles[].id`(uuid)와 썸네일 제공 여부는 소스에 따라 달라짐.
4. **quietDays 이력(§4.2)** — 종목별 마지막 뉴스 날짜 저장 필요. 서버가 어렵다면 클라 로컬 계산 대안 논의.
5. **매크로 요약 사전 생성(D6)** — 배치 파이프라인에 전역 겹침 기사 요약 단계 추가 가능한지.
6. **폴링 파라미터** — 2초/60초 잠정치, 서버 생성 소요 시간 실측 후 조정.

## 7. 변경 이력

- 2026-07-18 — 세션 시작. 현재 상태 정리, D0~D5 확정: 범위는 API 계약만, 백엔드 단독 서빙, 비동기 job + digest GET `status` 폴링, 서버 조립(가격·비중 포함), 타임스탬프 기반 시각 표현. 엔드포인트 2개·응답 스키마·실패 시맨틱 초안 작성. 매크로 이슈 조립 시점 계산 제약(§4.1)과 D6(배너 요약 생성 방식) 도출.
- 2026-07-18 — D6 확정: 매크로 배너 요약은 배치 시점 전역 사전 생성, 조립 시엔 사용자 보유 기준 게이팅만. `affectedTickers`는 사용자 보유 종목과의 교집합만 담기로 명시(§4.1).
- 2026-07-18 — 문서 성격을 "클라이언트 제안"으로 재프레이밍 (서버 담당자 별도, 공유 후 협의 예정). §6.1 서버팀 확인 필요 사항 추가. §3에 공통 엔벨로프 노트 추가.
- 2026-07-19 — **오늘 탭 API 문서와 정합 (사용자 지적):** ① D3 수정 — 온보딩 첫 생성을 클라 명시 POST에서 서버 내부 트리거로 변경. 근거: 수동 자산 등록이 없어 "첫 자산 등록"="계좌 연결"인데, 연결 직후엔 보유 동기화 미완료 레이스가 있고 완료 시점은 서버만 앎. POST는 `…/retries`(failed 재시도 전용)로 축소. ② D7 신설 — `isAccountLinked` 최상단 필드 채택(status에서 no_assets 제거), 경로를 플랫 kebab-case `/newsroom-digest`로. 클라 코드(엔드포인트·DTO·리포지토리) 동기 수정.
- 2026-07-18 — **클라이언트 선제 구현 완료:** `NewsroomDigestNetworkDTOs.swift`(status enum·도메인 매핑·`NewsroomDigestServiceError`), `LiveNewsroomDigestRepository.swift`(generating 폴링 2초/60초, Mock 폴백 없음 — 가짜 브리핑 방지), `BackendEndpoint.newsroomDigest`/`.newsroomDigestJob`, 프로토콜에 `requestFirstGeneration()` 추가(기본 no-op). 팩토리는 Mock 유지 — 서버 배포 후 한 곳만 교체. 남은 클라 작업: 온보딩 시 `requestFirstGeneration()` 호출 와이어링 + status 기반 "첫 브리핑 준비 중" 화면 연결.
