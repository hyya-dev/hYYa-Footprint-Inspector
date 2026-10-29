#!/usr/bin/env node
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// Localises the approved English listing (store/listing-en-US.json) into every App Store locale
// with Gemini, writing store/localized/<locale>.json. Each result is checked against App Store
// limits and our wording rules; failures are retried with the reasons, then reported.
//
//   node scripts/gemini-localize-listing.mjs [locale …] [--model name] [--force]
//   node scripts/gemini-localize-listing.mjs --text-only   (redo promotional text, description and
//     What's New only; each language keeps its own subtitle and keywords, so search ranking holds)
//   node scripts/gemini-localize-listing.mjs --whats-new   (redo What's New only; everything else
//     in each language stays as it is)
//   node scripts/gemini-localize-listing.mjs --whats-new-mac   (redo the Mac's own What's New,
//     whatsNewMac, from the English whatsNewMac; everything else stays as it is)
//   node scripts/gemini-localize-listing.mjs --search-only   (redo subtitle and keywords only, the
//     fields App Store search reads; descriptions and promotional text stay as they are)
//
// The key comes from GEMINI_API_KEY in the environment or in the gitignored .env file.

import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";

const argv = process.argv.slice(2);
const opt = (name, fallback) => { const i = argv.indexOf(name); return i >= 0 ? argv.splice(i, 2)[1] : fallback; };
const MODEL = opt("--model", "gemini-3.7-flash");
const FORCE = argv.includes("--force");
if (FORCE) argv.splice(argv.indexOf("--force"), 1);
const TEXT_ONLY = argv.includes("--text-only");
if (TEXT_ONLY) argv.splice(argv.indexOf("--text-only"), 1);
const WHATS_NEW_ONLY = argv.includes("--whats-new");
if (WHATS_NEW_ONLY) argv.splice(argv.indexOf("--whats-new"), 1);
const WHATS_NEW_MAC = argv.includes("--whats-new-mac");
if (WHATS_NEW_MAC) argv.splice(argv.indexOf("--whats-new-mac"), 1);
const SEARCH_ONLY = argv.includes("--search-only");
if (SEARCH_ONLY) argv.splice(argv.indexOf("--search-only"), 1);
const envFile = new URL("../.env", import.meta.url);
const KEY = process.env.GEMINI_API_KEY || (existsSync(envFile) ? (readFileSync(envFile, "utf8").split("\n")
  .find((l) => l.startsWith("GEMINI_API_KEY=")) ?? "").slice(15).trim() : "");
if (!KEY || KEY.startsWith("PASTE_")) { console.error("Add GEMINI_API_KEY to .env first"); process.exit(1); }

const en = JSON.parse(readFileSync(new URL("../store/listing-en-US.json", import.meta.url), "utf8"));
// The Mac's note runs through the What's New path, then is saved as whatsNewMac.
if (WHATS_NEW_MAC) en.whatsNew = en.whatsNewMac;
const WHATS_NEW = WHATS_NEW_ONLY || WHATS_NEW_MAC;
const OUT = new URL("../store/localized/", import.meta.url);
mkdirSync(OUT, { recursive: true });

export const LOCALES = {
  "ar-SA": "Arabic", "bn-BD": "Bengali", ca: "Catalan", cs: "Czech", da: "Danish", "de-DE": "German",
  el: "Greek", "en-AU": "English (Australia)", "en-CA": "English (Canada)", "en-GB": "English (UK)",
  "es-ES": "Spanish (Spain)", "es-MX": "Spanish (Mexico)", fi: "Finnish", "fr-CA": "French (Canada)",
  "fr-FR": "French (France)", "gu-IN": "Gujarati", he: "Hebrew", hi: "Hindi", hr: "Croatian",
  hu: "Hungarian", id: "Indonesian", it: "Italian", ja: "Japanese", "kn-IN": "Kannada", ko: "Korean",
  "ml-IN": "Malayalam", "mr-IN": "Marathi", ms: "Malay", "nl-NL": "Dutch", no: "Norwegian (Bokmål)",
  "or-IN": "Odia", "pa-IN": "Punjabi (Gurmukhi)", pl: "Polish", "pt-BR": "Portuguese (Brazil)",
  "pt-PT": "Portuguese (Portugal)", ro: "Romanian", ru: "Russian", sk: "Slovak", "sl-SI": "Slovenian",
  sv: "Swedish", "ta-IN": "Tamil", "te-IN": "Telugu", th: "Thai", tr: "Turkish", uk: "Ukrainian",
  "ur-PK": "Urdu", vi: "Vietnamese", "zh-Hans": "Chinese (Simplified)", "zh-Hant": "Chinese (Traditional)",
};
const ENGLISH = new Set(["en-AU", "en-CA", "en-GB"]);
const BANNED = /spyware|malware|anti-?virus|\bvirus\b|#\s*1|\bbest\b/i;
const BRAND = "hYYa Footprint Inspector";

