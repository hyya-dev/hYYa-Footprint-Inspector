#!/usr/bin/env node
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// Prepares a whole Play update in ONE edit and leaves it unsent: the release bundle on the closed
// testing track (alpha), the listing text in every language (GooglePlayConsole/localized/), and the
// slides in every language. Prints the edit id.
//
// 🚨 Once the app has a live release, committing an edit sends it for Google's review. So this
// script never commits on its own: `--send <edit id>` commits a prepared edit, and only on the
// owner's explicit consent. An unsent edit is simply discarded by Play after a while.
//
//   PLAY_SERVICE_ACCOUNT_JSON=… node scripts/play-prepare-update.mjs
//   PLAY_SERVICE_ACCOUNT_JSON=… node scripts/play-prepare-update.mjs --send <edit id>

import { readFileSync, readdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { accessToken, api, pushGraphics, PACKAGE } from "./play-api.mjs";

const ROOT = fileURLToPath(new URL("..", import.meta.url));
const args = process.argv.slice(2);
const { token } = await accessToken();
// Play's API sometimes answers 429 or 5xx for a moment: wait and try again (1, 2, 4, 8, 16 s).
const call = async (...a) => {
  for (let wait = 1000; ; wait *= 2) {
    try { return await api(...a); } catch (e) {
      if (wait > 16000 || !/→ (429|5\d\d):/.test(String(e.message))) throw e;
      await new Promise((r) => setTimeout(r, wait));
    }
  }
};

if (args[0] === "--send") {
  const id = args[1];
  if (!id) throw new Error("Pass the edit id printed when it was prepared");
  await api(token, `/edits/${id}:commit`, { method: "POST" });
  console.log(`Edit ${id} committed and sent for Google's review.`);
  process.exit(0);
}

const LIMITS = { title: 30, shortDescription: 80, fullDescription: 4000 };
const dir = `${ROOT}GooglePlayConsole/localized/`;
// Languages whose translation didn't pass the checks: their old listing is removed, so Play shows
// the current English instead of outdated text. --english-for fa,hi-IN,…
const englishFor = (args[args.indexOf("--english-for") + 1] ?? "").split(",").filter((x) => args.includes("--english-for") && x);
const listings = readdirSync(dir).filter((f) => f.endsWith(".json")).map((f) => JSON.parse(readFileSync(dir + f, "utf8")))
  .filter((l) => !englishFor.includes(l.language));
// English (United States) comes from the approved source file.
const md = readFileSync(`${ROOT}GooglePlayConsole/listing-en-US.md`, "utf8");
const section = (name) => md.split(`## ${name}\n`)[1].split("\n## ")[0].trim();
listings.push({ language: "en-US", title: section("App name (30)"), shortDescription: section("Short description (80)"), fullDescription: section("Full description (4000)") });
for (const l of listings) for (const [f, max] of Object.entries(LIMITS))
  if (!l[f] || [...l[f]].length > max) throw new Error(`${l.language} ${f} is empty or over ${max}`);

const slides = readdirSync(`${ROOT}store/slides/android-phone`).filter((f) => f.endsWith(".png")).sort()
  .map((f) => `${ROOT}store/slides/android-phone/${f}`);
const gallery = {
  icon: [`${ROOT}store/slides/play-icon-512.png`],
  featureGraphic: [`${ROOT}store/slides/play-feature-1024x500.png`],
  phoneScreenshots: slides,
};

const edit = await api(token, "/edits", { method: "POST", body: {} });
const E = `/edits/${edit.id}`;

const aab = readFileSync(`${ROOT}Android/app/build/outputs/bundle/release/app-release.aab`);
const b = await api(token, `https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/${PACKAGE}${E}/bundles?uploadType=media`,
  { method: "POST", raw: aab, contentType: "application/octet-stream" });
await call(token, `${E}/tracks/alpha`, { method: "PUT", body: { track: "alpha", releases: [{
  name: "1.0.0 (" + b.versionCode + ")", versionCodes: [String(b.versionCode)], status: "completed",
  releaseNotes: [{ language: "en-US", text: "New: see who can watch you, fix things step by step, and a colour chart on every page. Plainer words throughout." }],
}] } });
console.log(`• closed testing: versionCode ${b.versionCode}`);

for (const l of listings)
  await call(token, `${E}/listings/${l.language}`, { method: "PUT", body: {
    language: l.language, title: l.title, shortDescription: l.shortDescription, fullDescription: l.fullDescription } });
for (const lang of englishFor) await api(token, `${E}/listings/${lang}`, { method: "DELETE" }).catch(() => {});
console.log(`• listing text: ${listings.length} languages${englishFor.length ? `; ${englishFor.join(", ")} now show English` : ""}`);

const started = Date.now();
await pushGraphics(token, E, listings.map((l) => l.language), gallery, { log: () => {} });
console.log(`• slides (${slides.length}) in every language, read back in order (${Math.round((Date.now() - started) / 1000)} s)`);

await api(token, `${E}:validate`, { method: "POST" });
console.log(`\nPrepared and validated, NOT sent. Edit id: ${edit.id}`);
console.log(`To send for review (owner's consent only): node scripts/play-prepare-update.mjs --send ${edit.id}`);
