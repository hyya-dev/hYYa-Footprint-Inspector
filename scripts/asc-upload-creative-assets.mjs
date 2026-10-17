#!/usr/bin/env node
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// Uploads the product page header and search results images (store/creative/) to the app's Asset
// Library, then places them on every localisation of the editable iOS version, replacing any
// existing header or search results placement. Artwork is English everywhere, like the slides.
// 🚨 Placing assets is not a review submission, and this script never submits.
//
//   ASC_ISSUER_ID=… ASC_KEY_ID=… ASC_PRIVATE_KEY_PATH=… node scripts/asc-upload-creative-assets.mjs [--apply] [locale …]
//
// API flow: POST appAssetLibraryImages (category CREATIVE_ASSETS) → PUT the upload parts → PATCH
// uploaded → wait for processing → POST appAssetLibraryPlacements per localisation.

import { readFileSync } from "node:fs";
import { createSign } from "node:crypto";
import { basename } from "node:path";

const APP_ID = "6824033636";
const FILES = {
  PRODUCT_PAGE_HEADER_ASSET: "store/creative/header-3840x1646.png",
  APP_STORE_SEARCH_RESULTS_ASSET: "store/creative/search-results-3840x2560.png",
};
const argv = process.argv.slice(2);
const APPLY = argv.includes("--apply");
const ONLY = argv.filter((a) => !a.startsWith("--"));
const { ASC_ISSUER_ID, ASC_KEY_ID, ASC_PRIVATE_KEY_PATH } = process.env;
for (const [k, v] of Object.entries({ ASC_ISSUER_ID, ASC_KEY_ID, ASC_PRIVATE_KEY_PATH }))
  if (!v) { console.error(`Missing env ${k}`); process.exit(1); }
const key = readFileSync(ASC_PRIVATE_KEY_PATH, "utf8");

const token = () => {
  const b = (o) => Buffer.from(JSON.stringify(o)).toString("base64url");
  const n = Math.floor(Date.now() / 1000);
  const h = b({ alg: "ES256", kid: ASC_KEY_ID, typ: "JWT" });
  const p = b({ iss: ASC_ISSUER_ID, iat: n, exp: n + 900, aud: "appstoreconnect-v1" });
  return `${h}.${p}.${createSign("SHA256").update(`${h}.${p}`).sign({ key, dsaEncoding: "ieee-p1363" }).toString("base64url")}`;
};
async function api(path, method = "GET", body) {
  for (let attempt = 1; attempt <= 5; attempt++) {
    const r = await fetch(`https://api.appstoreconnect.apple.com/v1${path}`, {
      method, headers: { Authorization: `Bearer ${token()}`, "Content-Type": "application/json" },
      body: body ? JSON.stringify(body) : undefined,
    });
    const t = await r.text();
    if (r.ok) return t ? JSON.parse(t) : null;
    if (attempt === 5 || (r.status < 500 && r.status !== 429)) throw new Error(`${method} ${path} → ${r.status}\n${t.slice(0, 600)}`);
    await new Promise((res) => setTimeout(res, 2000 * attempt));
  }
}
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function upload(file) {
  const bytes = readFileSync(file);
  const img = (await api("/appAssetLibraryImages", "POST", { data: { type: "appAssetLibraryImages",
    attributes: { category: "CREATIVE_ASSETS", fileName: basename(file), fileSize: bytes.length },
    relationships: { assetLibrary: { data: { type: "appAssetLibraries", id: APP_ID } } } } })).data;
  for (const op of img.attributes.uploadOperations ?? []) {
    const r = await fetch(op.url, { method: op.method, body: bytes.subarray(op.offset, op.offset + op.length),
      headers: Object.fromEntries((op.requestHeaders ?? []).map((h) => [h.name, h.value])) });
    if (!r.ok) throw new Error(`upload ${file} → ${r.status}`);
  }
  await api(`/appAssetLibraryImages/${img.id}`, "PATCH", { data: { type: "appAssetLibraryImages", id: img.id, attributes: { uploaded: true } } });
  for (let i = 0; i < 80; i++) {
    const s = (await api(`/appAssetLibraryImages/${img.id}`)).data.attributes;
    if (/FAIL/.test(s.state)) throw new Error(`${file}: ${s.state} ${JSON.stringify(s.stateDetails ?? "")}`);
    if (!["AWAITING_UPLOAD", "PROCESSING", "UPLOAD_COMPLETE"].includes(s.state)) { console.log(`  ${basename(file)}: ${s.state}`); return img.id; }
    await sleep(3000);
  }
  throw new Error(`${file}: still processing`);
}

const version = (await api(`/apps/${APP_ID}/appStoreVersions?filter[platform]=IOS&filter[appStoreState]=PREPARE_FOR_SUBMISSION,DEVELOPER_REJECTED,REJECTED,METADATA_REJECTED`)).data[0];
if (!version) throw new Error("No editable iOS version");
const locs = (await api(`/appStoreVersions/${version.id}/appStoreVersionLocalizations?limit=200`)).data
  .filter((l) => !ONLY.length || ONLY.includes(l.attributes.locale));

if (!APPLY) {
  console.log(`Dry run: would place header and search results on ${locs.length} localisations. Add --apply.`);
  process.exit(0);
}

const ids = {};
for (const [type, file] of Object.entries(FILES)) ids[type] = await upload(file);

let done = 0;
for (const l of locs) {
  const locale = l.attributes.locale;
  try {
    const existing = (await api(`/appStoreVersionLocalizations/${l.id}/placements?limit=200`)).data
      .filter((p) => p.attributes.placementType in FILES);
    for (const p of existing) await api(`/appAssetLibraryPlacements/${p.id}`, "DELETE");
    for (const [type, imageId] of Object.entries(ids)) {
      await api("/appAssetLibraryPlacements", "POST", { data: { type: "appAssetLibraryPlacements", attributes: { placementType: type },
        relationships: { appStoreVersionLocalization: { data: { type: "appStoreVersionLocalizations", id: l.id } },
          image: { data: { type: "appAssetLibraryImages", id: imageId } } } } });
    }
    const back = (await api(`/appStoreVersionLocalizations/${l.id}/placements?limit=200`)).data.filter((p) => p.attributes.placementType in FILES);
    if (back.length !== 2) throw new Error(`read back ${back.length} placements`);
    done++;
    console.log(`✓ ${locale}`);
  } catch (e) {
    console.log(`✗ ${locale}: ${e.message}`);
  }
}
console.log(`\n${done}/${locs.length} localisations have both assets. Nothing was submitted.`);