function check(l) {
  const issues = [];
  const len = (s) => [...s].length;
  if (!l.subtitle || len(l.subtitle) > 30) issues.push(`subtitle is ${len(l.subtitle ?? "")} characters (max 30)`);
  if (!l.promotionalText || len(l.promotionalText) > 170) issues.push(`promotional text is ${len(l.promotionalText ?? "")} characters (max 170)`);
  if (!l.description || len(l.description) > 4000) issues.push(`description is ${len(l.description ?? "")} characters (max 4000)`);
  for (const f of ["promotionalText", "description"]) if (/\b(?:iphone|ipad|ios|mac|android)\b/i.test(l[f] ?? "")) issues.push(`${f} must not name a device or platform`);
  if (!l.description?.includes(BRAND)) issues.push(`description must keep the name "${BRAND}" untranslated`);
  const kw = l.keywords ?? "";
  if (!kw || Buffer.byteLength(kw) > 100) issues.push(`keywords are ${Buffer.byteLength(kw)} UTF-8 bytes (max 100)`);
  const words = kw.split(",");
  if (words.some((w) => !w || w !== w.trim())) issues.push("keywords: no spaces around commas and no empty items");
  if (new Set(words.map((w) => w.toLowerCase())).size !== words.length) issues.push("keywords: duplicates");
  const taken = `${BRAND} ${l.subtitle ?? ""}`.toLowerCase().split(/[\s,&:،、・]+/).filter((w) => w.length > 1);
  for (const w of words) if (taken.includes(w.toLowerCase())) issues.push(`keyword "${w}" already appears in the name or subtitle`);
  if (en.whatsNew) {
    if (!l.whatsNew || len(l.whatsNew) > 4000) issues.push("whatsNew is missing or too long");
    else {
      if (en.whatsNew.includes("iPhone Duo") && !l.whatsNew.includes("iPhone Duo")) issues.push('whatsNew must keep "iPhone Duo" exactly as written');
      if (l.whatsNew.split("\n").length !== en.whatsNew.split("\n").length) issues.push("whatsNew must keep the same lines as the English");
    }
  }
  for (const [k, v] of Object.entries(l)) if (BANNED.test(v)) issues.push(`${k} uses a banned word (${v.match(BANNED)[0]})`);
  if (/\bfree\b/i.test(l.subtitle ?? "") || /gratuit|gratis|kostenlos|無料|免费|免費|무료|бесплат|مجان/i.test(l.subtitle ?? "")) issues.push("subtitle must not mention price or free");
  return issues;
}

function prompt(language, feedback) {
  return `You localise App Store listings. Localise this approved English listing for a free, open-source privacy app into ${language}, for people searching the App Store in that language.

Rules:
- Natural, native wording; calm and plain, never alarmist or hyped. Not a word-for-word translation.
- subtitle: at most 30 characters. Use the local everyday terms people search for an "app privacy report" and a "privacy check/checkup" (the system's App Privacy Report keeps its localised name where it has one). No price, no "free", no superlatives.
- keywords: comma-separated search terms people in this language really type, no spaces after commas, at most 100 UTF-8 bytes in total, every term longer than two characters where the script allows. Do not repeat any word from the name "${BRAND}" or from your subtitle. Cover ideas like: app permissions, tracking, privacy scanner, safety check, lockdown mode, location, camera, microphone, photos, contacts, data leak. Never "fingerprint" (people searching it want screen locks). English terms are fine only where locals commonly search in English.
- promotionalText: at most 170 characters. Keep it device-neutral like the English (phone, tablet or computer): never name iPhone, iPad, Mac or Android.
- description: at most 4000 characters, plain text. Keep the structure: paragraphs, the UPPERCASE section headings (translated, still uppercase where the script has case) and the • bullets. Keep "${BRAND}", "hYYa" and "Mozilla Public License 2.0" unchanged; "Settings" is the system's own localised name for the Settings app. Stay device-neutral like the English ("your device", "the system"): never name iPhone, iPad, iOS, Mac or Android.
- Never mention other apps or companies, viruses, malware or spyware, and make no ranking claims.
- whatsNew: the release note. Keep its lines: the • bullet line${en.whatsNew?.includes("iPhone Duo") ? ' (keep "iPhone Duo" exactly as written, it\'s the device\'s name)' : ""} and, on the second line, a faithful translation of the fixed sentence "This release contains general bug fixes and stability improvements."
${feedback ? `\nYour previous attempt had these problems; fix all of them:\n- ${feedback.join("\n- ")}\n` : ""}
English listing (JSON):
${JSON.stringify(WHATS_NEW ? { whatsNew: en.whatsNew } : SEARCH_ONLY ? { subtitle: en.subtitle, keywords: en.keywords } : TEXT_ONLY ? { promotionalText: en.promotionalText, description: en.description, whatsNew: en.whatsNew }
  : { subtitle: en.subtitle, keywords: en.keywords, promotionalText: en.promotionalText, description: en.description, whatsNew: en.whatsNew }, null, 1)}`;
}

