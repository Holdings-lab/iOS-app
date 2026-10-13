# 뉴스 미노출 및 오늘·뉴스룸 로딩 진단

확인일: 2026-09-09 PDT. 로컬 iOS `feat/final`, backend-api `main`,
Hodlings/data-ml `crawler` 기준. 배포 코드가 로컬 HEAD와 같은지는 확인하지 못했다.
백엔드와 크롤러 저장소는 수정하지 않았다.

## 확인된 현상

- 첨부 화면의 “관련 뉴스가 아직 없어요”는 iOS의
  `NewsroomBriefing.hasNoRelevantNews` 조건, 즉 보유 종목이 한 개 이상이고
  모든 `briefingType`이 `Quiet`일 때 표시된다. 서버 오류/보유 자산 없음과 별개다.
  다만 이 세션에서 해당 계정의 인증된 `/api/newsroom` 원문을 확보하지는 못했다.
- 공개 `GET https://holdings-lab.me/api/feeds/policy?limit=50`를
  2026-09-09 23:17 UTC에 확인: HTTP 200, `isSuccess=true`, 50개 카드.
  한 번 측정한 총 응답 시간 1.535초, 첫 바이트 0.976초.
  사용자별 뉴스룸 성능 측정값은 아니다.
- 위 50개 기사의 날짜는 2026-08-29 20개, 2026-08-28 30개였다.
  `generatedAt`은 요청 시각인 9월 9일이지만 기사 날짜는 오래되어 있었다.
  `assetSignals`는 QQQ 50개, SOXX 50개, USD 34개이며 `impact.targetAssets`는 없었다.
  따라서 “크롤러 최신 뉴스가 계속 전달된다”는 증거로 볼 수 없다.
- 확인한 기사 이미지에는 `thumbnailUrl: "nan"`이 들어 있었다.

## 실제 전달 경로와 끊길 수 있는 지점

```text
Hodlings/data-ml/crawler/collectors/policy_monitor.py
  수집 → 요약/감성/임베딩 → policy_updates_features.csv
    ↓ 공유 볼륨 / 배포된 수집·적재 작업
backend-api/data-ml
  DB policy_documents + policy_document_features 우선
  DB가 비거나 조회 실패할 때에만 CSV fallback
    ↓ GET /ml/feeds/policy?userId=...&limit=50
Spring PolicyFeedProxyService → NewsroomService
  실제 연결 계좌의 보유 종목별 매칭 → Hero / Compact / Quiet
    ↓ 인증된 GET /api/newsroom
iOS DTO → NewsroomBriefing → 화면
```

### 1. 수집 성공과 DB 반영 성공이 연결되지 않을 수 있음

- 현재 크롤러 `run_monitor`는 CSV를 저장한다. 기본 경로는
  `/opt/riseai/data/crawler/policy_updates_features.csv`다.
- 서버 CSV fallback 경로는 Docker 기준
  `/app/data/crawler/features/policy_updates_features.csv`다.
  compose에서는 `/app/data`와 `/opt/riseai/data/crawler`가 각각 별도 마운트다.
  복사/적재 연결이 없으면 DB가 비어도 새 크롤러 파일을 읽지 못한다.
- 서버 `data-ml/crawler/external.py`는 외부 크롤러를 `--max-cycles 1`로 실행한다.
  `lstm_signal/runner.py:prepare_features_from_crawl`는 실행 후 기존 피처를 반환한다.
- `db/db.py:persist_policy_pipeline_outputs`는 존재하지만, 현재 backend-api의
  Python 소스에서 실제 호출부를 찾지 못했다. 별도 운영 적재 작업 유무는 확인이 필요하다.
- `app.py:_read_policy_feed_frame`은 DB에 한 행이라도 있으면 CSV를 확인하지 않는다.
  따라서 새 CSV가 생성되어도 DB가 갱신되지 않으면 오래된 뉴스가 계속 제공될 수 있다.

### 2. 사용자 필터가 신호 생성보다 앞섬

- `app.py:_filter_policy_feed_by_user_assets`는
  `user_watch_assets.asset_name`과 기존 행의 `assetSignals` 또는
  `feature_payload.assetSignals`의 ticker 교집합으로 필터링한다.
