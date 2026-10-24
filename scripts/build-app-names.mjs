#!/usr/bin/env node
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// Builds App/Resources/AppNames.json: bundle id → the app's App Store name, for the most used apps
// in every App Store country (Apple's public top free, paid and grossing charts, 200 each). The
// Tracker uses it to show "Bolt" instead of "ee.mtakso.client", fully offline: the app itself
// never looks anything up. Run it before a release to refresh the list.
//
//   node scripts/build-app-names.mjs

import { writeFileSync } from "node:fs";

// English-speaking stores first, so a global app keeps its English name.
const COUNTRIES = ("us gb au ca ie nz in sg za ae sa kw qa bh om eg jo lb ma dz tn iq ly ye ps pk bd lk np "
  + "de at ch fr be lu nl dk se no fi is it es pt gr cy mt pl cz sk hu ro bg hr si rs ba mk me al ee lv lt "
  + "ua by md ru kz uz kg tj tm az am ge tr il ir jp kr cn tw hk mo th vn my id ph kh la mm mn bn "
  + "mx br ar cl co pe ve ec bo py uy cr pa gt hn sv ni do jm tt bs bb bz gy sr "
  + "ng gh ke tz ug rw et sn ci cm ao mz zm zw bw na mg mu sc").split(" ");
const CHARTS = ["topfreeapplications", "toppaidapplications", "topgrossingapplications"];

// "Bolt: Request a Ride" → "Bolt"; "Q | كيو" → "Q"; keep short names whole.
const short = (n) => {
  const first = n.split(/\s+[-–—|:]\s+|:\s+/)[0].trim();
  return first.length >= 2 ? first : n.trim();
};

const names = {};
for (const cc of COUNTRIES) {
  for (const chart of CHARTS) {
    try {
      const r = await fetch(`https://itunes.apple.com/${cc}/rss/${chart}/limit=200/json`, { redirect: "follow" });
      if (!r.ok) continue;
      const entries = (await r.json()).feed?.entry ?? [];
      for (const e of entries) {
        const id = e.id?.attributes?.["im:bundleId"], name = e["im:name"]?.label;
        if (id && name && !names[id]) names[id] = short(name);
      }
    } catch { /* a storefront without that chart */ }
  }
  process.stdout.write(`${cc} `);
}
const sorted = Object.fromEntries(Object.entries(names).sort(([a], [b]) => a.localeCompare(b)));
writeFileSync(new URL("../App/Resources/AppNames.json", import.meta.url), JSON.stringify(sorted) + "\n");
console.log(`\n${Object.keys(sorted).length} apps → App/Resources/AppNames.json`);