const schema = WHATS_NEW
  ? { type: "OBJECT", required: ["whatsNew"], properties: { whatsNew: { type: "STRING" } } }
  : SEARCH_ONLY
  ? { type: "OBJECT", required: ["subtitle", "keywords"], properties: { subtitle: { type: "STRING" }, keywords: { type: "STRING" } } }
  : TEXT_ONLY
  ? { type: "OBJECT", required: ["promotionalText", "description", "whatsNew"], properties: {
      promotionalText: { type: "STRING" }, description: { type: "STRING" }, whatsNew: { type: "STRING" } } }
  : { type: "OBJECT", required: ["subtitle", "keywords", "promotionalText", "description", "whatsNew"], properties: {
      subtitle: { type: "STRING" }, keywords: { type: "STRING" }, promotionalText: { type: "STRING" }, description: { type: "STRING" }, whatsNew: { type: "STRING" } } };

async function gemini(text) {
  for (let a = 1; a <= 5; a++) {
    const res = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`, {
      method: "POST", headers: { "Content-Type": "application/json", "x-goog-api-key": KEY },
      body: JSON.stringify({ contents: [{ role: "user", parts: [{ text }] }],
        generationConfig: { temperature: 0.3, responseMimeType: "application/json", responseSchema: schema } }),
    });
    const t = await res.text();
    if (res.ok) return JSON.parse(JSON.parse(t).candidates[0].content.parts.map((p) => p.text).join(""));
    if (a === 5 || ![429, 500, 503].includes(res.status)) throw new Error(`Gemini ${res.status}: ${t.slice(0, 300)}`);
    await new Promise((r) => setTimeout(r, 5000 * a));
  }
}

async function localise(locale) {
  const file = new URL(`${locale}.json`, OUT);
  if (!FORCE && !TEXT_ONLY && !WHATS_NEW && !SEARCH_ONLY && existsSync(file)) return `${locale}: kept`;
  const kept = (TEXT_ONLY || WHATS_NEW || SEARCH_ONLY) && existsSync(file) ? JSON.parse(readFileSync(file, "utf8")) : null;
  let result, issues;
  if (ENGLISH.has(locale)) {
    result = { subtitle: SEARCH_ONLY ? en.subtitle : kept?.subtitle ?? en.subtitle, keywords: SEARCH_ONLY ? en.keywords : kept?.keywords ?? en.keywords,
               promotionalText: WHATS_NEW ? kept?.promotionalText ?? en.promotionalText : en.promotionalText,
               description: WHATS_NEW ? kept?.description ?? en.description : en.description, whatsNew: en.whatsNew };
    issues = check(result);
  } else {
    for (let attempt = 1; attempt <= 4; attempt++) {
      result = await gemini(prompt(LOCALES[locale], issues));
      if (kept) result = WHATS_NEW ? { ...kept, whatsNew: result.whatsNew }
        : SEARCH_ONLY ? { ...kept, subtitle: result.subtitle, keywords: result.keywords }
        : { subtitle: kept.subtitle, keywords: kept.keywords, ...result };
      delete result.locale; delete result.name;
      result.keywords = result.keywords.split(/\s*[,،、，]\s*/).filter(Boolean).join(",");
      issues = check(result);
      if (!issues.length) break;
    }
  }
  if (issues.length) return `${locale}: ✗ ${issues.join("; ")}`;
  if (WHATS_NEW_MAC) result = { ...result, whatsNewMac: result.whatsNew, whatsNew: kept?.whatsNew ?? JSON.parse(readFileSync(new URL("../store/listing-en-US.json", import.meta.url), "utf8")).whatsNew };
  writeFileSync(file, JSON.stringify({ locale, name: BRAND, ...result }, null, 2) + "\n");
  return `${locale}: ✓ ${result.subtitle}`;
}

const wanted = argv.length ? argv : Object.keys(LOCALES);
const queue = [...wanted];
await Promise.all(Array.from({ length: 6 }, async () => {
  while (queue.length) {
    const loc = queue.shift();
    try { console.log(await localise(loc)); } catch (e) { console.log(`${loc}: ✗ ${e.message}`); }
  }
}));
