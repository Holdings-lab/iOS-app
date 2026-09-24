# egunHoldings 웹 데모

현재 iPhone 시뮬레이터에 로그인된 **한 사용자**의 저장 데이터를 사용해 오늘, 뉴스룸, 내 자산, 설정 화면을 클릭해 볼 수 있는 웹 데모입니다. Windows에서 오프라인으로 열 때는 Xcode, Node.js, 로그인이 필요하지 않습니다. 실시간 서버 데이터는 Windows의 Node.js 20 이상과 데모용 서버 계정 로그인이 필요합니다.

## 팀원에게 전달

`egunholdings-current-user-demo.zip`을 전달합니다. 압축을 풀고 `dist/index.html`을 더블클릭하면 저장 시점의 데모가 열립니다. 실시간 데이터가 필요하면 `dist` 폴더에서 `node server.mjs`를 실행하고 `http://127.0.0.1:4173/`을 연 뒤 **실시간 연결**을 눌러 서버 계정으로 로그인하세요. Mac과 Xcode는 필요하지 않습니다. ZIP에는 자산 평가액과 보유 종목 등 개인 데이터가 포함되므로 팀 내부에서만 공유하세요.

## Mac에서 스냅샷 갱신

1. 현재 사용자가 로그인된 시뮬레이터에서 이 브랜치의 Debug 앱을 한 번 실행합니다.
2. 아래 명령을 저장소 루트에서 실행합니다. `booted`는 해당 사용자의 시뮬레이터여야 합니다.

   ```sh
   xcrun simctl launch --terminate-running-process booted com.jiyong.com.egunHoldings -export-web-demo-snapshot
   mkdir -p web-demo/private
   cp "$(xcrun simctl get_app_container booted com.jiyong.com.egunHoldings data)/Documents/web-demo-snapshot.json" web-demo/private/snapshot.json
   chmod 600 web-demo/private/snapshot.json
   cd web-demo
   npm run build
   ditto -c -k --norsrc --keepParent dist egunholdings-current-user-demo.zip
   ```

3. 스냅샷을 내보낸 뒤 시뮬레이터 앱을 평소처럼 다시 실행합니다.

빌드는 사용자 스냅샷이 없거나 토큰, 이메일, 계좌 번호, 상품 코드 등 민감한 필드가 남아 있으면 실패합니다. `private/`, `dist/`, ZIP은 Git에 올라가지 않습니다. 저장소의 `mock-data.js`는 iOS Mock 데이터 대조용이며 배포 ZIP에는 포함되지 않습니다.

## API 연결

브라우저의 정적 파일만으로는 iOS Keychain의 세션을 읽을 수 없습니다. 배포 서버는 브라우저의 Bearer 인증 CORS 사전 요청에 401을 반환합니다. `server.mjs`는 로컬 컴퓨터에서만 실행되며, 서버 계정 로그인을 백엔드의 `POST /api/auth/login`에 전달하고 액세스·리프레시 토큰을 프로세스 메모리에만 보관합니다. 만료 시 한 번 갱신해 원래 요청을 재시도합니다. 브라우저·ZIP·디스크에는 토큰이나 비밀번호를 저장하지 않습니다. 오늘·뉴스룸·내 자산 GET, 설정·계좌 GET, 알림 PATCH, 목표 PATCH, 관심 분야 GET/PATCH는 같은 경로로 백엔드에 전달합니다. 세션이 없거나 갱신에 실패하면 저장된 데모 데이터를 유지합니다.

```sh
cd web-demo
npm start
```

기본 주소는 `http://127.0.0.1:4173`이며 로컬 컴퓨터에서만 접근할 수 있습니다. Mac의 현재 시뮬레이터 사용자 세션을 같은 서버에 연결하려면 `DEMO_BRIDGE_NONCE`를 서버 환경변수로 설정하고 Debug 앱을 `-web-demo-bridge-nonce` 인수와 함께 실행할 수 있습니다. 비밀번호 변경·계정 탈퇴·증권사 연결/해제는 공유 데모에서 실행되지 않습니다. 설정 목표 금액은 서버 설정 조회 응답에 금액이 없어 앱의 기본값을 표시하며, 웹에서 저장한 금액은 해당 브라우저 세션 동안 표시됩니다. 배포 서버의 `/api/interest-sectors`는 현재 404이므로 관심 분야 선택지는 백엔드 코드의 enum 목록을 사용합니다.
