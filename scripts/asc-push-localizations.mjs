#!/usr/bin/env node
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// Pushes store/localized/<locale>.json to App Store Connect: name, subtitle and privacy policy URL
// on the app info, and description, keywords, promotional text and URLs on the editable iOS
// version. Missing localisations are created. 🚨 It never submits anything for review.
//
//   ASC_ISSUER_ID=… ASC_KEY_ID=… ASC_PRIVATE_KEY_PATH=… node scripts/asc-push-localizations.mjs [locale …]

import { readFileSync, readdirSync } from "node:fs";
import { createSign } from "node:crypto";

const APP_ID = "6824033636";
// IOS (default) or MAC_OS: which platform's editable version to fill.
const PLATFORM = process.env.PLATFORM ?? "IOS";
const { ASC_ISSUER_ID, ASC_KEY_ID, ASC_PRIVATE_KEY_PATH } = process.env;
for (const [k, v] of Object.entries({ ASC_ISSUER_ID, ASC_KEY_ID, ASC_PRIVATE_KEY_PATH }))
  if (!v) { console.error(`Missing env ${k}`); process.exit(1); }
const key = readFileSync(ASC_PRIVATE_KEY_PATH, "utf8");
const en = JSON.parse(readFileSync(new URL("../store/listing-en-US.json", import.meta.url), "utf8"));
const DIR = new URL("../store/localized/", import.meta.url);

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
  if (!r.ok) throw new Error(`${method} ${path} → ${r.status}\n${t.slice(0, 600)}`);
  return t ? JSON.parse(t) : null;
}

const versions = await api(`/v1/apps/${APP_ID}/appStoreVersions?filter[platform]=${PLATFORM}&filter[appStoreState]=PREPARE_FOR_SUBMISSION,DEVELOPER_REJECTED,REJECTED,METADATA_REJECTED`);
const version = versions.data[0];
if (!version) throw new Error("No editable iOS version");
const infos = await api(`/v1/apps/${APP_ID}/appInfos`);
const info = infos.data.find((i) => ["PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED"].includes(i.attributes.state)) ?? infos.data[0];
const infoLocData = (await api(`/v1/appInfos/${info.id}/appInfoLocalizations?limit=200`)).data;
const infoLocs = Object.fromEntries(infoLocData.map((l) => [l.attributes.locale, l.id]));
const infoNow = Object.fromEntries(infoLocData.map((l) => [l.attributes.locale, l.attributes]));
let verLocs = Object.fromEntries((await api(`/v1/appStoreVersions/${version.id}/appStoreVersionLocalizations?limit=200`)).data.map((l) => [l.attributes.locale, l.id]));

const wanted = process.argv.slice(2);
const files = readdirSync(DIR).filter((f) => f.endsWith(".json")).map((f) => f.slice(0, -5))
  .filter((l) => !wanted.length || wanted.includes(l)).sort();

let failed = 0;
for (const locale of files) {
  const l = JSON.parse(readFileSync(new URL(`${locale}.json`, DIR), "utf8"));
  try {
    const infoAttrs = { name: l.name, subtitle: l.subtitle, privacyPolicyUrl: en.privacyPolicyUrl };
    if (infoLocs[locale]) {
      // The app info locks while any platform is in review; skip it then if it already matches.
      const same = infoNow[locale]?.name === l.name && infoNow[locale]?.subtitle === l.subtitle;
      if (!same) await api(`/v1/appInfoLocalizations/${infoLocs[locale]}`, "PATCH", { data: { type: "appInfoLocalizations", id: infoLocs[locale], attributes: infoAttrs } });
    } else {
      await api(`/v1/appInfoLocalizations`, "POST", { data: { type: "appInfoLocalizations", attributes: { locale, ...infoAttrs },
        relationships: { appInfo: { data: { type: "appInfos", id: info.id } } } } });
    }
    // Creating an app-info localisation also creates the version's, so look it up again.
    if (!verLocs[locale]) Object.assign(verLocs, Object.fromEntries((await api(`/v1/appStoreVersions/${version.id}/appStoreVersionLocalizations?limit=200`)).data.map((v) => [v.attributes.locale, v.id])));
    const verAttrs = { description: l.description, keywords: l.keywords, promotionalText: l.promotionalText,
      supportUrl: en.supportUrl, marketingUrl: en.marketingUrl, ...(l.whatsNew ? { whatsNew: l.whatsNew } : {}) };
    if (verLocs[locale]) {
      await api(`/v1/appStoreVersionLocalizations/${verLocs[locale]}`, "PATCH", { data: { type: "appStoreVersionLocalizations", id: verLocs[locale], attributes: verAttrs } });
    } else {
      await api(`/v1/appStoreVersionLocalizations`, "POST", { data: { type: "appStoreVersionLocalizations", attributes: { locale, ...verAttrs },
        relationships: { appStoreVersion: { data: { type: "appStoreVersions", id: version.id } } } } });
    }
    console.log(`✓ ${locale}`);
  } catch (e) {
    failed++;
    console.log(`✗ ${locale}: ${e.message}`);
  }
}
console.log(`\n${files.length - failed}/${files.length} locales pushed. Nothing was submitted.`);
