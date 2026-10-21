/**
 * Shared Google Play Developer API plumbing. No dependencies, same approach as the `asc-*.mjs`
 * scripts: hand-rolled RS256 JWT with `node:crypto`, because this repo has no `node_modules` and
 * a store script that needs `npm install` first is a store script that stops working.
 *
 * Auth is a service account — `the Play service account`, granted per-app access in Play Console under
 * Users and permissions. ⚠️ **A service account is granted access in the CONSOLE, not in Google
 * Cloud.** Creating the key is necessary and not sufficient; if a call 401s with
 * "The current user has insufficient permissions", the grant is what is missing.
 *
 * 🚨 **An "edit" is a transaction.** Nothing you change is live until `edits.commit`, and an edit
 * left uncommitted simply expires. That is the safety property these scripts lean on: a dry run
 * can do the whole sequence and then NOT commit, and the store is untouched.
 */
import { readFileSync } from "node:fs";
import crypto from "node:crypto";

export const PACKAGE = "com.hyya.footprintinspector";
const SCOPE = "https://www.googleapis.com/auth/androidpublisher";
const BASE = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE}`;

const b64u = (b) => Buffer.from(b).toString("base64url");

export async function accessToken(keyPath = process.env.PLAY_SERVICE_ACCOUNT_JSON) {
  if (!keyPath) throw new Error("Set PLAY_SERVICE_ACCOUNT_JSON to the service-account JSON path");
  const sa = JSON.parse(readFileSync(keyPath, "utf8"));
  const now = Math.floor(Date.now() / 1000);
  const head = b64u(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const body = b64u(JSON.stringify({
    iss: sa.client_email, scope: SCOPE,
    aud: "https://oauth2.googleapis.com/token", iat: now, exp: now + 3600,
  }));
  const sig = crypto.sign("RSA-SHA256", Buffer.from(`${head}.${body}`), sa.private_key)
    .toString("base64url");
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${head}.${body}.${sig}`,
    }),
  });
  const json = await res.json();
  if (!res.ok) throw new Error(`token ${res.status}: ${JSON.stringify(json)}`);
  return { token: json.access_token, account: sa.client_email };
}

/** Every call goes through here so an error is a readable sentence, not an unhandled rejection. */
export async function api(token, path, { method = "GET", body, raw, contentType } = {}) {
  const url = path.startsWith("http") ? path : `${BASE}${path}`;
  const headers = { Authorization: `Bearer ${token}` };
  if (body) headers["content-type"] = "application/json";
  if (contentType) headers["content-type"] = contentType;
  const res = await fetch(url, {
    method, headers, body: raw ?? (body ? JSON.stringify(body) : undefined),
  });
  const text = await res.text();
  let json; try { json = text ? JSON.parse(text) : {}; } catch { json = { raw: text }; }
  if (!res.ok) {
    const msg = json?.error?.message ?? text.slice(0, 300);
    throw new Error(`${method} ${url.replace(BASE, "")} → ${res.status}: ${msg}`);
  }
  return json;
}

// ── store graphics ──────────────────────────────────────────────────────────────────────────────
const UPLOAD_BASE = `https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/${PACKAGE}`;

/**
 * Replaces every image set named in [files] (`{ imageType: [path, …] }`) in every language of
 * [langs], inside the edit at [E] (`/edits/<id>`), several sets at once.
 *
 * ⚠️ Why it is shaped like this (2026-10-13): one set after another took about two minutes a
 * language — some twenty minutes a production send, twice with the rehearsal — and the owner took
 * the wait for a hang. The sets are independent, so they run side by side (`concurrency` at a
 * time). ⛔ But the images WITHIN a set go one after another: Play orders a gallery by upload order,
 * and parallel uploads inside a set would shuffle the slides. Every set is then read back and its
 * order checked against [files] by sha256 (`verifyGraphics`) — fail closed, before any commit.
 * Each set is DELETED first, so a re-run replaces it instead of appending a second copy.
 * A 429 or 5xx is retried with backoff (1, 2, 4, 8 s); anything else stops the run.
 */
export async function pushGraphics(token, E, langs, files, { concurrency = 6, log = console.log } = {}) {
  const jobs = langs.flatMap((lang) => Object.entries(files).map(([type, paths]) => ({ lang, type, paths })));
  const left = Object.fromEntries(langs.map((l) => [l, Object.keys(files).length]));
  const retrying = async (fn) => {
    for (let wait = 1000; ; wait *= 2) {
      try { return await fn(); } catch (e) {
        if (wait > 8000 || !/→ (429|5\d\d):/.test(String(e.message))) throw e;
        await new Promise((r) => setTimeout(r, wait));
      }
    }
  };
  let next = 0;
  const worker = async () => {
    while (next < jobs.length) {
      const { lang, type, paths } = jobs[next++];
      await retrying(() => api(token, `${E}/listings/${lang}/${type}`, { method: "DELETE" })).catch(() => {});
      for (const p of paths)
        await retrying(() => api(token, `${UPLOAD_BASE}${E}/listings/${lang}/${type}?uploadType=media`,
                                 { method: "POST", raw: readFileSync(p), contentType: "image/png" }));
      if (--left[lang] === 0) log(`  graphics: ${lang} done`);
    }
  };
  await Promise.all(Array.from({ length: Math.min(concurrency, jobs.length) }, worker));
  await verifyGraphics(token, E, langs, files);
}

/** Reads every set back and fails unless it holds exactly [files]' images, in [files]' order. */
export async function verifyGraphics(token, E, langs, files) {
  const sha = (p) => crypto.createHash("sha256").update(readFileSync(p)).digest("hex");
  const want = Object.fromEntries(Object.entries(files).map(([t, ps]) => [t, ps.map(sha)]));
  for (const lang of langs) for (const [type, hashes] of Object.entries(want)) {
    const got = ((await api(token, `${E}/listings/${lang}/${type}`)).images ?? []).map((i) => i.sha256);
    if (got.length !== hashes.length || got.some((h, i) => h !== hashes[i]))
      throw new Error(`${lang} ${type}: Play holds ${got.length} image(s) not matching the ${hashes.length} expected, in order — nothing committed`);
  }
}
