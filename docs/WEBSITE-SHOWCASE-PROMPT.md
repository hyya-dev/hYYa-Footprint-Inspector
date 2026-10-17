# Prompt for the hyya.com workspace: hYYa Footprint Inspector showcase

Paste everything below the line into the hyya.com workspace.

---

**FROM the hYYa Footprint Inspector workspace.** Please add hYYa Footprint Inspector to hyya.com:
- a home-page presence wherever the other apps appear
- a product page at `hyya-footprint-inspector.html`
- every SEO/AEO file that lists the apps

Follow your own conventions for design, CSS, the served-comment rule, deploy and verification. This
brief gives you the facts, the wording rules and the assets.

**Status:** v1.0.0 was submitted to App Store review on 2026-10-17 and is **not live yet**.
- Build and stage everything now.
- Publish only when the owner says "publish" after Apple approves. Until then the App Store link
  returns 404.
- Per your CLAUDE.md, no "coming soon" or review status goes in served files.

## 1. Facts (verified against the app's code and the store record)

| | |
|---|---|
| Name | **hYYa Footprint Inspector** (always the full name; lowercase h, YY capitals) |
| App Store subtitle | Privacy Checkup & Tracking Fix |
| App Store | https://apps.apple.com/app/id6824033636 (Apple ID 6824033636, bundle `com.hyya.footprintinspector`) |
| Platforms | iPhone and iPad (one App Store app). macOS and Android are planned but **must not be mentioned** |
| Category | Utilities (schema.org `UtilitiesApplication`) |
| Price | Free. No in-app purchases, no subscription, no ads. Per your rule, print no figures; "Free" is fine |
| Account | None. No sign-up, no server, no analytics, no third-party code |
| Data | App Store label **"Data Not Collected"**. Nothing the app reads ever leaves the device |
| Open source | Mozilla Public License 2.0. Source: https://github.com/hyya-dev/hYYa-Footprint-Inspector (public). Link it; "anyone can read the code to check" is true |
| App language | English (the store listing is in 50 languages) |
| Privacy policy | https://hyya.com/privacypolicy/hyya-footprint-inspector.html (live; stays noindex) |
| Support | https://hyya.com/#contact |

## 2. What the app does (use these facts; the wording is yours)

**One line:** see what any app can learn about your device, and how to hide it.

**The problem:**
- Every app can quietly read dozens of details without asking. Examples: when the device was set
  up (to the second), when it last restarted, free space to the byte, your headphones' name (which
  often contains your first name), your languages and keyboards.
- Each detail looks harmless. Combined, they work as a **device fingerprint** that can recognise
  you across apps.
- Grant a permission and an app sees far more.
- Any app can also ask whether specific apps are installed, and the answer can reveal your dating
  life, your health, your faith or your money.

**Features:**
1. **Scan.** Reads the device details any app can read without asking: nearly 50 signals, grouped
   by what they reveal. It gives a calm **footprint score out of 100** that counts only what you
   can change.
2. **Every clue explained.** For each one: what an app learns, why the system allows it, and how
   long it lasts.
3. **A fix for each finding**, at one of four levels:
   - one tap inside the app
   - a jump to the right Settings screen
   - a few simple steps
   - an honest "only Apple can fix this"
4. **What apps see once you say yes.** Ten permissions: Location, Photos, Contacts, Calendars,
   Reminders, Camera, Bluetooth, Local Network, Motion & Fitness, Media & Apple Music.
   - Tap one to see exactly what an app would get.
   - The app asks only when you tap "Show me", never on launch.
   - It shows counts and summaries, never names, numbers, messages or event titles.
5. **Which apps give you away.** The user picks which of nine sensitive categories to check: dating,
   religion and faith, health and fertility, addiction and recovery, VPN and censorship tools,
   private messaging, crypto and gambling, job hunting and workplace, politics and news.
   - All categories are off until switched on.
   - Results are blurred until tapped, cleared on leaving, and never saved.
   - The system caps this at 25 named apps.
6. **Guided permission check-up.** The system never tells one app which other apps can reach your
   Health data, location or photos; only Settings knows. A 12-step walk through Settings covers it,
   starting with Safety Check.
7. **Keep track.**
   - Scan again to see before and after.
   - Scan history stays on the device: scrambled markers only, never the values, and excluded from
     backups.
   - A scoreboard shows what Apple has fixed in each system release.
   - A share card holds your score and none of your details.
8. **The detective.** A blue furry mascot lives on every page. He leans when you tilt the device and
   gives a tip when tapped.

**Tone:** calm and plain. Concerning findings are clearly flagged, but never alarmist and never hype.
Use "could" and "can", not "will".

## 3. Wording rules (hard)

- ⛔ Never call it a spyware, malware, virus or antivirus scanner, or say it "detects tracking apps".
  It shows what apps *can* read. (Apple Guideline 2.3.1 calls virus and malware scanner claims on
  iOS misleading.)
- ⛔ Never name or compare with another privacy app or its developer. In particular, never "Loupe"
  or "Mysk".
- ⛔ Don't list the individual apps the sensitive check looks for (they are third-party trademarks).
  Name the **categories** only.
- ⛔ **Don't use "LGBTQ+".** Say "dating apps". The owner chose this because the term is banned in
  some countries.
