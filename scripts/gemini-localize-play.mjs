#!/usr/bin/env node
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// Localises the approved English Play listing (GooglePlayConsole/listing-en-US.md) into every
// Google Play language with Gemini, writing GooglePlayConsole/localized/<play code>.json. Each
// result is checked against Play's limits and our wording rules; failures are retried with the
// reasons, then reported. Languages that share a translation (English variants, Persian variants…)
// are copied from their source rather than translated twice.
//
//   node scripts/gemini-localize-play.mjs [play code …] [--model name] [--force]
//
// The key comes from GEMINI_API_KEY in the environment or in the gitignored .env file.

import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";

const argv = process.argv.slice(2);
const opt = (name, fallback) => { const i = argv.indexOf(name); return i >= 0 ? argv.splice(i, 2)[1] : fallback; };
const MODEL = opt("--model", "gemini-3.7-flash");
const FORCE = argv.includes("--force");
if (FORCE) argv.splice(argv.indexOf("--force"), 1);
const envFile = new URL("../.env", import.meta.url);
const KEY = process.env.GEMINI_API_KEY || (existsSync(envFile) ? (readFileSync(envFile, "utf8").split("\n")
  .find((l) => l.startsWith("GEMINI_API_KEY=")) ?? "").slice(15).trim() : "");
if (!KEY || KEY.startsWith("PASTE_")) { console.error("Add GEMINI_API_KEY to .env first"); process.exit(1); }

const md = readFileSync(new URL("../GooglePlayConsole/listing-en-US.md", import.meta.url), "utf8");
const section = (name) => md.split(`## ${name}\n`)[1].split("\n## ")[0].trim();
const BRAND = section("App name (30)");
const en = { shortDescription: section("Short description (80)"), fullDescription: section("Full description (4000)") };
const OUT = new URL("../GooglePlayConsole/localized/", import.meta.url);
mkdirSync(OUT, { recursive: true });

// 🚨 Play's codes, not the App Store's: a wrong code is accepted and makes a listing nobody sees.
export const LANGUAGES = {
  af: "Afrikaans", am: "Amharic", ar: "Arabic", "az-AZ": "Azerbaijani", be: "Belarusian",
  bg: "Bulgarian", "bn-BD": "Bengali", ca: "Catalan", "cs-CZ": "Czech", "da-DK": "Danish",
  "de-DE": "German", "el-GR": "Greek", "es-419": "Spanish (Latin America)", "es-ES": "Spanish (Spain)",
  et: "Estonian", "eu-ES": "Basque", fa: "Persian", "fi-FI": "Finnish", fil: "Filipino",
  "fr-CA": "French (Canada)", "fr-FR": "French (France)", "gl-ES": "Galician", gu: "Gujarati",
  "hi-IN": "Hindi", hr: "Croatian", "hu-HU": "Hungarian", "hy-AM": "Armenian", id: "Indonesian",
  "is-IS": "Icelandic", "it-IT": "Italian", "iw-IL": "Hebrew", "ja-JP": "Japanese", "ka-GE": "Georgian",
  kk: "Kazakh", "km-KH": "Khmer", "kn-IN": "Kannada", "ko-KR": "Korean", "ky-KG": "Kyrgyz",
  "lo-LA": "Lao", lt: "Lithuanian", lv: "Latvian", "mk-MK": "Macedonian", "ml-IN": "Malayalam",
  "mn-MN": "Mongolian", "mr-IN": "Marathi", ms: "Malay", "my-MM": "Burmese", "ne-NP": "Nepali",
  "nl-NL": "Dutch", "no-NO": "Norwegian (Bokmål)", pa: "Punjabi (Gurmukhi)", "pl-PL": "Polish",
  "pt-BR": "Portuguese (Brazil)", "pt-PT": "Portuguese (Portugal)", rm: "Romansh", ro: "Romanian",
  "ru-RU": "Russian", "si-LK": "Sinhala", sk: "Slovak", sl: "Slovenian", sq: "Albanian",
  sr: "Serbian (Cyrillic)", "sv-SE": "Swedish", sw: "Swahili", "ta-IN": "Tamil", "te-IN": "Telugu",
  th: "Thai", "tr-TR": "Turkish", uk: "Ukrainian", ur: "Urdu", vi: "Vietnamese",
  "zh-CN": "Chinese (Simplified)", "zh-HK": "Chinese (Traditional, Hong Kong)",
  "zh-TW": "Chinese (Traditional, Taiwan)", zu: "Zulu",
};
// Same text as another language: copied, not translated again.
export const COPIES = {
  "en-AU": "en-US", "en-CA": "en-US", "en-GB": "en-US", "en-IN": "en-US", "en-SG": "en-US", "en-ZA": "en-US",
  "es-US": "es-419", "ms-MY": "ms", "fa-AE": "fa", "fa-AF": "fa", "fa-IR": "fa",
};
// "Phone" in the languages where Gemini reached for it: the listing serves tablets too.
const PHONE = /phone|mobile|smartphone|móvil|mòbil|móbil|celular|telemóvel|telefon|телефон|смартфон|फ़ोन|फोन|ফোন|ફોન|ਫ਼ੋਨ|ਫੋਨ|ఫోన్|ಫೋನ್|ഫോൺ|فون|موبایل|گوشی|هاتف|جوال|טלפון|ስልክ|手机|手機|携帯|スマホ|휴대폰|스마트폰|điện thoại|โทรศัพท์|ဖုန်း|foon|cellulare/i;
const BANNED = /spyware|malware|anti-?virus|\bvirus\b|#\s*1|\bbest\b/i;

