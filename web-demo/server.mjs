import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { extname, resolve, sep } from "node:path";

const root = existsSync(resolve(import.meta.dirname, "snapshot.js"))
  ? import.meta.dirname : resolve(import.meta.dirname, "dist");
const host = "127.0.0.1";
const port = Number(process.env.PORT || 4173);
const types = { ".html": "text/html", ".css": "text/css", ".js": "text/javascript", ".json": "application/json" };
const livePaths = new Set(["/api/daily-briefing", "/api/holdings", "/api/goal-progress", "/api/portfolio", "/api/newsroom"]);
const settingsPaths = new Map([
  ["GET /api/me/settings", true],
  ["GET /api/accounts", true],
  ["PATCH /api/me/settings/notifications", true],
  ["POST /api/me/notifications/test", true],
  ["GET /api/me/settings/interests", true],
  ["GET /api/interest-sectors", true],
  ["PATCH /api/me/settings/interests", true],
  ["PATCH /api/goal", true]
]);
let simulatorToken = null;
let simulatorUserId = null;
let activeRefreshToken = null;
let refreshInFlight = null;

async function refreshAccessToken() {
  if (!activeRefreshToken) return false;
  if (!refreshInFlight) {
    refreshInFlight = (async () => {
      try {
        const upstream = await fetch(new URL("/api/auth/refresh", process.env.DEMO_API_BASE_URL || "https://holdings-lab.me"), {
          method: "POST", headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ refreshToken: activeRefreshToken }), signal: AbortSignal.timeout(15000)
        });
        const payload = await upstream.json();
        const next = payload.result || payload;
        if (!upstream.ok || !next.accessToken) throw new Error("Refresh failed");
        simulatorToken = next.accessToken;
        activeRefreshToken = next.refreshToken || activeRefreshToken;
        return true;
      } catch {
        simulatorToken = null; simulatorUserId = null; activeRefreshToken = null;
        return false;
      }
    })().finally(() => { refreshInFlight = null; });
  }
  return refreshInFlight;
}

