#!/usr/bin/env node
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// Pushes store/listing-en-US.json and store/review-notes.txt to App Store Connect for the
// editable iOS version. 🚨 It never submits anything for review: submitting needs the owner's
// explicit consent.
//
//   ASC_ISSUER_ID=… ASC_KEY_ID=… ASC_PRIVATE_KEY_PATH=… node scripts/asc-fill-listing.mjs [--dry-run]
//
// Reviewer contact details are copied from another hYYa app's latest version (REVIEW_CONTACT_APP_ID,
// default hYYa Encrypted Notes), so no personal details live in this repo.

import { readFileSync } from "node:fs";
import { createSign } from "node:crypto";

const APP_ID = "6824033636";
// IOS (default) or MAC_OS: which platform's editable version to fill.
const PLATFORM = process.env.PLATFORM ?? "IOS";
const REVIEW_CONTACT_APP_ID = process.env.REVIEW_CONTACT_APP_ID ?? "6792328099";
const DRY = process.argv.includes("--dry-run");
const { ASC_ISSUER_ID, ASC_KEY_ID, ASC_PRIVATE_KEY_PATH } = process.env;
for (const [k, v] of Object.entries({ ASC_ISSUER_ID, ASC_KEY_ID, ASC_PRIVATE_KEY_PATH }))
  if (!v) { console.error(`Missing env ${k}`); process.exit(1); }

const key = readFileSync(ASC_PRIVATE_KEY_PATH, "utf8");
const listing = JSON.parse(readFileSync(new URL("../store/listing-en-US.json", import.meta.url), "utf8"));
// The Mac has its own What's New (whatsNewMac); a platform's first version has none.
const whatsNew = PLATFORM === "MAC_OS" ? listing.whatsNewMac : listing.whatsNew;
const notes = readFileSync(new URL(PLATFORM === "MAC_OS" ? "../store/review-notes-mac.txt" : "../store/review-notes.txt", import.meta.url), "utf8").trim();

function token() {
  const b64 = (o) => Buffer.from(JSON.stringify(o)).toString("base64url");
  const now = Math.floor(Date.now() / 1000);
  const head = b64({ alg: "ES256", kid: ASC_KEY_ID, typ: "JWT" });
  const body = b64({ iss: ASC_ISSUER_ID, iat: now, exp: now + 900, aud: "appstoreconnect-v1" });
  const sig = createSign("SHA256").update(`${head}.${body}`).sign({ key, dsaEncoding: "ieee-p1363" }).toString("base64url");
  return `${head}.${body}.${sig}`;
}

