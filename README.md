# egunHoldings iOS

egunHoldings는 정책 변화와 포트폴리오 노출도를 함께 보여주는 SwiftUI 기반 iOS 앱입니다. 현재 구현본은 로컬 인증, 온보딩, 정책 브리핑, 시그널, 자산 노출도, 뉴스룸 화면을 중심으로 구성되어 있으며 일부 데이터는 목 데이터와 라이브 API 연결 지점을 함께 사용합니다.

## 주요 기능

- 이메일 회원가입/로그인 및 세션 저장
- 온보딩 플로우와 투자 성향 기반 홈 진입
- 홈 대시보드: 정책 이벤트, 포트폴리오 요약, 주요 정책 영향도
- 시그널 탭: 정책 액션 큐, ETF 매칭, 리밸런싱 시뮬레이션
- 내 자산 탭: 정책 노출도 대시보드, 보유 종목 노출 매트릭스, 시나리오 리밸런싱
- 뉴스룸 탭: 정책 뉴스 피드와 사용자 자산 기반 맞춤 해설
- USD/KRW 환율 조회 및 KIS 샌드박스 잔고조회 서버 연동 지점

## 기술 스택

- SwiftUI
- Swift Concurrency
- Swift Testing
- Alamofire 5.11.1+
- Moya 15.0.3+
- UserDefaults 기반 로컬 세션/계정 저장

## 요구 사항

- Xcode 26 이상 권장
- iOS 26.2 이상 타깃
- Swift 5

프로젝트 설정상 앱, 테스트, UI 테스트 타깃이 모두 iOS 26.2를 기준으로 잡혀 있습니다.

## 시작하기

1. 저장소를 클론합니다.

   ```bash
   git clone https://github.com/Holdings-lab/iOS-app.git
   cd iOS-app
   ```

2. Xcode에서 `egunHoldings.xcodeproj`를 엽니다.

3. Swift Package 의존성이 자동으로 해석될 때까지 기다립니다.

4. 필요한 경우 `egunHoldings/Resources/Fonts`에 Pretendard 폰트 파일을 추가합니다.

   - `Pretendard-Regular.otf`
   - `Pretendard-Medium.otf`
   - `Pretendard-SemiBold.otf`
   - `Pretendard-Bold.otf`

   폰트 파일이 없어도 앱은 시스템 폰트로 폴백합니다.

5. `egunHoldings` 스킴을 선택한 뒤 시뮬레이터에서 실행합니다.

## 네트워크 설정

앱은 `Info.plist` 또는 빌드 설정의 Info.plist 키를 통해 아래 값을 읽습니다.

| 키 | 설명 |
| --- | --- |
| `POLICY_BACKEND_BASE_URL` | 정책 뉴스와 맞춤 해설 API의 베이스 URL입니다. 없으면 목 뉴스 데이터로 폴백합니다. |
| `TRADING_SERVER_BASE_URL` | KIS 샌드박스 잔고조회 중계 서버 URL입니다. Debug 빌드에서는 기본값으로 `http://localhost:8080`을 사용합니다. |
| `TRADING_KIS_ACCOUNT_NUMBER` | KIS 샌드박스 계좌번호입니다. |
| `TRADING_KIS_PRODUCT_CODE` | KIS 상품 코드입니다. |

실서비스 키, 계좌 식별자, 토큰 등 민감한 값은 저장소에 커밋하지 말고 로컬 `.xcconfig`나 CI/CD 시크릿으로 주입하는 방식을 권장합니다.

## 프로젝트 구조

```text
egunHoldings/
  App/                 앱 진입점, 루트 플로우, 탭 내비게이션
  Core/                공통 확장과 뷰 모디파이어
  Data/                네트워크, 저장소, 목 데이터, repository 구현
  Features/            Auth, Onboarding, Home, Signal, Asset, Newsroom 화면
  Model/               도메인 모델과 repository 프로토콜
  Resources/           앱 리소스 안내
  Shared/              공통 UI 컴포넌트와 앱 테마
egunHoldingsTests/     유닛 테스트 타깃
egunHoldingsUITests/   UI 테스트 타깃
scripts/               앱 아이콘 생성 스크립트
exports/               공유용 디자인/아이콘 산출물
```

## 현재 구현 상태

- 인증은 실제 OAuth가 아닌 로컬 계정/세션 저장 기반입니다.
- 증권사 연결 UI는 스텁이며, KIS 샌드박스 잔고조회 서버 연동 지점이 준비되어 있습니다.
- 정책 뉴스는 백엔드 URL이 없으면 목 데이터로 동작합니다.
- 테스트 타깃은 생성되어 있으나 실제 검증 케이스는 아직 확장 전입니다.

## 빌드 확인

Xcode가 설치된 환경에서는 아래 명령으로 빌드할 수 있습니다.

```bash
xcodebuild -project egunHoldings.xcodeproj -scheme egunHoldings -destination 'platform=iOS Simulator,name=iPhone 16' build
```

현재 로컬 환경은 `xcode-select`가 Command Line Tools를 가리키고 있어 터미널 빌드 확인은 Xcode 경로 설정 후 실행해야 합니다.
