# egunHoldings 웹 데모

현재 iPhone 시뮬레이터에 로그인된 **한 사용자**의 저장 데이터를 사용해 오늘, 뉴스룸, 내 자산 화면을 클릭해 볼 수 있는 정적 웹 데모입니다. Windows에서는 Xcode, Node.js, 로그인 없이 배포 ZIP의 `dist/index.html`을 브라우저로 열면 됩니다. 뉴스 이미지와 기사 원문은 인터넷 연결이 있어야 표시됩니다.

## 팀원에게 전달

`egunholdings-current-user-demo.zip`을 전달합니다. 압축을 풀고 `dist/index.html`을 더블클릭하세요. 기본 화면에는 빌드할 때 내보낸 시뮬레이터 사용자의 데이터만 들어 있습니다. ZIP에는 자산 평가액과 보유 종목 등 개인 데이터가 포함되므로 팀 내부에서만 공유하세요.

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
   ditto -c -k --keepParent dist egunholdings-current-user-demo.zip
   ```

3. 스냅샷을 내보낸 뒤 시뮬레이터 앱을 평소처럼 다시 실행합니다.

빌드는 사용자 스냅샷이 없거나 토큰, 이메일, 계좌 번호, 상품 코드 등 민감한 필드가 남아 있으면 실패합니다. `private/`, `dist/`, ZIP은 Git에 올라가지 않습니다. 저장소의 `mock-data.js`는 iOS Mock 데이터 대조용이며 배포 ZIP에는 포함되지 않습니다.

## API 연결

브라우저의 정적 파일만으로는 iOS Keychain의 세션을 읽을 수 없습니다. 서버의 `/api/daily-briefing`, `/api/holdings`, `/api/goal-progress`, `/api/portfolio`, `/api/newsroom`, `/api/newsroom/{ticker}`는 Bearer 인증이 필요합니다. `server.mjs`는 로컬 테스트에서 `DEMO_BEARER_TOKEN`을 서버 환경변수로 받아 GET 요청을 같은 경로로 전달합니다. 토큰은 브라우저 파일이나 ZIP에 저장하지 않습니다. 토큰이 없거나 만료되면 저장된 데모 데이터를 유지합니다.

```sh
cd web-demo
DEMO_BEARER_TOKEN='인증된_임시_토큰' npm start
```

기본 주소는 `http://127.0.0.1:4173`이며 로컬 컴퓨터에서만 접근할 수 있습니다. 이 방식으로 실시간 값을 보려면 해당 컴퓨터에 유효한 토큰을 별도로 준비해야 합니다. 데모데이에 Mac과 토큰을 사용할 수 없다면 미리 만든 ZIP의 스냅샷을 사용하세요.
