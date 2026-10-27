#!/usr/bin/env node
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// Uploads the App Store app preview (store/previews/iphone-6.9.mov, made by
// scripts/make-app-preview.swift) to the editable iOS version's en-US localisation, replacing any
// preview already there. 🚨 It never submits anything for review.
//
//   ASC_ISSUER_ID=… ASC_KEY_ID=… ASC_PRIVATE_KEY_PATH=… node scripts/asc-upload-preview.mjs

import { readFileSync, statSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { createHash, createSign } from "node:crypto";

const APP_ID = "6824033636";
const FILE = fileURLToPath(new URL("../store/previews/iphone-6.9.mov", import.meta.url));
const TYPE = "IPHONE_67"; // the 6.9-inch display group
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

const version = (await api(`/v1/apps/${APP_ID}/appStoreVersions?filter[platform]=IOS&filter[appStoreState]=PREPARE_FOR_SUBMISSION,DEVELOPER_REJECTED,REJECTED,METADATA_REJECTED`)).data[0];
if (!version) throw new Error("No editable iOS version: create the next one first (asc-prepare-version.mjs)");
const loc = (await api(`/v1/appStoreVersions/${version.id}/appStoreVersionLocalizations?limit=200`)).data.find((l) => l.attributes.locale === "en-US");
const sets = await api(`/v1/appStoreVersionLocalizations/${loc.id}/appPreviewSets`);
let set = sets.data.find((s) => s.attributes.previewType === TYPE);
if (set) {
  for (const p of (await api(`/v1/appPreviewSets/${set.id}/appPreviews`)).data) await api(`/v1/appPreviews/${p.id}`, "DELETE");
} else {
  set = (await api("/v1/appPreviewSets", "POST", { data: { type: "appPreviewSets", attributes: { previewType: TYPE },
    relationships: { appStoreVersionLocalization: { data: { type: "appStoreVersionLocalizations", id: loc.id } } } } })).data;
}
const bytes = readFileSync(FILE);
const reserved = (await api("/v1/appPreviews", "POST", { data: { type: "appPreviews",
  attributes: { fileName: "iphone-6.9.mov", fileSize: statSync(FILE).size, mimeType: "video/quicktime", previewFrameTimeCode: "00:00:05:00" },
  relationships: { appPreviewSet: { data: { type: "appPreviewSets", id: set.id } } } } })).data;
for (const op of reserved.attributes.uploadOperations) {
  const headers = Object.fromEntries(op.requestHeaders.map((h) => [h.name, h.value]));
  const r = await fetch(op.url, { method: op.method, headers, body: bytes.subarray(op.offset, op.offset + op.length) });
  if (!r.ok) throw new Error(`upload → ${r.status}`);
}
await api(`/v1/appPreviews/${reserved.id}`, "PATCH", { data: { type: "appPreviews", id: reserved.id,
  attributes: { uploaded: true, sourceFileChecksum: createHash("md5").update(bytes).digest("hex") } } });
console.log(`✓ preview uploaded to ${version.attributes.versionString} (${TYPE}); Apple processes it in a few minutes. Nothing was submitted.`);