function json(response, status, body) {
  response.writeHead(status, { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" });
  response.end(JSON.stringify(body));
}

async function readJSON(request) {
  let raw = "";
  for await (const chunk of request) {
    raw += chunk;
    if (raw.length > 8192) throw new Error("Request too large");
  }
  return JSON.parse(raw);
}

createServer(async (request, response) => {
  if (![`${host}:${port}`, `localhost:${port}`].includes(request.headers.host)) {
    json(response, 403, { code: "INVALID_HOST" }); return;
  }
  const url = new URL(request.url, `http://${request.headers.host || "localhost"}`);
  if (request.method !== "GET" && request.headers.origin && request.headers.origin !== `http://${request.headers.host}`) {
    json(response, 403, { code: "INVALID_ORIGIN" }); return;
  }
  if (url.pathname === "/api/demo-login" && request.method === "POST") {
    const origin = request.headers.origin;
    if (origin && origin !== `http://${request.headers.host}`) { json(response, 403, { message: "잘못된 요청입니다." }); return; }
    try {
      const credentials = await readJSON(request);
      if (typeof credentials.email !== "string" || typeof credentials.password !== "string") throw new Error("Invalid credentials");
      const upstream = await fetch(new URL("/api/auth/login", process.env.DEMO_API_BASE_URL || "https://holdings-lab.me"), {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: credentials.email, password: credentials.password }),
        signal: AbortSignal.timeout(15000)
      });
      const payload = await upstream.json();
      const login = payload.result || payload;
      if (!upstream.ok || !login.accessToken || !login.userId) {
        json(response, 401, { message: payload.message || "로그인 정보를 확인해 주세요." }); return;
      }
      simulatorToken = login.accessToken;
      simulatorUserId = String(login.userId);
      activeRefreshToken = typeof login.refreshToken === "string" ? login.refreshToken : null;
      json(response, 200, { connected: true, userId: simulatorUserId });
    } catch { json(response, 502, { message: "로그인 서버에 연결하지 못했어요." }); }
    return;
  }
  if (url.pathname === "/api/demo-disconnect" && request.method === "POST") {
    simulatorToken = null; simulatorUserId = null; activeRefreshToken = null;
    json(response, 200, { connected: false }); return;
  }
  if (url.pathname === "/internal/simulator-session" && request.method === "POST") {
    if (!process.env.DEMO_BRIDGE_NONCE || request.headers["x-demo-bridge-nonce"] !== process.env.DEMO_BRIDGE_NONCE) {
      json(response, 403, { code: "BRIDGE_DENIED" }); return;
    }
    try {
      const body = await readJSON(request);
      if (typeof body.token !== "string" || !body.token || !/^\d+$/.test(body.userId)) throw new Error("Invalid session");
      simulatorToken = body.token;
      simulatorUserId = body.userId;
      activeRefreshToken = null;
      json(response, 200, { connected: true });
    } catch { json(response, 400, { code: "INVALID_SESSION" }); }
    return;
  }
  if (url.pathname === "/api/demo-status") {
    json(response, 200, { connected: Boolean(simulatorToken || process.env.DEMO_BEARER_TOKEN), userId: simulatorUserId }); return;
  }
  const isLivePath = (request.method === "GET" && (livePaths.has(url.pathname) || /^\/api\/newsroom\/[A-Za-z0-9._-]+$/.test(url.pathname)))
    || settingsPaths.has(`${request.method} ${url.pathname}`);
  if (url.pathname.startsWith("/api/") && isLivePath) {
    const token = simulatorToken || process.env.DEMO_BEARER_TOKEN;
    if (!token) {
      json(response, 503, { isSuccess: false, code: "DEMO_TOKEN_MISSING", message: "실시간 API를 사용할 수 없어요." });
      return;
    }
    try {
      let body;
      if (request.method === "PATCH") {
        body = "";
        for await (const chunk of request) {
          body += chunk;
          if (body.length > 16384) throw new Error("Request too large");
        }
        JSON.parse(body);
      }
      const destination = new URL(url.pathname + url.search, process.env.DEMO_API_BASE_URL || "https://holdings-lab.me");
      const forward = bearer => fetch(destination, {
        method: request.method,
        headers: { Authorization: `Bearer ${bearer}`, ...(body ? { "Content-Type": "application/json" } : {}) },
        body, signal: AbortSignal.timeout(35000)
      });
      let upstream = await forward(token);
      if (upstream.status === 401) {
        if (simulatorToken && token !== simulatorToken) upstream = await forward(simulatorToken);
        else if (await refreshAccessToken()) upstream = await forward(simulatorToken);
      }
      response.writeHead(upstream.status, { "content-type": upstream.headers.get("content-type") || "application/json", "cache-control": "no-store" });
      response.end(Buffer.from(await upstream.arrayBuffer()));
    } catch {
      response.writeHead(502, { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" });
      response.end(JSON.stringify({ isSuccess: false, code: "DEMO_UPSTREAM_FAILED", message: "서버 응답을 받지 못했어요." }));
    }
    return;
  }
  if (url.pathname.startsWith("/api/")) { json(response, 404, { code: "DEMO_ROUTE_NOT_FOUND" }); return; }

  const path = resolve(root, `.${decodeURIComponent(url.pathname === "/" ? "/index.html" : url.pathname)}`);
  if (path !== root && !path.startsWith(root + sep)) {
    response.writeHead(403); response.end(); return;
  }
  try {
    const data = await readFile(path);
    response.writeHead(200, { "content-type": `${types[extname(path)] || "application/octet-stream"}; charset=utf-8`, "cache-control": "no-store" });
    response.end(data);
  } catch {
    response.writeHead(404); response.end("Not found");
  }
}).listen(port, host, () => console.log(`Demo preview: http://${host}:${port}`));
