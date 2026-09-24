import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { extname, resolve, sep } from "node:path";

const root = resolve(import.meta.dirname, "dist");
const host = process.env.HOST || "127.0.0.1";
const port = Number(process.env.PORT || 4173);
const types = { ".html": "text/html", ".css": "text/css", ".js": "text/javascript", ".json": "application/json" };
const livePaths = new Set(["/api/daily-briefing", "/api/holdings", "/api/goal-progress", "/api/portfolio", "/api/newsroom"]);

createServer(async (request, response) => {
  const url = new URL(request.url, `http://${request.headers.host || "localhost"}`);
  const isLivePath = livePaths.has(url.pathname) || /^\/api\/newsroom\/[A-Za-z0-9._-]+$/.test(url.pathname);
  if (url.pathname.startsWith("/api/") && isLivePath) {
    const token = process.env.DEMO_BEARER_TOKEN;
    if (!token || request.method !== "GET") {
      response.writeHead(token ? 405 : 503, { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" });
      response.end(JSON.stringify({ isSuccess: false, code: token ? "METHOD_NOT_ALLOWED" : "DEMO_TOKEN_MISSING", message: "실시간 API를 사용할 수 없어요." }));
      return;
    }
    try {
      const upstream = await fetch(new URL(url.pathname + url.search, process.env.DEMO_API_BASE_URL || "https://holdings-lab.me"), {
        headers: { Authorization: `Bearer ${token}` }, signal: AbortSignal.timeout(35000)
      });
      response.writeHead(upstream.status, { "content-type": upstream.headers.get("content-type") || "application/json", "cache-control": "no-store" });
      response.end(Buffer.from(await upstream.arrayBuffer()));
    } catch {
      response.writeHead(502, { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" });
      response.end(JSON.stringify({ isSuccess: false, code: "DEMO_UPSTREAM_FAILED", message: "서버 응답을 받지 못했어요." }));
    }
    return;
  }

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
