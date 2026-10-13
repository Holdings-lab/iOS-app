# 웹 데모 디자인 QA

## 비교 대상

- 원본: `/private/tmp/egunholdings-simulator-current-today.png`, `/private/tmp/egunholdings-simulator-newsroom.png`, `/private/tmp/egunholdings-simulator-asset.png`
- 구현: `http://127.0.0.1:4173/`의 2026-09-24 브라우저 렌더링. 최종 캡처: `/private/tmp/egunholdings-web-final-today.png`, `/private/tmp/egunholdings-web-final-newsroom.png`, `/private/tmp/egunholdings-web-final-asset-adjusted.png`
- 화면 크기: iPhone 17 Pro 시뮬레이터 402×874 pt. 원본 PNG는 1206×2622 px (3×); 웹은 1400×1200 CSS px 브라우저의 402×874 CSS px 기기 프레임을 잘랐다 (1×). 원본을 402×874 px로 축소해 비교했다.
- 전체 비교: `/private/tmp/egunholdings-qa-final-today-sf.png`, `/private/tmp/egunholdings-qa-final-newsroom-sf.png`, `/private/tmp/egunholdings-qa-final-asset-adjusted.png`
- 집중 비교: `/private/tmp/egunholdings-qa-focused-today.png`, `/private/tmp/egunholdings-qa-focused-newsroom.png`, `/private/tmp/egunholdings-qa-focused-asset.png`
- 상태: 오늘은 시뮬레이터에 로그인된 같은 사용자의 저장값. 뉴스룸과 자산의 원본 화면은 iOS UI 테스트 Mock 사용자이며, 웹은 요청대로 현재 로그인 사용자 데이터를 표시한다. 이 두 화면은 값과 티커가 아니라 구성, 간격, 색, 타이포그래피를 비교했다.

## Findings

- P0/P1/P2: 남아 있지 않음. 오늘 화면의 배너, 브리핑, 보유 비중 카드 위치와 뉴스룸 첫 카드, 자산 총액 카드·목록 시작 위치가 원본에 근접한다.
- P3: 웹의 작은 본문 글씨가 iOS의 Pretendard보다 약간 조밀하다. 현재 폰트 스택은 Windows에서 Malgun Gothic으로 대체되므로 Windows 실기기의 줄바꿈은 달라질 수 있다.
- P3: 상태표시줄의 이동통신·Wi-Fi 표시는 웹에서 단순화했다. 앱 본문과 탭·버튼 아이콘은 SwiftUI와 같은 SF Symbols 원본 이미지를 사용한다.
- 의도한 데이터 차이: 뉴스룸과 자산의 Mock 스크린샷에 나오는 종목/금액은 웹에 표시하지 않는다. 웹은 현재 시뮬레이터 사용자 스냅샷만 사용한다.

## 필수 표면 확인

- 글꼴·계층: 제목, 카드 제목, 본문, 보조 텍스트의 크기·굵기·한 줄 말줄임을 비교했다. 작은 본문 밀도만 P3이다.
- 여백·레이아웃: 402×874 기준 카드 시작 위치, 카드 높이, 모서리, 하단 탭을 비교했다. 자산 총액 카드의 마지막 차이는 약 3 px였다.
- 색상: iOS의 배경 `#F4F6FB`, 파란 강조색 `#3461FD`, 자산 카드 그라데이션 `#254EDB`→`#527CFF`를 적용했다.
- 이미지·아이콘: 메인 화면에는 사진이 없다. SF Symbols는 macOS 시스템에서 투명 PNG로 내보내 웹에 사용했다. 뉴스 상세 이미지는 현재 서버 응답의 URL을 표시하며 원본 상세 스크린샷 비교는 없다.
- 문구·데이터: 오늘 화면의 배너·브리핑·보유 비중·목표는 시뮬레이터 화면과 같은 현재 사용자 상태를 확인했다. 뉴스룸·자산은 현재 사용자 데이터만 표시한다.

## 비교 이력