async function api(path, method = "GET", body) {
  if (DRY && method !== "GET") { console.log(`DRY ${method} ${path}`); return null; }
  const res = await fetch(`https://api.appstoreconnect.apple.com${path}`, {
    method, headers: { Authorization: `Bearer ${token()}`, "Content-Type": "application/json" },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`${method} ${path} → ${res.status}\n${text}`);
  return text ? JSON.parse(text) : null;
}

const step = (msg) => console.log(`• ${msg}`);

// Editable version and app info
const versions = await api(`/v1/apps/${APP_ID}/appStoreVersions?filter[platform]=${PLATFORM}&filter[appStoreState]=PREPARE_FOR_SUBMISSION,DEVELOPER_REJECTED,REJECTED,METADATA_REJECTED`);
const version = versions.data[0];
if (!version) throw new Error("No editable iOS version");
const infos = await api(`/v1/apps/${APP_ID}/appInfos`);
const info = infos.data.find((i) => ["PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED"].includes(i.attributes.state)) ?? infos.data[0];

// The app info (name, subtitle, categories, age rating) is shared by every platform and locks while
// any platform is in review. Skip it then, but only if what's there already matches.
const locked = (e) => /INVALID_STATE|STATE_ERROR|not editable/.test(String(e.message));
async function infoStep(label, fn, matches = async () => true) {
  try { await fn(); step(label); }
  catch (e) {
    if (!locked(e)) throw e;
    if (!(await matches())) throw new Error(`${label}: locked while another platform is in review, and it differs from the repo`);
    step(`${label}: already as in the repo (locked while another platform is in review)`);
  }
}

// App info localization: name, subtitle, privacy policy URL
const infoLocs = await api(`/v1/appInfos/${info.id}/appInfoLocalizations`);
const infoLoc = infoLocs.data.find((l) => l.attributes.locale === "en-US");
await infoStep(`name, subtitle, privacy policy URL`,
  () => api(`/v1/appInfoLocalizations/${infoLoc.id}`, "PATCH", { data: { type: "appInfoLocalizations", id: infoLoc.id, attributes: {
    name: listing.name, subtitle: listing.subtitle, privacyPolicyUrl: listing.privacyPolicyUrl } } }),
  async () => infoLoc.attributes.name === listing.name && infoLoc.attributes.subtitle === listing.subtitle);

// Version localization: description, keywords, promo text, URLs
const verLocs = await api(`/v1/appStoreVersions/${version.id}/appStoreVersionLocalizations`);
const verLoc = verLocs.data.find((l) => l.attributes.locale === "en-US");
await api(`/v1/appStoreVersionLocalizations/${verLoc.id}`, "PATCH", { data: { type: "appStoreVersionLocalizations", id: verLoc.id, attributes: {
  description: listing.description, keywords: listing.keywords, promotionalText: listing.promotionalText,
  supportUrl: listing.supportUrl, marketingUrl: listing.marketingUrl, ...(whatsNew ? { whatsNew } : {}) } } });
step(`description, keywords, promotional text, ${whatsNew ? "What's New, " : ""}support and marketing URLs`);

// Copyright on the version
await api(`/v1/appStoreVersions/${version.id}`, "PATCH", { data: { type: "appStoreVersions", id: version.id, attributes: { copyright: listing.copyright } } });
step(`copyright`);

// Categories
await infoStep(`categories ${listing.primaryCategory} / ${listing.secondaryCategory}`,
  () => api(`/v1/appInfos/${info.id}`, "PATCH", { data: { type: "appInfos", id: info.id, relationships: {
    primaryCategory: { data: { type: "appCategories", id: listing.primaryCategory } },
    secondaryCategory: { data: { type: "appCategories", id: listing.secondaryCategory } } } } }),
  async () => (await api(`/v1/appInfos/${info.id}/primaryCategory`)).data?.id === listing.primaryCategory);

// Age rating: nothing objectionable, no web access, no UGC, no ads → 4+
const none = "NONE";
await infoStep(`age rating answers (all none → 4+)`, () => api(`/v1/ageRatingDeclarations/${info.id}`, "PATCH", { data: { type: "ageRatingDeclarations", id: info.id, attributes: {
  advertising: false, alcoholTobaccoOrDrugUseOrReferences: none, contests: none, gambling: false, gamblingSimulated: none,
  gunsOrOtherWeapons: none, healthOrWellnessTopics: false, lootBox: false, medicalOrTreatmentInformation: none,
  messagingAndChat: false, parentalControls: false, profanityOrCrudeHumor: none, ageAssurance: false,
  sexualContentGraphicAndNudity: none, sexualContentOrNudity: none, socialMedia: false, socialMediaAgeRestricted: false,
  horrorOrFearThemes: none, matureOrSuggestiveThemes: none, unrestrictedWebAccess: false, userGeneratedContent: false,
  violenceCartoonOrFantasy: none, violenceRealisticProlongedGraphicOrSadistic: none, violenceRealistic: none } } }));

// Review details: contact copied from a sibling app, notes from store/review-notes.txt
const sibVersions = await api(`/v1/apps/${REVIEW_CONTACT_APP_ID}/appStoreVersions?limit=1`);
const sibDetail = await api(`/v1/appStoreVersions/${sibVersions.data[0].id}/appStoreReviewDetail`);
const c = sibDetail.data.attributes;
const attrs = { contactFirstName: c.contactFirstName, contactLastName: c.contactLastName, contactPhone: c.contactPhone,
  contactEmail: c.contactEmail, demoAccountRequired: false, notes };
const existing = await api(`/v1/appStoreVersions/${version.id}/appStoreReviewDetail`).catch(() => null);
if (existing?.data) {
  await api(`/v1/appStoreReviewDetails/${existing.data.id}`, "PATCH", { data: { type: "appStoreReviewDetails", id: existing.data.id, attributes: attrs } });
} else {
  await api(`/v1/appStoreReviewDetails`, "POST", { data: { type: "appStoreReviewDetails", attributes: attrs,
    relationships: { appStoreVersion: { data: { type: "appStoreVersions", id: version.id } } } } });
}
step(`review contact (copied) and reviewer notes (${notes.length} chars)`);

console.log(`\nDone for ${listing.name} ${version.attributes.versionString}. Nothing was submitted.`);
