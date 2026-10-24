#!/usr/bin/env node
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// Standing rule after every successful submission: expire the obsolete builds in App Store
// Connect. For each platform it keeps the build attached to the newest App Store version (in
// review or on sale) and every newer one, and expires every older build still live in TestFlight.
// Lists only, unless --apply is passed. Expiring can't be undone.
//
//   ASC_ISSUER_ID=… ASC_KEY_ID=… ASC_PRIVATE_KEY_PATH=… node scripts/asc-expire-old-builds.mjs [--apply]

import { readFileSync } from "node:fs";
import { createSign } from "node:crypto";

const APP_ID = "6824033636";
const apply = process.argv.includes("--apply");
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

for (const platform of ["IOS", "MAC_OS"]) {
  const versions = await api(`/v1/apps/${APP_ID}/appStoreVersions?filter[platform]=${platform}&include=build&limit=10`);
  const attached = versions.data.map((v) => ({ state: v.attributes.appStoreState, build: v.relationships.build.data?.id }))
    .filter((v) => v.build && v.state !== "PREPARE_FOR_SUBMISSION");
  const builds = (await api(`/v1/builds?filter[app]=${APP_ID}&filter[preReleaseVersion.platform]=${platform}&limit=200`)).data;
  const keepIds = new Set(attached.map((v) => v.build));
  const kept = builds.filter((b) => keepIds.has(b.id));
  if (!kept.length) { console.log(`${platform}: no build in review or on sale; nothing expired`); continue; }
  console.log(`${platform}: keeping build ${kept.map((b) => b.attributes.version).join(", ")} (${attached.map((v) => v.state).join(", ")}) and the newest build`);
  // Above that line only the newest build stays in TestFlight; older ones there are superseded.
  const newest = Math.max(...builds.map((b) => Number(b.attributes.version)));
  const old = builds.filter((b) => !b.attributes.expired && !keepIds.has(b.id) && Number(b.attributes.version) < newest)
    .sort((a, b) => Number(a.attributes.version) - Number(b.attributes.version));
  for (const b of old) {
    if (apply) await api(`/v1/builds/${b.id}`, "PATCH", { data: { type: "builds", id: b.id, attributes: { expired: true } } });
    console.log(`  ${apply ? "expired" : "would expire"} build ${b.attributes.version}`);
  }
  if (!old.length) console.log("  nothing older left in TestFlight");
}
if (!apply) console.log("\nNothing changed. Pass --apply to expire.");
