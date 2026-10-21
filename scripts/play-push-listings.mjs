#!/usr/bin/env node
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// Pushes the localised Play listings (GooglePlayConsole/localized/*.json) as listing text only: no
// bundle, no track, no release. A language new to Play also gets the English gallery (icon, feature
// graphic, phone screenshots) in the same edit, because Play does not inherit images from the
// default language and would otherwise publish a page with no screenshots. Slides stay English.
//
// The default run rehearses the whole edit and does NOT commit. 🚨 --apply SENDS THE CHANGES FOR
// GOOGLE'S REVIEW: once the app has a live release, Play refuses changesNotSentForReview ("Changes
// are sent for review automatically", 2026-10-21). So --apply needs the owner's explicit consent.
//
//   PLAY_SERVICE_ACCOUNT_JSON=… node scripts/play-push-listings.mjs [--apply]

import { readFileSync, readdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { accessToken, api, pushGraphics } from "./play-api.mjs";

const APPLY = process.argv.includes("--apply");
const ROOT = fileURLToPath(new URL("..", import.meta.url));
const DIR = `${ROOT}GooglePlayConsole/localized/`;
const LIMITS = { title: 30, shortDescription: 80, fullDescription: 4000 };

const local = Object.fromEntries(readdirSync(DIR).filter((f) => f.endsWith(".json"))
  .map((f) => JSON.parse(readFileSync(DIR + f, "utf8"))).map((l) => [l.language, l]));
for (const [lang, l] of Object.entries(local))
  for (const [f, max] of Object.entries(LIMITS))
    if (!l[f] || [...l[f]].length > max) throw new Error(`${lang} ${f} is empty or over ${max}`);

const slides = readdirSync(`${ROOT}store/slides/android-phone`).filter((f) => f.endsWith(".png")).sort()
  .map((f) => `${ROOT}store/slides/android-phone/${f}`);
const gallery = {
  icon: [`${ROOT}store/slides/play-icon-512.png`],
  featureGraphic: [`${ROOT}store/slides/play-feature-1024x500.png`],
  phoneScreenshots: slides,
};

const { token } = await accessToken();
const edit = await api(token, "/edits", { method: "POST", body: {} });
const E = `/edits/${edit.id}`;
const live = new Set(((await api(token, `${E}/listings`)).listings ?? []).map((l) => l.language));

for (const [lang, l] of Object.entries(local))
  await api(token, `${E}/listings/${lang}`, { method: "PUT", body: {
    language: lang, title: l.title, shortDescription: l.shortDescription, fullDescription: l.fullDescription } });
console.log(`• listing text: ${Object.keys(local).length} languages`);

const fresh = Object.keys(local).filter((l) => !live.has(l));
if (fresh.length) {
  const started = Date.now();
  await pushGraphics(token, E, fresh, gallery);
  console.log(`• gallery for ${fresh.length} new languages, read back in order (${Math.round((Date.now() - started) / 1000)} s)`);
}

if (!APPLY) {
  await api(token, E, { method: "DELETE" });
  console.log("Rehearsal: edit discarded. Nothing changed. Re-run with --apply.");
} else {
  await api(token, `${E}:commit`, { method: "POST" });
  console.log("Committed and sent for Google's review.");
}
