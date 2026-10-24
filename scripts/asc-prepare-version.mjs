#!/usr/bin/env node
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// Creates the next App Store version (or reuses the editable one), sets it to release
// automatically after approval (owner's standing choice), and attaches a processed build.
// 🚨 It never submits anything for review: that needs the owner's explicit consent.
//
//   ASC_ISSUER_ID=… ASC_KEY_ID=… ASC_PRIVATE_KEY_PATH=… PLATFORM=IOS \
//     node scripts/asc-prepare-version.mjs <version> <build number>

import { readFileSync } from "node:fs";
import { createSign } from "node:crypto";

const APP_ID = "6824033636";
const PLATFORM = process.env.PLATFORM ?? "IOS";
const [versionString, buildNumber] = process.argv.slice(2);
if (!versionString || !buildNumber) throw new Error("Usage: asc-prepare-version.mjs <version> <build number>");
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

const editable = (await api(`/v1/apps/${APP_ID}/appStoreVersions?filter[platform]=${PLATFORM}&filter[appStoreState]=PREPARE_FOR_SUBMISSION,DEVELOPER_REJECTED,REJECTED,METADATA_REJECTED`)).data[0];
let version;
if (editable) {
  version = (await api(`/v1/appStoreVersions/${editable.id}`, "PATCH", { data: { type: "appStoreVersions", id: editable.id,
    attributes: { versionString, releaseType: "AFTER_APPROVAL" } } })).data;
  console.log(`• reused the editable ${PLATFORM} version, now ${versionString}`);
} else {
  version = (await api("/v1/appStoreVersions", "POST", { data: { type: "appStoreVersions",
    attributes: { platform: PLATFORM, versionString, releaseType: "AFTER_APPROVAL" },
    relationships: { app: { data: { type: "apps", id: APP_ID } } } } })).data;
  console.log(`• created ${PLATFORM} ${versionString}`);
}

const build = (await api(`/v1/builds?filter[app]=${APP_ID}&filter[version]=${buildNumber}&filter[preReleaseVersion.platform]=${PLATFORM}&filter[processingState]=VALID`)).data[0];
if (!build) throw new Error(`Build ${buildNumber} isn't processed (VALID) yet`);
await api(`/v1/appStoreVersions/${version.id}/relationships/build`, "PATCH", { data: { type: "builds", id: build.id } });
console.log(`• attached build ${buildNumber}; releases automatically after approval`);
console.log("Nothing was submitted.");
