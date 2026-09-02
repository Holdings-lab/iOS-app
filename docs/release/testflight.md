# TestFlight 배포 준비

이 문서는 Apple Developer Program 계정이 발급되기 전부터 첫 TestFlight
빌드를 배포할 때까지의 체크리스트입니다. 자격 증명, 인증서, 프로비저닝
프로파일, App Store Connect API 키는 저장소에 추가하지 않습니다.

## 현재 프로젝트 기준

| 항목 | 현재 값 | 배포 전 결정/확인 |
| --- | --- | --- |
| iOS 타깃 | 26.0 | 테스트 기기가 iOS 26 이상인지 |
| Bundle ID | `com.jiyong.com.egunHoldings` | Apple Developer의 명시적 App ID로 등록 가능한지, 이후 변경 없이 유지할지 |
| 버전 / 빌드 | `1.0` / `1` | 첫 업로드는 `1.0.0 (1)` 권장. 다시 업로드할 때마다 빌드 번호를 올릴 것 |
| 서명 | Automatic, Team ID 설정됨 | 계정 수령 뒤 이 Team ID가 실제 등록 팀과 같은지 |
| 앱 아이콘 | 1024×1024 기본 아이콘 존재 | Archive Organizer의 App Store Connect 검증도 통과하는지 |
| 원격 알림 | 수신 토큰을 앱 메모리에만 보관 | 서버가 토큰 등록·발송을 구현하기 전에는 Push Notifications capability를 켜지 않음 |

`Bundle ID + 마케팅 버전 + 빌드 번호` 조합은 업로드된 빌드를 식별하며, 빌드를
올린 뒤 Bundle ID는 변경할 수 없습니다. 따라서 `com.jiyong.com.egunHoldings`를
새 계정의 App ID로 확정하기 전에는 바꾸지 마세요. [Apple의 앱 정보
참조](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/)

## 계정 없이 지금 확인할 것

1. 다음 명령을 실행합니다. 이 스크립트는 서명, Archive, 업로드, 계정 접근을 하지 않습니다.

   ```bash
   bash scripts/testflight_preflight.sh
   ```

   제한된 CI/샌드박스 환경에서 Xcode 캐시 접근이 막힌 경우에는 정적 검사만 실행할 수 있습니다.

   ```bash
   bash scripts/testflight_preflight.sh --static-only
   ```

2. 실제 Release 빌드에서 로그인, 온보딩, Today, 내 자산, 뉴스, 로그아웃을
   물리 기기에서 확인합니다. 이 앱에는 라이브 API와 목 데이터 폴백이 공존하므로,
   빌드 성공과 인증된 서버 동작을 별개로 기록합니다.

3. 이 문서 끝의 `What to Test`와 알려진 제한을 실제 동작에 맞게 업데이트합니다.
   외부 테스터에게 배포하려면 TestFlight에 Beta App Description, Feedback Email,
   Contact Information, What to Test를 입력해야 합니다.

## Apple 계정 수령 뒤의 단회 설정

1. Apple Developer Program 등록 완료 및 App Store Connect의 최신 계약 수락을 확인합니다.
2. Certificates, Identifiers & Profiles에서 이 프로젝트와 같은 Bundle ID의 명시적
   App ID를 등록합니다. 향후 실제 원격 푸시를 제공할 때만 Push Notifications
   capability도 함께 활성화합니다.
3. Xcode > Settings > Accounts에 해당 Apple Account를 추가하고, 프로젝트
   `Signing & Capabilities`에서 올바른 Team을 선택합니다. 자동 서명은 유지합니다.
4. App Store Connect에서 iOS App record를 만듭니다. 앱 이름, 기본 언어, 위 Bundle
   ID, 고유 SKU를 입력합니다. 앱 레코드는 빌드 업로드 전에 필요합니다. [Apple의
   앱 레코드 생성 안내](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/)
5. App Store Connect에서 TestFlight용 Beta App Description, Feedback Email,
   Contact Information을 입력합니다. 외부 테스터를 쓸 계획이라면 내부 그룹을 먼저
   하나 만듭니다.

## 첫 빌드 업로드

1. `egunHoldings` 스킴, `Any iOS Device (arm64)`, `Release`를 선택합니다.
2. Build Settings의 `MARKETING_VERSION`을 `1.0.0`,
   `CURRENT_PROJECT_VERSION`을 `1`로 정리합니다. 같은 버전을 다시 올릴 때는
   두 번째 값을 반드시 증가시킵니다.
3. Product > Archive를 실행합니다. Organizer에서 Validate App을 먼저 실행한 뒤,
   Distribute App > App Store Connect > Upload를 선택합니다.
4. 처리 완료 후 TestFlight에서 내부 테스터 그룹에 `1.0.0 (1)`을 배정합니다.
   내부 테스터는 최대 100명이며, 외부 테스터는 최대 10,000명입니다. 외부 배포는
   첫 TestFlight 검토가 필요할 수 있습니다. [Apple TestFlight 개요](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/)
5. 외부 테스터를 초대할 때는 이메일 또는 공개 링크를 사용합니다. 공개 링크는
   전달될 수 있으므로 기기/OS 조건과 인원 제한을 설정합니다. [Apple의 외부
   테스터 안내](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers)

TestFlight 빌드는 최대 90일 동안 테스트할 수 있습니다. 내보낸 `.ipa`,
`.xcarchive`, 인증서, provisioning profile은 저장소에 커밋하지 않습니다.

## 첫 TestFlight용 입력 초안

아래 대괄호 항목을 실제 정보로 교체한 뒤 TestFlight에 붙여 넣습니다.

### Beta App Description

정책 뉴스와 보유 자산의 연결을 보여 주는 iOS 베타 앱입니다. 이메일 로그인과
온보딩을 거쳐 오늘의 정책 브리핑, 자산 노출도, 맞춤 뉴스 흐름을 확인할 수 있습니다.

### What to Test — 1.0.0 (1)

- 이메일 회원가입, 인증, 로그인과 로그아웃 흐름
- 관심 섹터·투자 성향·증권사 연결 여부를 묻는 온보딩
- Today의 정책 브리핑과 자산 요약
- 내 자산의 보유 종목·노출도·리밸런싱 화면
- 뉴스 목록, 원문 열기, 읽음/숨김 상태
- 로컬 알림 권한과 테스트 알림 표시

### Known Limitations

- 소셜 로그인은 현재 연동 전 분기만 있습니다.
- 일부 자산·맞춤 뉴스·리밸런싱 결과는 목 데이터 폴백을 사용할 수 있습니다.
- 증권사 잔고조회는 연결된 계정과 서버 환경에 따라 사용할 수 없습니다.
- 원격 푸시 알림은 서버 토큰 등록·발송이 구현되기 전까지 제공하지 않습니다.

### Contact Information

- Feedback Email: `[배포 담당 이메일]`
- Contact Name: `[배포 담당자 이름]`
- Contact Phone: `[국가 코드 포함 전화번호]`
