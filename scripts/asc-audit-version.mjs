#!/usr/bin/env node
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// Read-only check of the editable App Store version before the owner submits it: the build, the
// release setting, every language's text against the repo, What's New, screenshots, reviewer
// notes and links. GETs only; it changes and submits nothing.
//
//   ASC_ISSUER_ID=… ASC_KEY_ID=… ASC_PRIVATE_KEY_PATH=… PLATFORM=IOS node scripts/asc-audit-version.mjs

import { readFileSync, readdirSync } from "node:fs";
import { createSign } from "node:crypto";

const APP_ID = "6824033636";
const PLATFORM = process.env.PLATFORM ?? "IOS";
const { ASC_ISSUER_ID, ASC_KEY_ID, ASC_PRIVATE_KEY_PATH } = process.env;
const key = readFileSync(ASC_PRIVATE_KEY_PATH, "utf8");
const token = () => {
  const b = (o) => Buffer.from(JSON.stringify(o)).toString("base64url");
  const n = Math.floor(Date.now() / 1000);
  const h = b({ alg: "ES256", kid: ASC_KEY_ID, typ: "JWT" });
  const p = b({ iss: ASC_ISSUER_ID, iat: n, exp: n + 900, aud: "appstoreconnect-v1" });
  return `${h}.${p}.${createSign("SHA256").update(`${h}.${p}`).sign({ key, dsaEncoding: "ieee-p1363" }).toString("base64url")}`;
};
const api = async (path) => {
  const r = await fetch(`https://api.appstoreconnect.apple.com${path}`, { headers: { Authorization: `Bearer ${token()}` } });
  if (!r.ok) throw new Error(`GET ${path} → ${r.status}`);
  return r.json();
};

let problems = 0;
const ok = (cond, label) => { console.log(`${cond ? "✓" : "✗"} ${label}`); if (!cond) problems++; };

const en = JSON.parse(readFileSync(new URL("../store/listing-en-US.json", import.meta.url), "utf8"));
const v = (await api(`/v1/apps/${APP_ID}/appStoreVersions?filter[platform]=${PLATFORM}&filter[appStoreState]=PREPARE_FOR_SUBMISSION,DEVELOPER_REJECTED,REJECTED,METADATA_REJECTED&include=build`));
const version = v.data[0];
ok(!!version, `${PLATFORM} version ready to submit: ${version?.attributes.versionString}`);
ok(version.attributes.releaseType === "AFTER_APPROVAL", `releases automatically after approval (${version.attributes.releaseType})`);
const build = v.included?.find((x) => x.type === "builds");
ok(!!build, `build attached: ${build?.attributes.version} (${build?.attributes.processingState})`);
ok(build?.attributes.processingState === "VALID" && !build?.attributes.expired, "build processed and not expired");
ok(build?.attributes.usesNonExemptEncryption === false, `export compliance answered (uses non-exempt encryption: ${build?.attributes.usesNonExemptEncryption})`);

// Every language against the repo.
const locs = (await api(`/v1/appStoreVersions/${version.id}/appStoreVersionLocalizations?limit=200`)).data;
const repo = { "en-US": en };
for (const f of readdirSync(new URL("../store/localized/", import.meta.url))) if (f.endsWith(".json"))
  repo[f.slice(0, -5)] = JSON.parse(readFileSync(new URL(`../store/localized/${f}`, import.meta.url), "utf8"));
let same = 0;
for (const l of locs) {
  const r = repo[l.attributes.locale]; if (!r) continue;
  const a = l.attributes;
  // What's New is iOS only (it's the iPhone Duo line, and a platform's first version can't have one).
  const fields = ["description", "keywords", "promotionalText", ...(PLATFORM === "IOS" ? ["whatsNew"] : [])].filter((k) => (a[k] ?? "") !== (r[k] ?? ""));
  if (fields.length) ok(false, `${l.attributes.locale}: differs from repo in ${fields.join(", ")}`); else same++;
  if (PLATFORM === "IOS" && !a.whatsNew?.includes("iPhone Duo")) ok(false, `${l.attributes.locale}: What's New missing`);
}
ok(same === Object.keys(repo).length, `${same} of ${Object.keys(repo).length} languages match the repo exactly (description, keywords, promo, What's New)`);

// Screenshots (the primary language's sets; the others fall back to them).
const enLoc = locs.find((l) => l.attributes.locale === "en-US");
const sets = (await api(`/v1/appStoreVersionLocalizations/${enLoc.id}/appScreenshotSets?limit=50`)).data;
for (const want of PLATFORM === "MAC_OS" ? ["APP_DESKTOP"] : ["APP_IPHONE_67", "APP_IPAD_PRO_3GEN_129", "APP_IPHONE_DUO"]) {
  const set = sets.find((s) => s.attributes.screenshotDisplayType === want);
  const shots = set ? (await api(`/v1/appScreenshotSets/${set.id}/appScreenshots?limit=50`)).data : [];
  const done = shots.filter((s) => s.attributes.assetDeliveryState?.state === "COMPLETE").length;
  ok(shots.length >= 1 && done === shots.length, `${want}: ${shots.length} slides, ${done} processed`);
}

// Reviewer notes and contact.
const notes = readFileSync(new URL(PLATFORM === "MAC_OS" ? "../store/review-notes-mac.txt" : "../store/review-notes.txt", import.meta.url), "utf8").trim();
const rd = (await api(`/v1/appStoreVersions/${version.id}/appStoreReviewDetail`)).data.attributes;
ok(rd.notes === notes, `reviewer notes match the repo (${rd.notes?.length} of 4000 characters)`);
ok(!!rd.contactEmail && !!rd.contactPhone && rd.demoAccountRequired === false, "review contact set, no demo account needed");

// Links.
for (const [name, url] of [["support", en.supportUrl], ["marketing", en.marketingUrl], ["privacy policy", en.privacyPolicyUrl]]) {
  const r = await fetch(url, { redirect: "follow" }).catch(() => null);
  ok(r?.ok, `${name} link loads (${url})`);
}

console.log(problems ? `\n${problems} problem(s). Nothing was submitted.` : "\nAll checks passed. Nothing was submitted.");
process.exit(problems ? 1 : 0);
