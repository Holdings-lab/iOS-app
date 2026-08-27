# egunHoldings iOS

egunHoldings는 정책 이벤트와 보유 자산의 연결을 보여주는 SwiftUI 기반 iOS 앱입니다. 현재 앱은 로그인/회원가입, 온보딩, 오늘 브리핑, 내 자산, 뉴스 흐름으로 구성되어 있으며 라이브 API 연결 지점과 목 데이터 폴백을 함께 사용합니다.

## 주요 기능

- 이메일 회원가입/로그인, 이메일 인증, 토큰 기반 세션 저장
- 관심 섹터, 투자 성향, 증권사 연결 여부를 수집하는 온보딩 플로우
- 오늘 탭: 정책 판단 카드, 총자산 요약, 정책 영향도, 판단 근거 바텀시트
- 내자산 탭: 정책 노출도 대시보드, 보유 자산 노출 매트릭스, 리밸런싱 시뮬레이션
- 뉴스 탭: 정책 뉴스 피드, 사용자 자산 기반 맞춤 해설, 저장/체크포인트/숨김 상태 관리
- KIS 샌드박스 잔고조회 중계 서버 연동 지점
- USD/KRW 환율 조회와 리밸런싱 계산 보조 로직

## 기술 스택

- SwiftUI
- Swift Concurrency
- Combine
- Swift Testing
- XCTest UI Testing
- Alamofire 5.11.1+
- Moya 15.0.3+
- UserDefaults 기반 로컬 세션/계정 저장

## 요구 사항

- Xcode 26 이상 권장
- iOS 26.0 이상 타깃
- Swift 5.0

프로젝트 설정상 앱, 테스트, UI 테스트 타깃은 모두 iOS 26.0을 기준으로 잡혀 있습니다.

## 시작하기

1. 저장소를 클론합니다.

   ```bash
   git clone https://github.com/Holdings-lab/iOS-app.git
   cd iOS-app
   ```

2. Xcode에서 `egunHoldings.xcodeproj`를 엽니다.

3. Swift Package 의존성이 자동으로 해석될 때까지 기다립니다.

4. 필요한 경우 `egunHoldings/DesignSystem/Fonts`에 Pretendard 폰트 파일을 추가합니다.

   - `Pretendard-Regular.otf`
   - `Pretendard-Medium.otf`
   - `Pretendard-SemiBold.otf`
   - `Pretendard-Bold.otf`

   폰트 파일이 없어도 앱은 시스템 폰트로 폴백합니다.

5. `egunHoldings` 스킴을 선택한 뒤 시뮬레이터에서 실행합니다.

## 네트워크 설정

앱은 `Config/Info.plist`에 주입된 값을 `NetworkConfiguration`에서 읽습니다. Debug와 Release 모두 기본값은 공유 HTTPS 서버를 가리키며, 필요한 경우 Xcode 빌드 설정이나 로컬 비추적 `.xcconfig`에서 덮어쓸 수 있습니다.

| 빌드 | Backend | ML | Trading |
| --- | --- | --- | --- |
| Debug | `https://holdings-lab.me` | `https://holdings-lab.me` | `https://holdings-lab.me` |
| Release | `https://holdings-lab.me` | `https://holdings-lab.me` | `https://holdings-lab.me` |

| 키 | 설명 |
| --- | --- |
| `BACKEND_BASE_URL` | `/api/**` 백엔드 베이스 URL입니다. 없으면 `https://holdings-lab.me`를 사용합니다. |
| `POLICY_BACKEND_BASE_URL` | 이전 설정명입니다. `BACKEND_BASE_URL`이 없을 때 호환용으로 읽습니다. |
| `ML_SERVICE_BASE_URL` | `/ml/**` ML 서비스 베이스 URL입니다. 없으면 백엔드 베이스 URL을 함께 사용합니다. |
| `AUTH_REFRESH_URL` | 자동 토큰 리프레시 API가 준비되면 사용할 전체 URL입니다. 없으면 리프레시 인터셉터를 붙이지 않습니다. |