- 그런데 현재 크롤러는 `sector`를 저장하며 `assetSignals`를 생성하지 않는다.
  서버의 `_build_policy_feed`는 필터가 끝난 뒤에 모델/키워드 `assetSignals`를 만든다.
- 예: `sector=qqq`, 제목/본문이 있는 정상 CSV 행이라도 기존 `assetSignals`가 없고
  사용자 관심 자산이 있으면 필터에서 제거된다. 이후 신호 생성까지 도달하지 못한다.
  공개 피드는 `userId`가 없어 이 필터를 건너뛰므로 공개 피드 성공과 개인 뉴스룸 성공은 다르다.
- 뉴스룸은 이 결과를 다시 실제 `asset_positions` 보유 종목으로 매칭한다.
  관심 자산과 실제 보유 종목의 집합이 다르면 두 번째 단계에서도 누락될 수 있다.
- QQQ 모델 신호를 기사 관련 티커로 쓰는 방식도 분리할 필요가 있다.
  회사 이름이 있는 기사에 실제 관련 종목 메타데이터가 없으면 ticker 문자열 검색만으로는
  해당 회사의 보유 종목과 매칭되지 않을 수 있다.

### 3. 이미지 필드명이 다름

- 현재 크롤러 표준 컬럼은 `image`다.
- 서버 CSV 변환은 `thumbnail_url` 또는 `image_url`을 읽고,
  DB 쿼리는 `raw_payload->>'thumbnail_url'`만 읽는다.
- `image → thumbnail_url → thumbnailUrl/imageUrl` 변환을 적재 시점에 통일해야 한다.
  결측값은 JSON `null`, 유효값은 절대 HTTP(S) URL이어야 한다.

### 4. 서버 로고 조회가 뉴스 응답을 지연시킬 수 있음

- `NewsroomService.getNewsroom`은 응답 작성 전에 `StockLogoService.preloadLogos`를 호출한다.
- `preloadLogos`는 캐시가 없는 티커를 순서대로 조회하고 각 외부 요청 timeout은 5초다.
  서버 캐시가 비어 있고 외부 API가 느릴 때 보유 종목 수만큼 지연이 누적될 수 있다.
- ML 프록시 호출 자체도 최대 12초까지 대기한다. 이 시간은 iOS timeout을 줄여도
  성공 응답이 빨라지는 문제가 아니므로 서버 쪽 개선이 필요하다.

## 이번 iOS 변경

- 오늘의 네 API는 병렬 호출을 유지하면서 도착한 섹션부터 표시한다.
  느린 뉴스 요청이나 브리핑 요청이 다른 카드의 표시를 막지 않는다.
- 로그인 세션이 소유하는 뉴스룸 저장소를 두 탭이 공유한다.
  동시에 요청하면 진행 중 요청 하나를 기다리고, 성공한 목록은 메모리에서 60초 재사용한다.
  오류는 캐시하지 않는다. 수동 새로고침은 캐시를 갱신하고, 자산 변경 시 무효화한다.
  계정 전환/로그아웃 후에는 다른 세션의 저장소를 사용한다. 디스크 저장은 하지 않는다.
- 뉴스룸 재진입 때 공유 저장소의 최신 결과를 읽는다. 화면에 있던 내용은 유지한다.
- 오늘의 기사 목록에서 `Quiet`을 제외한다. 빈 응답이나 오류를 샘플 기사로 대체하지 않는다.
- 잔고 세션 갱신 시 서버에서 받은 오늘 데이터를 통째로 mock 데이터로 다시 덮는 경로를 제거했다.
- 더 최신 새로고침이 시작되면 이전 오늘 조회를 취소하고, 연속 세션 변경은 최신 것만 처리한다.
  기존 Moya 취소 핸들을 통해 더 이상 필요하지 않은 개별 API 요청도 취소된다.

## 백엔드/data-ml 담당자에게 전달할 요청 초안