function check(l) {
  const issues = [];
  const len = (s) => [...(s ?? "")].length;
  if (!l.shortDescription || len(l.shortDescription) > 80) issues.push(`shortDescription is ${len(l.shortDescription)} characters (max 80)`);
  if (!l.fullDescription || len(l.fullDescription) > 4000) issues.push(`fullDescription is ${len(l.fullDescription)} characters (max 4000)`);
  for (const f of ["shortDescription", "fullDescription"]) {
    if (/\b(?:iphone|ipad|ios|macos|mac)\b/i.test(l[f] ?? "")) issues.push(`${f} must not name an Apple device or system`);
    if (PHONE.test(l[f] ?? "")) issues.push(`${f} says "${l[f].match(PHONE)[0]}": use the neutral word for "device" instead`);
    if (BANNED.test(l[f] ?? "")) issues.push(`${f} uses a banned word (${l[f].match(BANNED)[0]})`);
  }
  if (!l.fullDescription?.includes(BRAND)) issues.push(`fullDescription must keep the name "${BRAND}" untranslated`);
  if (!l.fullDescription?.includes("Mozilla Public License 2.0")) issues.push(`fullDescription must keep "Mozilla Public License 2.0" unchanged`);
  return issues;
}

function prompt(language, feedback) {
  return `You localise Google Play store listings. Localise this approved English listing for a free, open-source privacy app into ${language}, for people searching Google Play in that language.

Rules:
- Natural, native wording; calm and plain, never alarmist or hyped. Not a word-for-word translation.
- Google Play search reads the full description, so use the local everyday terms people really search for: privacy check, app permissions, device fingerprint, digital footprint, trackers. Let them appear naturally a few times; no keyword stuffing.
- shortDescription: at most 80 characters. Same message as the English: see what apps know about your device, then fix it; free, open source, private.
- fullDescription: at most 4000 characters, plain text. Keep the structure: paragraphs, the UPPERCASE section headings (translated, still uppercase where the script has case) and the • bullets. Keep "${BRAND}", "hYYa" and "Mozilla Public License 2.0" unchanged. "Settings" is the system's own localised name for the Settings app. Keep "Android" and "Google" where the English has them, but never name iPhone, iPad, iOS or Mac.
- Stay device-neutral: the listing is for phones and tablets alike, so say "device" (the local neutral word) wherever the English says "device". Never write "phone", "mobile", "smartphone", "cell" or "tablet".
- Never mention other apps or companies (other than Google and Android as in the English), viruses, malware or spyware, and make no ranking claims.
${feedback ? `\nYour previous attempt had these problems; fix all of them:\n- ${feedback.join("\n- ")}\n` : ""}
English listing (JSON):
${JSON.stringify(en, null, 1)}`;
}

const schema = { type: "OBJECT", required: ["shortDescription", "fullDescription"], properties: {
  shortDescription: { type: "STRING" }, fullDescription: { type: "STRING" } } };

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

const write = (code, l) => writeFileSync(new URL(`${code}.json`, OUT),
  JSON.stringify({ language: code, title: BRAND, shortDescription: l.shortDescription, fullDescription: l.fullDescription }, null, 2) + "\n");

async function localise(code) {
  if (!FORCE && existsSync(new URL(`${code}.json`, OUT))) return `${code}: kept`;
  let result, issues;
  for (let attempt = 1; attempt <= 4; attempt++) {
    result = await gemini(prompt(LANGUAGES[code], issues));
    issues = check(result);
    if (!issues.length) break;
  }
  if (issues.length) return `${code}: ✗ ${issues.join("; ")}`;
  write(code, result);
  return `${code}: ✓ ${result.shortDescription}`;
}

const wanted = argv.length ? argv.filter((c) => LANGUAGES[c]) : Object.keys(LANGUAGES);
const queue = [...wanted];
await Promise.all(Array.from({ length: 6 }, async () => {
  while (queue.length) {
    const code = queue.shift();
    try { console.log(await localise(code)); } catch (e) { console.log(`${code}: ✗ ${e.message}`); }
  }
}));

// Copies, once their source exists.
for (const [code, from] of Object.entries(COPIES)) {
  if (argv.length && !argv.includes(code) && !argv.includes(from)) continue;
  if (from === "en-US") { write(code, en); console.log(`${code}: = en-US`); continue; }
  const src = new URL(`${from}.json`, OUT);
  if (!existsSync(src)) { console.log(`${code}: ✗ waiting for ${from}`); continue; }
  write(code, JSON.parse(readFileSync(src, "utf8")));
  console.log(`${code}: = ${from}`);
}
