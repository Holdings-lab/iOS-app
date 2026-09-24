import { readFile, writeFile, mkdir, copyFile, rm, readdir } from "node:fs/promises";
import { resolve } from "node:path";

const root = resolve(import.meta.dirname, "..");
const output = resolve(root, "dist");
const privateSnapshot = resolve(root, "private/snapshot.json");
const sensitiveKeys = new Set([
  "token", "accesstoken", "refreshtoken", "password", "email",
  "accountnumber", "accountproductcode", "productcode", "appkey", "appsecret",
  "credentials", "authorization"
]);

function checkSecrets(value, location = "snapshot") {
  if (Array.isArray(value)) return value.forEach((item, index) => checkSecrets(item, `${location}[${index}]`));
  if (value && typeof value === "object") {
    for (const [key, item] of Object.entries(value)) {
      if (sensitiveKeys.has(key.toLowerCase().replace(/[^a-z0-9]/g, ""))) {
        throw new Error(`Sensitive field in ${location}: ${key}`);
      }
      checkSecrets(item, `${location}.${key}`);
    }
  }
}

const snapshot = JSON.parse(await readFile(privateSnapshot, "utf8"));
checkSecrets(snapshot);
if (snapshot.schemaVersion !== 1 || snapshot.source !== "simulator-session" || !snapshot.user?.userId) {
  throw new Error("Invalid simulator snapshot");
}

await rm(output, { recursive: true, force: true });
await mkdir(output, { recursive: true });
for (const file of ["index.html", "styles.css", "app.js", "server.mjs"]) {
  await copyFile(resolve(root, file), resolve(output, file));
}
await mkdir(resolve(output, "assets"));
for (const file of await readdir(resolve(root, "assets"))) {
  await copyFile(resolve(root, "assets", file), resolve(output, "assets", file));
}

await writeFile(
  resolve(output, "snapshot.js"),
  `window.__EGUN_SNAPSHOT__ = ${JSON.stringify(snapshot)};\n`,
  "utf8"
);
await writeFile(resolve(output, "README-WINDOWS.txt"),
  `egunHoldings 데모\n\n오프라인: 압축을 풀고 index.html을 더블클릭하세요. 설치나 로그인이 필요하지 않습니다. 현재 시뮬레이터 사용자 ID ${snapshot.user.userId}의 ${snapshot.capturedAt} 시점 저장 데이터입니다.\n\n실시간: Windows에 Node.js 20 이상을 설치하고 이 폴더에서 명령 프롬프트를 열어 node server.mjs 를 실행하세요. 브라우저에서 http://127.0.0.1:4173/ 을 연 뒤 실시간 연결을 눌러 서버 계정으로 로그인하세요. 로그인 정보와 토큰은 파일에 저장되지 않고 서버 프로세스가 종료되면 사라집니다.\n\n뉴스 대표 이미지와 원문 링크는 인터넷 연결이 있을 때만 열립니다. 새 저장 데이터가 필요하면 Mac에서 현재 사용자 스냅샷을 다시 내보내어 재빌드하세요. 이 폴더에는 현재 사용자의 자산 데이터가 들어 있으므로 공개 웹에 게시하지 마세요.\n`, "utf8");
console.log(`Built current-user demo for user ${snapshot.user.userId}`);
