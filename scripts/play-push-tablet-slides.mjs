// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// Pushes the tablet slides (store/slides/android-tablet) as the 7-inch and 10-inch screenshots of
// every Play language: no bundle, no track, no listing text. Slides stay English.
//
// The default run rehearses the whole edit and does NOT commit. 🚨 --apply SENDS THE CHANGES FOR
// GOOGLE'S REVIEW, so it needs explicit human approval.
//
//   PLAY_SERVICE_ACCOUNT_JSON=… node scripts/play-push-tablet-slides.mjs [--apply]
import { readdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { accessToken, api, pushGraphics } from "./play-api.mjs";

const APPLY = process.argv.includes("--apply");
const ROOT = fileURLToPath(new URL("..", import.meta.url));
const tablets = readdirSync(`${ROOT}store/slides/android-tablet`).filter((f) => f.endsWith(".png")).sort()
  .map((f) => `${ROOT}store/slides/android-tablet/${f}`);

const { token } = await accessToken();
const edit = await api(token, "/edits", { method: "POST", body: {} });
const E = `/edits/${edit.id}`;
const langs = ((await api(token, `${E}/listings`)).listings ?? []).map((l) => l.language);
const started = Date.now();
await pushGraphics(token, E, langs, { sevenInchScreenshots: tablets, tenInchScreenshots: tablets }, { log: () => {} });
console.log(`• tablet slides (${tablets.length}) for 7- and 10-inch in ${langs.length} languages, read back in order (${Math.round((Date.now() - started) / 1000)} s)`);
await api(token, `${E}:validate`, { method: "POST" });

if (!APPLY) {
  await api(token, E, { method: "DELETE" });
  console.log("Rehearsed and validated, NOT sent. Run with --apply to send for Google's review.");
} else {
  await api(token, `${E}:commit`, { method: "POST" });
  console.log(`Edit ${edit.id} committed and sent for Google's review.`);
}