- ⛔ Don't claim it can see which apps hold a permission. It can't; that's why the check-up exists.
- ⛔ Don't claim it lists all installed apps. No app can; it asks about specific ones (up to 25).
- ⛔ Don't print a minimum system version.
- ⛔ Don't promise one-tap fixes for everything. Many items are "only Apple can fix".
- Keep claims identical to the live privacy policy. Where you're unsure, the policy and this brief
  win.

## 4. Search and answer-engine targets

**Primary phrases** (organic research, 2026-10-17; winnable, low competition):
- privacy checkup / privacy check
- what apps can see / what apps know about me
- device fingerprinting / device fingerprint
- digital footprint
- app permissions checker
- privacy scanner / privacy audit / privacy score

**Avoid:** "tracker detector" and "who is tracking me". Those searches mean AirTag and stalkerware
detection, which is the wrong intent.

**Suggested title (≤60 characters):**
"hYYa Footprint Inspector — See What Apps Know About You"

**Suggested meta description (≤155 characters):**
"Free privacy checkup that shows what any app can learn about your iPhone or iPad — and how to
hide it. Open source. Nothing leaves your device."

**FAQ (FAQPage JSON-LD plus visible FAQ).** Answer each in one or two plain sentences, answer first:
1. What can apps learn about my iPhone without asking?
2. What is device fingerprinting?
3. Can an app see which other apps I have installed?
4. Can apps learn my name from my headphones?
5. Can hYYa Footprint Inspector see which apps have access to my Health data or location?
   - No. Only Settings knows; the guided check-up walks you through it.
6. Is it a spyware or virus scanner?
   - No. It shows what any app can read, and how to reduce it.
7. Does it collect or send any of my data?
   - No: Data Not Collected, no account, no server.
8. Why does it ask for permissions?
   - Only when you tap "Show me", to show you what an app would get.
9. Is it free and open source?
   - Yes, under MPL 2.0, with a link to the source.

**`llms.txt` entry** (keep the facts dense; add ⛔ lines for the wording rules above):
- free, open-source privacy inspector for iPhone and iPad
- shows what any app can read without asking (device fingerprint), what each permission exposes,
  and which sensitive app categories can be detected
- a fix for each finding
- Data Not Collected; no account; MPL 2.0 with the GitHub link
- ⛔ not a malware/spyware scanner
- ⛔ can't see other apps' permissions or list all installed apps

Also update the site tagline that lists what hYYa spans ("spiritual wellness, expense tracking,
private AI…") to include **privacy inspection**.

## 5. Where it must appear (mirror the existing apps)

**`index.html`:**
- the Organization graph's `SoftwareApplication` entry: `UtilitiesApplication`, operatingSystem
  "iOS, iPadOS", Offer price 0
- the app card, with its own accent (see §6)
- the goal picker card ("You want to know what your apps can see about you")
- the "best for" answer card (`#hyya-footprint-inspector-best-for`)
- an FAQ entry
- the app buttons row
- the footer link
- the intro sentence listing what visitors compare: add "privacy checkups"

**The new product page:**
- `<title>`, meta description, canonical, hreflang `en`, Open Graph and Twitter card
- `MobileApplication` and `FAQPage` JSON-LD, Offer price 0, `sameAs`/`codeRepository` → GitHub
- sections for the problem, the 8 features, privacy, open source and the FAQ
- links to the privacy policy and the App Store
- optional: a Smart App Banner, `<meta name="apple-itunes-app" content="app-id=6824033636">`, only
  if it fits your conventions

**Site-wide files:**
- `sitemap.xml`, `llms.txt`, `llms-full.txt` (full section)
- `use-cases.html` (privacy use cases)
- `feed.xml` (a launch item, on publish)
- `images/app-icons/` (avif and webp, as the others)
- `images/og/hyya-footprint-inspector-og.png`
- `HANDOFF.md` per-app rules
- `directives/page-maintainer-notes.md`

## 6. Look and assets

The app's look is **"Quiet Noir"**, and the page should feel like the app:
- black ground and near-black panels
- hairline sand-brown borders
- **sand accent `#D2AE88`**, borders `#8F7560`
- coral `#EC7F6A` for "worth a look", green `#7CD9A8` for fixed
- white primary button with black text
- almost no glow

Use sand as the card accent on the home page.

Assets, all in the app repo `/Users/hyya/development/hYYa Footprint Inspector` (read-only for you):

| Asset | Path |
|---|---|
| App icon (1024) | `App/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png` |
| Mascot cut-out (transparent) | `App/Resources/Assets.xcassets/MascotCutout.imageset/mascot-cutout.png` |
| Wide hero banner (21:9) | `store/creative/header-3840x1646.png` |
| Product shot, three phones (3:2) | `store/creative/search-results-3840x2560.png` |
| iPhone screenshots (7) | `store/slides/iphone-6.9/01…07.png` |
| iPad screenshots (7) | `store/slides/ipad-13/01…07.png` |
| Social image (1280×640, good OG base) | `docs/images/social-preview.png` |
| README hero | `docs/images/readme-hero.jpg` |

## 7. When you're done

Reply with:
- the staged page path
- every file you touched
- the visible text of the new page and home-page additions, so this workspace can check them
  against the code

Publish only on the owner's "publish".
