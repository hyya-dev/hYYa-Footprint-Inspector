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
  - **Keep supporting iOS 26** (owner, 2026-10-21). Before each release, build and run the unit
    tests and a launch check on an **iOS 26.0 Simulator** as well as the latest iOS, so those
    users stay protected. The iOS 26.0 runtime is kept installed on this Mac for that, with this
    project's own Simulator `fi-ios26-iPhone17Pro`. Unit tests use Swift Testing, so read the
    count from the .xcresult (`xcresulttool get test-results summary`); the XCTest log says 0.
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
- **Clean up after every submission** (owner, 2026-10-22): each time a version goes to review
  (Apple or Google), finish by removing local clutter: `build/`, `Android/app/build`,
  `Android/build`, `Android/.gradle`, this project's DerivedData, `.DS_Store` files, scratch
  captures, and the app's test copies on shared Simulators and the borrowed emulator (also clear
  status-bar overrides and emulator demo mode). Keep `.env`, `Android/local.properties`, the
  generated `.xcodeproj` and the `fi-ios26-iPhone17Pro` Simulator. Report the before/after size.
- **Store growth:** use App Store Connect's Custom Product Pages, Asset Library and Product Page
  Optimization wherever possible. Plan: `docs/STORE-GROWTH-PLAN.md`.
- **App Store record:** Apple ID 6824033636, SKU `hyya-footprint-inspector`, created
  2026-10-17.
- **First release is v1.0.0 on every store and platform** (App Store Connect and Google Play
  Console; owner, 2026-10-17). `MARKETING_VERSION` 1.0.0.
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

## macOS (built 2026-10-21; plan in `docs/MACOS-PLAN.md`)
- **Native Mac target** sharing the model, scanner and screens. Same bundle id as iOS, so one App
  Store record and one listing.
- Mac-only readers are in `App/Sources/MacReaders/`, Mac findings in
  `App/Sources/Model/MacSignalCatalogue.swift`, and platform switches use `#if os(macOS)`.
- **A sandboxed Mac app can read, with no prompt:**
  - the serial number and hardware ID (permanent)
  - the full name
  - every installed and running app (no 25-app limit)
  - network hardware addresses, router and DNS
  - drive, USB and sound device names
- **Most System Settings panes open directly** (`x-apple.systempreferences:`), so Mac fixes carry
  a pane id.
- **No "What websites see" on Mac:** a web view needs the network entitlement, and the app holds
  none. Also no Motion, Music or Local Network on Mac.
- **Store screenshots: launch with `-sampleData`** (made-up name, serial number and apps). Never
  publish the owner's real values. Other screenshot switches: `-autoScan`, `-startTab`,
  `-openFinding`, `-sensitiveCategories`, `-openSettings`.

## Android (built 2026-10-21; project in `Android/`)
- Kotlin + Jetpack Compose, Quiet Noir ported. minSdk 33, targetSdk 36, compileSdk 37. Build with
  Android Studio's JBR as `JAVA_HOME`. Upload keystore and its passwords are in the Keys Wallet
  (`hYYa Footprint Inspector Keys/android-signing/`), read by `app/build.gradle.kts`.
- **No INTERNET permission**, no AD_ID, no QUERY_ALL_PACKAGES, no Photos permission (Play
  policy). Sensitive apps use named `<queries>` packages. `allowBackup=false`.
- An Android app reads `ANDROID_ID` (per signing key, survives reinstall), device name and boot
  count with no prompt. Fixes open Settings intents, falling back to the Settings home.
- Store screenshots: launch with the `sampleData` intent extra (also `startTab`, `autoScan`,
  `sensitiveCategories`, `openFinding`).
- Google Play: closed test first (12 testers, 14 days) before production. **Listing changes are
  sent for review automatically**, so every commit of a Play edit is a review submission and
  needs consent. Details: `HANDOFF.md`, `GooglePlayConsole/`.

## Layout
- `project.yml`: XcodeGen spec and the source of truth. The `.xcodeproj` is generated and
  gitignored.
- `App/`: the app (iOS and macOS). `Tests/` iOS unit tests, `TestsMac/` Mac unit tests.
- `Android/`: the Android app. `GooglePlayConsole/`: Play listing, translations, App content.
- `store/`: App Store listing, translations, slides, review notes. `scripts/`: store tooling.
- `docs/`: the plan, research and inventories.
