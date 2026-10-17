# CLAUDE.md — hYYa Footprint Inspector

Durable project context. For where the work is right now, see `./HANDOFF.md`.

## What it is
A free, open-source iPhone app that shows people what any app can learn about their device and
about them, then helps them fix it. It covers:
- passive fingerprinting signals, which any app can read without asking
- everything an app can see once a permission is granted
- the sensitive inferences a tracker can draw (for example from which apps are installed)

Every finding comes with a calm explanation and a fix, where one exists.

Sibling projects: `../hYYa-Encrypted-Notes` and `../hYYa-Encrypted-Folder` are the reference for
conventions: XcodeGen, Liquid Glass, design layer, Settings layout and release flow. When unsure,
look there first. They are read-only from here.

## Standing decisions (owner, 2026-10-17). Don't re-ask
- **Our own code and our own words.** Loupe (Mysk, github.com/mysk-research/loupe) is the
  reference for *which* signals exist. **Copy none of its code, strings or explanations, and
  don't credit or mention it in the app.** Its branding is reserved anyway.
- **Licence: MPL 2.0.** It is share-alike at the file level and compatible with the App Store.
  Changes to our files must stay open.
- **Free.** No IAP, no ads, no subscription, no analytics, no accounts, no server. Nothing leaves
  the phone.
- **Platforms, in order:** iOS (and iPadOS) → macOS → Android. **Minimum iOS 26.**
- **English only** at launch. Keep strings in String Catalogs so adding languages later is cheap.
- **Scope:** sensitive checks included, plus everything an app can be granted permission to read,
  "to open the eyes of the user".
- **Tone:** calm, with concerning findings clearly flagged. Never alarmist, never hype.
- **Fixes:** every finding gets a fix level:
  1. one tap inside our app
  2. one tap to the right Settings screen
  3. guided steps
  4. only Apple can fix

  Fixes may suggest a hYYa app where it genuinely helps. Which app goes with which finding is
  decided case by case, later.
- **Settings screen:** same layout as Encrypted Notes:
  - **Support hYYa:** Share, Rate the App, Contact hYYa, Privacy Policy, Report a Security Issue
  - **More from hYYa**
- **Installed-app checks:** cover the most sensitive apps, grouped by category. The user picks
  which categories to scan. See `docs/SENSITIVE-APP-CATALOGUE.md`.
- **Subtitle / ASO:** decided at the store-listing stage, not before.
- **🚨 Never submit for review without the owner's explicit consent** (Apple or Google; a
  version, a build, a custom product page or a PPO test). Prepare everything up to the submit
  button, then ask, naming exactly what would be submitted.
- **Store growth:** use App Store Connect's Custom Product Pages, Asset Library and Product Page
  Optimization wherever possible. Plan: `docs/STORE-GROWTH-PLAN.md`.
- **App Store record:** Apple ID 6824033636, SKU `hyya-footprint-inspector`, created
  2026-10-17.
- **Mascot:** a blue furry detective in a fedora, round glasses and trench coat, studying a
  footprint with a magnifier and a brush. It was changed by the owner on 2026-10-17.
  - Source: iCloud Drive `hYYa HD/hYYa Apps/hYYa.com UI/Mascots/hYYa Footprint Inspector.jpg`.
  - The cut-out (`MascotCutout`) was made with Vision subject lifting.
- **Look: "Quiet Noir"** (owner, 2026-10-17, after several rejected rounds):
  - Black ground, a quiet near-black panel, and hairline borders and separators.
  - The accent is the footprint's sand-brown (#D2AE88; borders use #8F7560).
  - Coral (#EC7F6A) means "worth a look", green means fixed.
  - The primary button is white with black text. There's almost no glow.
  - The mascot is on every page. The app is dark only.
  - Rejected looks, so don't repeat them: magenta/violet; full neon glow; boxy cards inside boxes;
    rounded "playful" type.

## Platform facts that shape the product (verified 2026-10-17)
- **No iOS app can list installed apps.** It can only ask about URL schemes it declares in
  `LSApplicationQueriesSchemes`. The cap is **50, or 25 for apps built with the iOS 27 SDK**.
  This Mac has **only Xcode 27.1**, so our builds are on the 27 SDK and **25 is the working
  limit**.
- **No iOS app can see which other apps hold a permission** (Health, Location, Photos…). Only
  Settings knows. We cover this with a guided permission check-up, not a scan.
- **Officially, an app can only open its own Settings page.** Deep links into other Settings
  panes are unofficial; see `docs/SETTINGS-LINKS.md` for what was tested.

## Layout
- `project.yml`: XcodeGen spec and the source of truth. The `.xcodeproj` is generated and
  gitignored.
- `App/`: the iOS app.
- `docs/`: the plan, research and inventories.
