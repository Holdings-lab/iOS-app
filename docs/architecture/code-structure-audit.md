# Code Structure Audit

검사 기준일: 2026-07-13  
대상 브랜치: `feat/final`

## 결론

프로젝트 최상위 구조는 `App`, `Common`, `DesignSystem`, `Features`로 구분되어 있고,
대부분의 기능은 `DTO`, `Models`, `Repositories`, `ViewModels`, `Views`로 나뉘어 있다.
기능 중심 MVVM 구조가 일관되게 적용되어 있다. View와 ViewModel의 직접 네트워크
참조를 제거했고, 큰 화면 파일은 역할별 컴포넌트로 분리했다. 새 기능은 아래 표준을
따르면 기존 구조를 별도 해석 없이 확장할 수 있다.

## 확인된 구조

### 네트워크 공통 계층

- `Common/Network/Core`: API 클라이언트, 응답 envelope, JSON 코딩, endpoint 기반 타입
- `Common/Network/Auth`: 인증 헤더, 토큰 저장소, 갱신 interceptor
- 기능별 `DTO`: 서버 전송 형식과 도메인 모델 변환
- 기능별 `Repositories`: endpoint 선택과 DTO 변환

이 방향은 적절하다. View와 ViewModel은 `APIClient`, `BackendEndpoint`, Moya,
Alamofire를 직접 알지 않고 Repository protocol만 의존해야 한다.

### 기능 경계

현재 큰 기능은 `Asset`, `Auth`, `Newsroom`, `Onboarding`, `Settings`, `Signal`,
`Today`로 구분되어 있다. 기능 간 공유 대상만 `Common`에 두는 원칙을 유지한다.

## 감사 결과

### 해결: Onboarding 네트워크 경계

`OnboardingFlowViewModel`은 `OnboardingRepositoryProtocol`만 주입받는다.
DTO 인코딩, `APIClient`, `BackendEndpoint` 사용은 `LiveOnboardingRepository`로
이동해 ViewModel을 전송 방식과 분리했다.

현재 구조:

```text
Onboarding/Views
    -> OnboardingFlowViewModel
        -> OnboardingRepositoryProtocol
            -> LiveOnboardingRepository
                -> APIClient + BackendEndpoint
```

### 개선: 대형 View 파일

다음 파일은 화면 조합, 상태 표현, 세부 컴포넌트가 함께 있어 추가 분리 여지가 있다.

- `Newsroom/Views/Components/PolicyNewsInsightSheet.swift`: 670줄

화면 진입점은 상태와 섹션 조합만 담당하고, 독립적인 섹션은
`Views/Components/<Subfeature>` 아래로 이동한다. 한 파일에 여러 독립 화면 상태나
여러 재사용 가능한 컴포넌트가 있으면 분리한다.

완료한 분리:

- `PolSignalSharedViews.swift`: 1,034줄에서 공용 컴포넌트 496줄로 축소
- `PolSignalDashboardViews.swift`: Today 브리핑·자산 스냅샷 539줄 분리
- `SignalView.swift`: 980줄에서 화면 진입점 445줄로 축소
- `SignalDetailViews.swift`: 상세 화면·조정 제안 sheet 537줄 분리
- `PolicyNewsInsightSheet.swift`: 993줄에서 상세 화면 본체 670줄로 축소
- `PolicyNewsInsightComponents.swift`: 상세 전용 컴포넌트 324줄 분리
- `AssetExposureOverviewSection.swift`: 709줄에서 개요 427줄로 축소
- `AssetExposureDetailView.swift`: 상세 화면·컴포넌트 283줄 분리
- `AssetRebalanceSection.swift`: 657줄에서 화면 본체 308줄로 축소
- `AssetRebalanceComponents.swift`: 재조정 카드·지표 350줄 분리
- `TodayView.swift`: 907줄에서 화면 조립·내비게이션 360줄로 축소
- `TodayDashboardSections.swift`: 대시보드 섹션 컴포넌트 549줄 분리

### 남은 비차단 개선점

- `Common/Network/Brokerage`에는 DTO, domain model, repository, cipher가 함께 있다.
  여러 기능에서 공유하는 통합 기능이라면 `Common/Brokerage/{Models,Repositories}`와
  `Common/Network`의 전송 구현을 분리하거나, 독립 `Features/Brokerage`로 승격한다.
- Factory가 항상 단일 구현을 반환하는 파일이 반복된다. 환경 선택 책임이 없다면
  composition root에서 구현을 주입하는 편이 탐색하기 쉽다.

### 주의: Mock fallback의 런타임 정책

일부 ViewModel/Repository factory가 실패 시 Mock을 사용하거나 기본 구현으로 Mock을
선택한다. 개발용 시나리오와 운영 fallback을 명시적으로 구분하지 않으면 실제 API
오류가 정상 데이터처럼 보일 수 있다. 앱 조립 지점에서 환경별 의존성을 선택하고,
운영 경로의 fallback은 별도 정책 타입으로 표현한다.

## 기능 내부 표준

```text
Features/<Feature>/
├── DTO/                 # 서버 요청/응답 타입과 매핑
├── Models/              # UI와 도메인이 사용하는 타입
├── Repositories/        # protocol, live/mock 구현
├── ViewModels/          # 화면 상태와 사용자 의도 처리
├── Views/               # 화면 진입점
└── Views/Components/    # 화면 전용 하위 뷰
```

규칙:

1. View는 ViewModel 상태 렌더링과 사용자 이벤트 전달만 담당한다.
2. ViewModel은 Repository protocol에만 의존한다.
3. Repository 구현만 API client, endpoint, DTO를 안다.
4. DTO는 View에서 직접 사용하지 않는다.
5. 공유 코드 이동은 실제로 둘 이상의 기능이 사용할 때만 한다.
6. 빈 폴더, 사용되지 않는 타입, 임시 중복 구현은 변경 단위마다 제거한다.

## 검증 기준선

- `git diff --check`: 통과
- iOS Simulator Debug build: 통과
- 빌드 명령:
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project egunHoldings.xcodeproj -scheme egunHoldings -configuration Debug -destination 'generic/platform=iOS Simulator' build`
