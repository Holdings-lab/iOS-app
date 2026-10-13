import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { createServer } from "node:http";
import { once } from "node:events";
import { resolve } from "node:path";

let refreshCount = 0;
const mock = createServer(async (request, response) => {
  response.setHeader("Content-Type", "application/json");
  if (request.url === "/api/auth/login") {
    const chunks = [];
    for await (const chunk of request) chunks.push(chunk);
    const body = JSON.parse(Buffer.concat(chunks).toString());
    assert.deepEqual(body, { email: "demo@example.com", password: "demo-pass" });
    response.end(JSON.stringify({ isSuccess: true, result: { accessToken: "stale-token", refreshToken: "refresh-token", userId: 3 } }));
    return;
  }
  if (request.url === "/api/auth/refresh") {
    refreshCount++;
    const chunks = [];
    for await (const chunk of request) chunks.push(chunk);
    assert.deepEqual(JSON.parse(Buffer.concat(chunks).toString()), { refreshToken: "refresh-token" });
    response.end(JSON.stringify({ isSuccess: true, result: { accessToken: "new-token", refreshToken: "next-refresh-token" } }));
    return;
  }
  if (request.headers.authorization === "Bearer stale-token") {
    response.statusCode = 401;
    response.end(JSON.stringify({ isSuccess: false, message: "Expired" }));
    return;
  }
  assert.equal(request.headers.authorization, "Bearer new-token");
  if (request.url === "/api/me/settings" && request.method === "GET") {
    response.end(JSON.stringify({ isSuccess: true, result: { notifications: { policyChangeAlert: true, briefingTime: "09:00" } } }));
  } else if (request.url === "/api/me/settings/notifications" && request.method === "PATCH") {
    response.end(JSON.stringify({ isSuccess: true, result: { policyChangeAlert: false, briefingTime: "09:00" } }));
  } else if (request.url === "/api/accounts" && request.method === "GET") {
    response.end(JSON.stringify({ isSuccess: true, result: [] }));
  } else {
    response.statusCode = 404;
    response.end(JSON.stringify({ isSuccess: false }));
  }
});

mock.listen(0, "127.0.0.1");
await once(mock, "listening");
const previewPort = 4175;
const preview = spawn(process.execPath, [resolve(import.meta.dirname, "../dist/server.mjs")], {
  env: { ...process.env, PORT: String(previewPort), DEMO_API_BASE_URL: `http://127.0.0.1:${mock.address().port}` },
  stdio: "ignore"
});

try {
  const base = `http://127.0.0.1:${previewPort}`;
  let ready = false;
  for (let attempt = 0; attempt < 40; attempt++) {
    try { ready = (await fetch(`${base}/api/demo-status`)).ok; } catch { /* starting */ }
    if (ready) break;
    await new Promise(resolve => setTimeout(resolve, 50));
  }
  assert.equal(ready, true, "preview server did not start");
  const login = await fetch(`${base}/api/demo-login`, {
    method: "POST", headers: { "Content-Type": "application/json", Origin: base },
    body: JSON.stringify({ email: "demo@example.com", password: "demo-pass" })
  });
  const loginBody = await login.json();
  assert.equal(login.status, 200);
  assert.equal(loginBody.connected, true);
  assert.equal(JSON.stringify(loginBody).includes("stale-token"), false);
  const crossOrigin = await fetch(`${base}/api/demo-disconnect`, { method: "POST", headers: { Origin: "https://other.example" } });
  assert.equal(crossOrigin.status, 403);
  const [settingsResponse, accountsResponse] = await Promise.all([
    fetch(`${base}/api/me/settings`), fetch(`${base}/api/accounts`)
  ]);
  const settings = await settingsResponse.json();
  assert.equal(settings.result.notifications.policyChangeAlert, true);
  const accounts = await accountsResponse.json();
  assert.deepEqual(accounts.result, []);
  const patch = await fetch(`${base}/api/me/settings/notifications`, {
    method: "PATCH", headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ policyChangeAlert: false })
  });
  assert.equal((await patch.json()).result.policyChangeAlert, false);
  assert.equal(refreshCount, 1);
  console.log("Local login, token refresh, GET, PATCH, account proxy: passed");
} finally {
  preview.kill();
  mock.close();
}