실서비스 키, 계좌 식별자, 토큰 등 민감한 값은 저장소에 커밋하지 말고 로컬 `.xcconfig`나 CI/CD 시크릿으로 주입하는 방식을 권장합니다.

## 주요 API 연결

- 인증: `/api/auth/email/send-code`, `/api/auth/email/verify-code`, `/api/auth/register`, `/api/auth/login`, `/api/auth/oauth-login`
- 사용자/온보딩: `/api/me/{userId}`, `/api/me/{userId}/profile`, `/api/me/{userId}/watch-assets`
- 오늘 대시보드: `/api/home/{userId}`
- 정책 피드: `/api/content/{userId}/policy-feed`
- ML 정책 피드: `/ml/content/policy-feed`
- 이벤트/인사이트: `/api/events/{userId}`, `/api/insights/**`
- KIS 잔고조회: `/api/brokers/kis/sandbox/balance`
- 환율: `https://api.frankfurter.app/latest?from=USD&to=KRW`

## 프로젝트 구조

```text
Config/                  Info.plist, Debug/Release xcconfig
egunHoldings/
  App/                   앱 진입점, 라우터, 탭 내비게이션
  Common/                공통 UI 컴포넌트, 모델, 목 데이터, 네트워크 코어
  DesignSystem/          컬러/타이포 토큰, 앱 테마, 이미지 에셋, 폰트 안내
  Features/
    Auth/                로그인, 회원가입, 이메일 인증, 세션/계정 저장
    Onboarding/          관심 섹터, 투자 성향, 증권사 연결 플로우
    Today/               오늘 브리핑 대시보드와 정책 판단 시트
    Asset/               자산 노출도, 리밸런싱, KIS 잔고조회 연동 지점
    Newsroom/            정책 뉴스 피드와 맞춤 해설
    Signal/              리밸런싱 계산, ETF 매칭, 환율 보조 모델
egunHoldingsTests/       Swift Testing 유닛 테스트 타깃
egunHoldingsUITests/     XCTest UI 테스트 타깃
scripts/                 앱 아이콘 생성 스크립트
exports/                 공유용 앱 아이콘 산출물
```

## 현재 구현 상태

- 앱 진입은 저장된 세션을 확인한 뒤 인증, 온보딩, 메인 탭 중 하나로 라우팅합니다.
- 메인 탭은 `오늘`, `내자산`, `뉴스` 3개입니다. `Signal` 기능은 별도 탭이 아니라 내자산 리밸런싱 계산과 목 데이터 모델로 사용됩니다.
- 이메일 인증, 회원가입, 로그인은 라이브 백엔드 API를 사용합니다. 소셜 로그인 버튼은 OAuth 연동 전까지 탭 이벤트와 분기 지점만 유지합니다.
- Today 대시보드는 `/api/home/{userId}`를 호출하고, 사용자 ID가 없거나 서버 동기화에 실패하면 목 브리핑을 유지합니다.
- 뉴스 피드는 `/api/content/{userId}/policy-feed`를 우선 사용하고, 사용자 ID가 없거나 404/미구현 응답이면 목 데이터로 폴백합니다.
- 맞춤 뉴스 해설, Asset 대시보드, Signal/ETF 매칭 데이터는 현재 목 저장소 기반입니다.
- KIS 샌드박스 잔고조회는 로그인/부트스트랩 시 연결된 세션에서 `/api/brokers/kis/sandbox/balance`를 호출할 수 있도록 준비되어 있습니다.
- 테스트 타깃은 생성되어 있으나 실제 검증 케이스는 아직 확장 전입니다.

## 빌드 확인

Xcode가 설치된 환경에서는 아래 명령으로 빌드할 수 있습니다.

```bash
xcodebuild -project egunHoldings.xcodeproj -scheme egunHoldings -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build
```

터미널 빌드가 실패하면 `xcode-select -p`가 전체 Xcode 경로를 가리키는지 확인하세요.

## 리뷰 자동화 확인

CodeRabbit GitHub App 연결 확인을 위해 테스트 PR을 생성할 수 있습니다.