1. 초기 Today에서 카드 간 간격이 누적되어 뉴스 영역이 약 36 px 아래에 있었다. 헤더, 경고 배너, 보유 비중, 목표 카드 간격을 조정했고 `/private/tmp/egunholdings-qa-today-revised.png`로 다시 비교했다.
2. 초기 뉴스룸 첫 카드가 약 20 px 아래에 있었다. 상단 여백과 카드 높이를 조정했고 `/private/tmp/egunholdings-qa-newsroom-revised.png`로 다시 비교했다.
3. 자산 총액 카드가 약 9 px 높고 목록이 아래에 있었다. SwiftUI `AssetView`의 간격 수치에 맞춘 뒤 `/private/tmp/egunholdings-qa-final-asset-adjusted.png`로 다시 비교했다.
4. 임시 SVG 아이콘을 iOS에서 쓰는 SF Symbols PNG로 바꾸고 탭·상단 버튼 크기를 조정했다. 세 최종 비교 화면에서 확인했다.

## 동작 검증

- 오늘↔뉴스룸↔내 자산 탭, 뉴스룸 QQQ 상세 열기와 뒤로 가기, 설정 열기, API 실패 시 저장 데이터 유지를 브라우저에서 확인했다.
- 별도 로컬 모의 API에 성공 응답을 넣고 새로고침 후 오늘 브리핑, 보유 비중, 자산 총액이 API 값으로 바뀌는 것을 확인했다.
- 브라우저 콘솔 오류 없음. `file://` 직접 열기 시험은 브라우저 도구의 URL 보안 정책이 차단했다. 상대 경로로 묶인 정적 파일은 로컬 HTTP 미리보기에서 확인했다.
- Windows 실기기와 뉴스 상세의 iOS 원본 스크린샷은 이번 QA에 포함되지 않았다.

## Implementation Checklist

- [x] 메인 3개 탭의 레이아웃과 SF Symbols를 원본에 맞춤
- [x] 현재 사용자만 포함하는 정적 빌드 및 API 성공/실패 경로 확인
- [x] 브라우저 콘솔 오류 확인

final result: passed

## 2026-09-24 설정 화면 수정

- 원본: 현재 시뮬레이터의 `SettingsRootView`를 `-ui-testing-settings`로 실행해 `/private/tmp/egunholdings-ios-settings.png`에 캡처했다. 로그인된 사용자 ID 3의 설정 조회가 화면에 반영됐다.
- 웹: 같은 402×874 기기 프레임에서 설정 루트의 헤더, 프로필 카드, 알림·투자 설정·계정 그룹, SF Symbols, 각 행의 순서와 보조 문구를 비교했다. 상태 표시줄 아래 시작 위치와 카드 시작 위치를 원본에 맞춰 조정했다.
- 연결: 현재 시뮬레이터 세션을 로컬 서버 메모리로 전달한 뒤 실제 서버의 설정 GET, 동일값 알림 PATCH, 계좌 GET, 관심 분야 GET/동일값 PATCH, 오늘·보유종목·목표 진행·포트폴리오·뉴스룸 GET이 성공했다. `npm run test:live`는 모의 백엔드로 Windows용 서버의 로그인 교환, 만료 토큰 갱신, 설정 GET/PATCH, 계좌 GET을 검증했다.
- 제한: Codex 내장 브라우저는 `http://127.0.0.1:4173/api/...` 탐색을 `ERR_BLOCKED_BY_CLIENT`로 차단했고, 화면 안의 실시간 fetch도 실패했다. 정적 화면은 갱신된 시뮬레이터 설정 스냅샷으로 확인했다. 일반 Windows 브라우저의 라이브 화면은 아직 실기기에서 확인하지 못했다.
- 서버 계약 차이: 배포 서버의 `/api/interest-sectors`는 404여서 관심 분야 선택지는 백엔드 enum을 사용한다. 설정 GET에 목표 금액이 없어 앱과 같은 기본 5억원을 표시한다. 비밀번호 변경, 로그아웃, 회원 탈퇴, 증권사 연결·해제는 공유 데모에서 실행하지 않는다.
