#!/usr/bin/env node
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// Pushes the en-US Play listing, graphics and the release bundle to the CLOSED TESTING track
// ("alpha") as a DRAFT release, in one edit. 🚨 A draft is not sent for review: sending a release
// for Google's review needs the owner's explicit consent and is done in Play Console.
//
//   PLAY_SERVICE_ACCOUNT_JSON=… node scripts/play-publish.mjs [--no-bundle] [--dry-run]

import { readFileSync, readdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { accessToken, api, pushGraphics, PACKAGE } from "./play-api.mjs";

const args = process.argv.slice(2);
const DRY = args.includes("--dry-run");
const WITH_BUNDLE = !args.includes("--no-bundle");
const ROOT = fileURLToPath(new URL("..", import.meta.url));

const md = readFileSync(`${ROOT}GooglePlayConsole/listing-en-US.md`, "utf8");
const section = (name) => md.split(`## ${name}\n`)[1].split("\n## ")[0].trim();
const listing = {
  language: "en-US",
  title: section("App name (30)"),
  shortDescription: section("Short description (80)"),
  fullDescription: section("Full description (4000)"),
};
for (const [k, max] of [["title", 30], ["shortDescription", 80], ["fullDescription", 4000]])
  if ([...listing[k]].length > max) throw new Error(`${k} is over ${max}`);

const slides = readdirSync(`${ROOT}store/slides/android-phone`).filter((f) => f.endsWith(".png")).sort()
  .map((f) => `${ROOT}store/slides/android-phone/${f}`);
const graphics = {
  icon: [`${ROOT}store/slides/play-icon-512.png`],
  featureGraphic: [`${ROOT}store/slides/play-feature-1024x500.png`],
  phoneScreenshots: slides,
};

const { token } = await accessToken();
const edit = await api(token, "/edits", { method: "POST", body: {} });
const E = `/edits/${edit.id}`;
console.log(`edit ${edit.id}`);

await api(token, `${E}/details`, { method: "PUT", body: {
  defaultLanguage: "en-US", contactWebsite: "https://hyya.com", contactEmail: "h@hyya.com" } });
await api(token, `${E}/listings/en-US`, { method: "PUT", body: listing });
console.log("• listing en-US");
await pushGraphics(token, E, ["en-US"], graphics);
console.log(`• graphics: icon, feature graphic, ${slides.length} phone screenshots`);

if (WITH_BUNDLE) {
  const aab = readFileSync(`${ROOT}Android/app/build/outputs/bundle/release/app-release.aab`);
  const b = await api(token, `https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/${PACKAGE}${E}/bundles?uploadType=media`,
    { method: "POST", raw: aab, contentType: "application/octet-stream" });
  console.log(`• bundle versionCode ${b.versionCode}`);
  await api(token, `${E}/tracks/alpha`, { method: "PUT", body: { track: "alpha", releases: [{
    name: "1.0.0", versionCodes: [String(b.versionCode)], status: "draft",
    releaseNotes: [{ language: "en-US", text: "First release: see what any app can learn about your device, and how to fix it." }],
  }] } });
  console.log("• closed testing (alpha): draft release 1.0.0");
}

if (DRY) {
  await api(token, E, { method: "DELETE" });
  console.log("Dry run: edit discarded. Nothing changed.");
} else {
  // A never-published app rejects changesNotSentForReview; a DRAFT release is never reviewed.
  await api(token, `${E}:commit`, { method: "POST" });
  console.log("Committed. The release is a draft: nothing was sent for review.");
}
