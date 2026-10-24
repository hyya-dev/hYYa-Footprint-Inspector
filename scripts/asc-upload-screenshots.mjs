#!/usr/bin/env node
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// Replaces the en-US screenshots of the editable iOS version with the slides in store/slides/.
// 🚨 Uploading screenshots is not a review submission, and this script never submits.
//
//   ASC_ISSUER_ID=… ASC_KEY_ID=… ASC_PRIVATE_KEY_PATH=… node scripts/asc-upload-screenshots.mjs [iphone|ipad]

import { readFileSync, readdirSync, statSync } from "node:fs";
import { createHash, createSign } from "node:crypto";
import { join } from "node:path";

const APP_ID = "6824033636";
// IOS (default) or MAC_OS: which platform's editable version to fill.
const PLATFORM = process.env.PLATFORM ?? "IOS";
const SETS = (process.env.PLATFORM ?? "IOS") === "MAC_OS" ? {
  mac: { dir: "store/slides/mac", type: "APP_DESKTOP" },
} : {
  iphone: { dir: "store/slides/iphone-6.9", type: "APP_IPHONE_67" },
  ipad: { dir: "store/slides/ipad-13", type: "APP_IPAD_PRO_3GEN_129" },
  // iPhone Duo: one set for both screens (1398×2034 folded, 2007×2853 open). The value isn't in
  // Apple's published API reference yet; uploads to it were confirmed working by other tools.
  duo: { dir: "store/slides/duo", type: "APP_IPHONE_DUO" },
};
const only = process.argv[2];
const { ASC_ISSUER_ID, ASC_KEY_ID, ASC_PRIVATE_KEY_PATH } = process.env;
const key = readFileSync(ASC_PRIVATE_KEY_PATH, "utf8");

const token = () => {
  const b = (o) => Buffer.from(JSON.stringify(o)).toString("base64url");
  const n = Math.floor(Date.now() / 1000);
  const h = b({ alg: "ES256", kid: ASC_KEY_ID, typ: "JWT" });
  const p = b({ iss: ASC_ISSUER_ID, iat: n, exp: n + 900, aud: "appstoreconnect-v1" });
  return `${h}.${p}.${createSign("SHA256").update(`${h}.${p}`).sign({ key, dsaEncoding: "ieee-p1363" }).toString("base64url")}`;
};
async function api(path, method = "GET", body) {
  const r = await fetch(`https://api.appstoreconnect.apple.com${path}`, {
    method, headers: { Authorization: `Bearer ${token()}`, "Content-Type": "application/json" },
    body: body ? JSON.stringify(body) : undefined,
  });
  const t = await r.text();
  if (!r.ok) throw new Error(`${method} ${path} → ${r.status}\n${t}`);
  return t ? JSON.parse(t) : null;
}

const versions = await api(`/v1/apps/${APP_ID}/appStoreVersions?filter[platform]=${PLATFORM}&filter[appStoreState]=PREPARE_FOR_SUBMISSION,DEVELOPER_REJECTED,REJECTED,METADATA_REJECTED`);
const version = versions.data[0];
const locs = await api(`/v1/appStoreVersions/${version.id}/appStoreVersionLocalizations`);
const loc = locs.data.find((l) => l.attributes.locale === "en-US");

for (const [name, set] of Object.entries(SETS)) {
  if (only && only !== name) continue;
  let files;
  try { files = readdirSync(set.dir).filter((f) => f.endsWith(".png")).sort(); } catch { console.log(`skip ${name}: no ${set.dir}`); continue; }
  if (!files.length) { console.log(`skip ${name}: empty`); continue; }

  const sets = await api(`/v1/appStoreVersionLocalizations/${loc.id}/appScreenshotSets?limit=50`);
  let target = sets.data.find((s) => s.attributes.screenshotDisplayType === set.type);
  if (target) {
    const existing = await api(`/v1/appScreenshotSets/${target.id}/appScreenshots?limit=50`);
    for (const s of existing.data) await api(`/v1/appScreenshots/${s.id}`, "DELETE");
  } else {
    target = (await api("/v1/appScreenshotSets", "POST", { data: { type: "appScreenshotSets",
      attributes: { screenshotDisplayType: set.type },
      relationships: { appStoreVersionLocalization: { data: { type: "appStoreVersionLocalizations", id: loc.id } } } } })).data;
  }

  for (const f of files) {
    const path = join(set.dir, f);
    const bytes = readFileSync(path);
    const reserved = (await api("/v1/appScreenshots", "POST", { data: { type: "appScreenshots",
      attributes: { fileName: f, fileSize: statSync(path).size },
      relationships: { appScreenshotSet: { data: { type: "appScreenshotSets", id: target.id } } } } })).data;
    for (const op of reserved.attributes.uploadOperations) {
      const chunk = bytes.subarray(op.offset, op.offset + op.length);
      const headers = Object.fromEntries(op.requestHeaders.map((h) => [h.name, h.value]));
      const r = await fetch(op.url, { method: op.method, headers, body: chunk });
      if (!r.ok) throw new Error(`upload ${f} → ${r.status}`);
    }
    const md5 = createHash("md5").update(bytes).digest("hex");
    await api(`/v1/appScreenshots/${reserved.id}`, "PATCH", { data: { type: "appScreenshots", id: reserved.id,
      attributes: { uploaded: true, sourceFileChecksum: md5 } } });
    console.log(`  ${name}: ${f}`);
  }
  console.log(`✓ ${name}: ${files.length} slides → ${set.type}`);
}
console.log("Nothing was submitted.");