> 뉴스룸에서 보유 종목이 전부 Quiet으로 표시됩니다. 공개 정책 피드는 9월 9일에도
> 최신 50개가 8월 28~29일 기사였습니다. 다음 연결부를 함께 수정·확인 부탁드립니다.
>
> 1. 크롤러 완료 후 CSV를 `policy_documents/policy_document_features`에 적재하는 작업을
>    명시적으로 연결하고, 성공 건수·마지막 수집/적재 시각을 기록해주세요.
>    출력 `/opt/riseai/data/crawler`와 읽기 `/app/data/crawler/features` 경로도 통일해주세요.
>    오래된 DB가 최신 CSV를 가리는 문제를 해결하고 재적재는 idempotent하게 해주세요.
> 2. 기사 관련 티커/sector를 정규화해 적재하거나, 동일한 매핑을 사용자 필터 전에
>    수행해주세요. 현재 필터는 아직 생성되지 않은 assetSignals를 요구합니다.
>    예측 모델의 대상 티커와 기사의 관련 티커는 별도 필드로 구분해주세요.
> 3. 뉴스룸의 대상은 실제 연결 계좌의 보유 종목으로 통일해주세요.
>    관심 자산 필터와 보유 종목 필터의 이중 적용으로 실제 보유 뉴스가 사라지지 않도록
>    뉴스룸 전용 ticker 필터를 적용하고, 종목 매칭 후 최신순 제한/종목별 개수 제한을 해주세요.
>    인증된 현재 사용자에서 티커를 도출해야 하며 임의 userId로 우회하지 않습니다.
> 4. 이미지 필드를 `image → thumbnail_url → thumbnailUrl/imageUrl`로 통일하고
>    빈 문자열/NaN/"nan"은 null로 내려주세요.
> 5. 최초 뉴스 요청에서 종목별 로고 API를 순차 대기하지 않도록 로고를 미리 적재하거나
>    캐시된 URL만 반환해주세요. 캐시 미스는 null로 응답해도 됩니다.
> 6. 응답의 기준시각은 요청 시각/고정 06:00가 아니라 실제 데이터 갱신 시각을 별도로
>    제공해주세요. 정상 무소식, 수집 지연, 미지원 종목, upstream 장애를 구분해주세요.
>
> 검증 시 같은 인증 사용자에 대해 보유 ticker, 관심 asset_name, DB/CSV 최신 기사 날짜,
> 필터 전/후 개수, 종목 매칭 후 개수, ML/DB/로고별 소요 시간을 확인해주세요.
> 토큰·계좌번호·금액은 로그에 남기지 않아도 됩니다.
>
> 회귀 검증에는 “sector만 있는 새 기사”, “관심 자산과 보유 종목이 다른 사용자”,
> “기사에 회사명만 있는 경우”, “실제 뉴스 없음”, “ML 실패”, “오래된 DB+새 CSV”,
> “로고 서비스 지연”을 포함해주세요.

## 검증 범위와 남은 확인

iPhone 17 Pro / iOS 26.1 Simulator에서 빌드 및 관련 테스트 23개 통과
(매개변수별 실행 포함 25회, 실패 0). `DashboardLoadingTests`,
`NewsroomAndSignalAPIContractTests`, `NewsroomAIJudgementStoreTests`를 실행했다.
요청 공유, 캐시 만료/갱신/실패 재시도/세션 분리, Quiet 필터링, 부분 표시와
이전 요청 취소를 검증했다.

전체 단위 테스트 실행에서는 변경하지 않은 `BrokerageAPIContractTests.mapsBackendPortfolio`
1개가 별도로 실패했다. 해당 fixture에 `byBroker`가 없지만 계좌번호 `1234567801`을
기대한다. 기존 변환 코드는 이 경우 빈 계좌번호를 반환한다. 뉴스 수정에서 자산 계약과
그 테스트는 변경하지 않았다.

서버 ticker 추출 함수도 합성 행으로 별도 확인했다. `sector=qqq`만 있는 행은
추출 결과가 빈 집합이고, `feature_payload.assetSignals=[{ticker:QQQ}]`를 넣으면
QQQ가 추출됐다. 이는 저장 필드와 필터 사이의 불일치 재현이며 해당 사용자의 실응답은 아니다.

로그인된 실제 계정의 뉴스가 표시되는지와
사용자별 p50/p95 응답 시간은 서버 변경 후 인증된 세션에서 추가 확인해야 한다.
이 문서는 전달용 초안이며 담당자에게 전송하지 않았다.
