# HANDOFF: where the work is

## Now (2026-10-23): iOS v1.0.0 is on the App Store; macOS is waiting for review

| Store | What | State |
| --- | --- | --- |
| App Store, iOS/iPadOS | v1.0.0 (build 13) | **On sale** since 2026-10-23 08:31 UTC (approved, released automatically). https://apps.apple.com/app/id6824033636 |
| App Store, macOS | v1.0.0 (build 13) | Waiting for review (submitted by the owner 2026-10-22). |
| Google Play, closed testing (alpha) | 1.0.0 (versionCode 7) | **Live** to closed testers since 2026-10-22. Production: apply after 14 days of 12+ testers (around 2026-11-04). |
| Google Play, listing | 79 localised listings, 7 slides in the iOS order | **Live** since 2026-10-22. |

- hyya.com: switched to the live App Store link on 2026-10-23. Changed: the product page (badge,
  Smart App Banner, structured data), the home card and FAQ, llms.txt, llms-full.txt and the
  sitemap. Mac and Android still say "coming soon".
  - 🔔 Tell the hyya.com workspace when Apple approves the Mac version.
  - 🔔 Tell them again when Android goes live in production on Google Play.
- ASC builds 1–12 are expired; build 13 is live on both platforms.

## Next: v1.0.1 to-do (agreed with the owner 2026-10-23)

▶ **iOS 1.0.1 (14) built and uploaded to TestFlight on 2026-10-24** (the owner asked to go ahead
before the macOS verdict). Waiting for the owner's Duo test. macOS and Android 1.0.1 come after
macOS 1.0.0 is approved. Android 1.0.1 goes to closed testers. 🚨 Nothing is submitted, iOS, macOS
or Play, without the owner's consent.

**Done in iOS 1.0.1 (14):**
- First page: one privacy score (the average of the checks done) and the four checks as cards.
- Plain headline and one line for every iPhone finding (`PlainWords.swift`); the longer text sits
  under "More about this".
- Restart rewrite.
- Check-up: keep the system updated, restart weekly, leaked passwords, protection from targeted
  spyware.
- Duo:
  - named pages on wide screens (`.sidebarAdaptable`)
  - icons on Close and Done
  - Fix buttons pinned at the bottom, side by side when sideways
  - Check-up list and detail when open
  - landscape allowed on iPhone
  - no faded cards; top fade only under a top clock

**How it was checked:**
- Code reading.
- Simulator, folded `fi-iPhone-Duo`: 24 unit + 8 flow tests. The flow tests include every Close
  and Done tapped upright and sideways; the Close button was broken once on purpose and the test
  caught it.
- Same tests on an iPhone 17 Pro (27.0) and on iOS 26.0.
- iPad wide layout reviewed.
- Mac: builds, 5 tests pass.
- Not yet: Device Hub open poses, or the owner's Duo.

**App Store Connect, iOS 1.0.1 (prepared 2026-10-24, NOT submitted):**
- Version 1.0.1 is created with **build 15** attached (replacing 14) and releases automatically
  after approval.
- Build 15 carries the owner's 2026-10-24 fixes:
  - the restart fix leads with "Restart once a week"
  - hide-and-lock comes first for apps that give you away
  - Settings search hints (no link can open a specific Settings page on iOS 27.x; re-tested on
    27.1)
  - "Analyze my report"
  - real app names in Tracker, from an offline list of 9,295 App Store chart apps
    (`scripts/build-app-names.mjs`)
- App icons would need an online lookup; the owner hasn't decided yet.
- English and 49 languages: description, promotional text and What's New. What's New reads
  "• Now made for iPhone Duo." above the fixed sentence (owner's rule). Subtitles and keywords
  were kept.
- Reviewer notes are 3,994 of 4,000 characters.
- Slides: 7 iPhone, 7 iPad, and 7 **landscape** iPhone Duo slides (open screen, 2853×2007, side
  strip of pages in view) in set `APP_IPHONE_DUO`.
  - They were captured in one Device Hub sitting (2026-10-24) with `scripts/capture-duo.sh … inner`
    and laid out by `scripts/make-landscape-slides.py`.
- The owner tested build 15 on their Duo through TestFlight on 2026-10-24: passed.
- `scripts/asc-audit-version.mjs`: all checks pass.
- `scripts/asc-audit-version.mjs` passes every check.
- New scripts: `asc-prepare-version.mjs` and `asc-audit-version.mjs`. The listing scripts carry
  What's New and skip app info that's locked while macOS is in review.
- 🚨 Waiting on: the owner's Duo test of build 14, then the owner's go-ahead to submit. After the
  iOS submission: Android 1.0.1 to closed testers. macOS stays on hold until 1.0.0's verdict.

**Still to do for 1.0.1 (later):** Mac plain words for Mac findings, and the Mac and Android ports.

**Where the issues came from:**
- **Friends and family**, on ordinary non-folding iPhones: they stay on the first page, the
  words are too technical, the restart line is unclear, two scores confuse them, and three
  questions (below).
- **My own checks on the owner's Duo**: the owner's Duo screenshots and the `fi-iPhone-Duo`
  Simulator.

1. **First page shows the whole check** (friends): one overall privacy score from all four checks
   (Footprint, Sensitive apps, Tracker, Check-up). The four steps sit there as cards that tick off
   as each is done, leading people on. Only one score at the top. The clue ring moves down into
   the clue list.
2. **Plain words** (friends): every finding becomes a one-line headline plus one short sentence.
   This covers the iOS catalogue (about 48), Mac (32) and Android. For example: "Apps can tell
   when you last restarted" / "That exact moment is rare, so apps can use it to recognise you."
   Also apply the unified severity words (already committed, 25ca9a5).
3. **Restart, said clearly** (friends): "Restart once a week. It's worth it: apps can no longer
   link you by your last restart time, and it also clears some kinds of spyware that only live
   in memory." Apply to `Fix.restart` and the boot-time and copy-counter findings.
4. **New Check-up steps** (friends' questions, answered as guided steps, never as antivirus):
   - Spyware: Lockdown Mode, keep the system updated, restart weekly, Apple threat
     notifications, device-management profiles you don't recognise.
   - Leaked passwords: Apple Passwords' warning about passwords found in known leaks (on Android,
     Google Password Checkup). Nothing is sent from our app.
   - Not doing: antivirus scanning or Moonlock (not possible, and against our offline design).
5. **Duo layout** (my checks; full plan in `docs/DUO-PLAN.md`: labelled sidebar when open, list and
   detail side by side, laptop pose, buzz the owner for every rotation or fold):
   - Pages show by name, not just an icon, in the Duo's side rail.
   - In "Fix them with me", the main button sits fully on screen when folded (FlowCheckUITests
     currently fails here).
   - The Back button on Check-up steps stays clear of the clock and status icons.
   - Cards no longer fade to 55% near the screen edge (`scrollIn3D` opacity).
   - Check folded, open, portrait and landscape.
6. **Port to Android and Mac**: the same first page, words and Check-up steps (Android uses
   Settings intents; Mac uses System Settings panes).
7. **Verify**:
   - Unit tests on iOS 27 and 26.0, Mac and Android.
   - FlowCheckUITests on `fi-iPhone-Duo` and a regular iPhone.
   - My own screenshot review of every flow.
8. **Store** (Duo screenshots, outer and inner screens, are required from April 2027): refresh the slides that show the first page or findings, and the copy that
   mentions the score, for App Store, Mac and Play. Translate with Gemini after the owner approves
   the English.
9. **Ship**:
   - TestFlight (iOS and Mac). The owner tests on the Duo.
   - Prepare the 1.0.1 versions and the Play closed-test edit, then ask before submitting.
10. **After submitting**: expire old builds, clean up local clutter, and tell hyya.com what's new.

🚨 Nothing goes to review (Apple or Google) without the owner's explicit consent. Releases are
always set to release automatically after approval.

### 2026-10-22: build 13 prepared and submitted
- iOS and macOS v1.0.0 were pulled from review by the owner for the new features (Tracker, Fix them
  with me, rings, five-step flow, plain-language findings). Build 13 is attached to both, with the new
  English copy, 49 translations, reviewer notes and slides (7 iPhone, 7 iPad, 6 Mac) uploaded.
- 🚨 The owner reorders the slides in App Store Connect and submits both versions themselves.
- 2026-10-22: the owner submitted iOS and macOS build 13 (waiting for review). Android versionCode 7,
  the new listing (79 languages; fa ×4, hi-IN, my-MM, nl-NL and te-IN show English) and 7 slides
  in the iOS order were sent for Google's review with the owner's consent (edit 00284048839385647342) and went live to closed testers the same day.

- hyya.com: the four-steps update went live on 2026-10-22 (product page, home card, FAQ, use
  cases, llms.txt, llms-full.txt, privacy policy section 4 and 7). 5 iPhone and 4 Mac screenshots,
  no sensitive-apps, iPad or Android slides. Status stays "coming soon" until each review verdict.
- Next build carries the unified severity words (Worth a look / Worth knowing / Minor).

### Google Play facts (verified 2026-10-21)
- Personal account "hYYa LLC", id 7244268045893720931, signed in at Play Console `u/1`. App id
  4973134500799616661, package `com.hyya.footprintinspector`.
- Service account `play-supply-hyya@…` has Admin on the app. Key:
  `H-iCloud Drive/hYYa HD/Keys Wallet/hYYa Footprint Inspector Keys/google-play/play-service-account.json`
  → `PLAY_SERVICE_ACCOUNT_JSON`. Every key this project uses is in that vault folder (see CLAUDE.md).
- **Closed test:** Google Group `testers-community@googlegroups.com` (the same group as hYYa
  Encrypted Folder), feedback to h@hyya.com, all 178 countries/regions.
  - Testers join at https://play.google.com/apps/testing/com.hyya.footprintinspector
  - **Production access needs 12 opted-in testers for 14 days**, then an "Apply for production"
    questionnaire in the dashboard.
- **Listing changes are sent for review automatically:** Play refuses `changesNotSentForReview`
  now that the app is live. So `scripts/play-push-listings.mjs --apply` is a review submission,
  and needs consent. Without `--apply` it rehearses and discards.
- Play does not inherit images from the default language. Every language gets the English gallery
  (slides stay English).
- App content answers: `GooglePlayConsole/app-content.md`. Listing source:
  `GooglePlayConsole/listing-en-US.md`, translations in `GooglePlayConsole/localized/`
  (`scripts/gemini-localize-play.mjs`).
- Play Console in the built-in browser: labels inside `simple-html` are often blank in
  `innerText`. Read `textContent`, and click Material checkboxes with dispatched mouse events.

### iOS 26 check
- **2026-10-21, iOS 26.0 (23A343) Simulator, iPhone 17 Pro, the build in review:** builds, 14/14
  unit tests pass, and the app launches. A sample-data scan finishes (score 64, 46 readings, 5
  worth a look), and Scan, Sensitive apps, Check-up and Settings all draw correctly. ✅

### Owed
- **Closed test:** 12+ testers opted in (dashboard ✓, 2026-10-21). The 14-day run ends around
  **2026-11-04**; then "Apply for production" in the dashboard, whose questionnaire needs owner
  answers. 🚨 The production release is a review submission: owner consent first.
- **Owner:** will forward the Apple review verdicts (iOS, macOS) as they arrive.
- **After Play production:** a hyya.com brief to add the Google Play badge/link to the app page.
- **Device tests** still open from the original plan (see `docs/DEVICE-TEST-LOG.md`).
- **Polish, not blocking:** a proper Icon Composer icon and PPO alternates; App Accessibility
  declarations after a VoiceOver and large-text pass; an app preview video.

---

## History

**2026-10-17: Store setup started (App Store Connect app 6824033636, version 1.0.0, "Prepare for
Submission"). 🚨 Nothing has been submitted, and nothing will be without the owner's explicit
consent.**

Done in App Store Connect:
- **Bundle ID:** registered.
- **App record:** created, SKU `hyya-footprint-inspector`.
- **Version:** renamed 1.0 → 1.0.0.
- **Listing:** name, subtitle ("Privacy Scan: What Apps Know"), keywords, description, promo text,
  support, marketing and privacy URLs, copyright. Source of truth is `store/listing-en-US.json`;
  push it with `scripts/asc-fill-listing.mjs`.
- **Categories:** Utilities / Developer Tools.
- **Age rating:** all "none", which gives 4+.
- **Reviewer contact and notes:** notes in `store/review-notes.txt`; the contact is copied from
  hYYa Encrypted Notes.
- **App Privacy:** published as "Data Not Collected".
- **Price and availability:** free, in all 175 territories plus new ones.
- **Content rights:** no third-party content.
- **App:** `MARKETING_VERSION` 1.0.0 and `ITSAppUsesNonExemptEncryption` NO.

Still blocking submission:
1. **Privacy policy page** on hyya.com (brief delivered; in git history). The URL
   is set but 404s.
2. **GitHub repo is private.** The listing, Settings and policy all say "open source", so it must
   be public before launch. Owner decision.
3. ~~Screenshots~~ **Done 2026-10-17.** Seven slides each for 6.9″ iPhone and 13″ iPad
   (`store/slides/`), built by `scripts/make-store-slides.py` from Simulator captures
   (`UITests/StoreScreenshotsUITests.swift`) and uploaded by `scripts/asc-upload-screenshots.mjs`.
   They're in the Asset Library, which also holds 7 stale iPhone assets from the first upload. An
   app preview video is still to do.
4. ~~Release build~~ **Done.** 1.0.0 (1) uploaded with `scripts/testflight-upload.sh` and
   attached to version 1.0.0.
   - Signing is manual: the local Apple Distribution certificate plus the profile "hYYa Footprint
     Inspector App Store". The API key has no cloud-signing permission.
   - The next upload must bump `CURRENT_PROJECT_VERSION`.
5. **App icon.** The current one is the mascot JPG. A proper Icon Composer icon (and PPO
   alternates) is recommended.
6. **App Accessibility** declarations, after a VoiceOver and large-text pass.
7. **The hyya.com showcase page and universal links** for custom product pages. Brief owed
   later.

---


**2026-10-17: Phase 3 built, not committed.** It builds, all 14 unit tests pass, and it was
checked in the iOS 26.4 Simulator in light and dark mode.

What Phase 3 added:
- **Design layer:** `App/Sources/UI/Brand.swift`, with colours from the mascot. Blue is the accent,
  cyan the glow, amber means "worth a look", green means fixed. Includes the Auto/Light/Dark theme,
  cards, CTA and ghost buttons, haptics and the mascot emblem.
- **Footprint score:** 0–100, in `Scanner/FootprintScore.swift`. Only fixable findings count: 10
  points for a high one, 2 for a medium one. Readers lower a signal to "low" when it's at its
  ordinary default. Things only Apple can fix are listed separately. The formula is shown in the
  app, and the app never claims "1 in N".
- **Before/after:** `HistoryStore` keeps snapshots holding the score, the ids worth a look and
  salted hashes of each value. **No values are saved.** The file and salt sit in Application
  Support, excluded from backup. The Scan screen shows a "Since your last scan" card.
- **History view** with a chart, and an **iOS scoreboard** (closed by Apple, still open, changes
  after your last iOS update).
- **Share card:** an image with the score, counts and finding titles only. No values.
- **Settings tab:**
  - Appearance
  - Your data (history, scoreboard, clear)
  - "Suggest hYYa apps in fixes" toggle
  - Open source (code link, MPL 2.0, version)
  - Support hYYa: Share, Rate (hidden until the App Store id exists), Contact, Privacy Policy,
    Report a Security Issue
  - More from hYYa (hYYa ai, hYYa ✨)
- **hYYa suggestions:** `Model/HyyaSuggestions.swift` is empty on purpose. The owner pairs apps
  with findings case by case.
- **Placeholder app icon:** made from the mascot JPG. It needs a proper icon, made in Icon
  Composer with Liquid Glass layers, before launch.

Owed before launch, besides the device tests below:
- The App Store id goes in `hYYaLinks.appStoreID`. That turns on Rate and makes Share point at the
  store.
- hyya.com pages: `privacypolicy/hyya-footprint-inspector.html` and
  `hyya-footprint-inspector.html`.
- In dark mode, list rows use the system grey rather than the brand navy surface. Polish item.

---

Earlier status:

**2026-10-17: Phase 2 scanner built.** It builds with no warnings in our code, all 7 unit tests
pass, and it was walked through by hand in the iOS 26.4 Simulator. Phase 2 is **not committed**
yet. Phase 1 is on `main`.

## What's in the app
Four tabs:
- **Scan:** 49 passive and advanced signals read with no prompt. "Worth a look" summary, then
  sections, then a detail page with what it reveals, why iOS allows it, how long it lasts and the
  fix.
- **Permission sections:** 10 categories and 23 signals, requested only on "Show me". Before
  asking, each one previews what an app would get.
- **Sensitive apps:** 9 categories and 25 schemes, all off by default. Results are blurred until
  tapped, cleared when the app leaves the screen, and never stored. There's a caution alert for the
  LGBTQ+ and circumvention categories.
- **Check-up:** 12 guided Settings steps with ticks remembered on the phone.
- **Lab:** a Debug-only Settings link lab.

Other pieces:
- **Reinstall demo:** a keychain install log for this app only, `ThisDeviceOnly`.
- **Privacy manifest:** `App/Resources/PrivacyInfo.xcprivacy`, with no tracking and no data
  collected.
- **Nothing contacts the network:** grep for URLSession, CLGeocoder or http finds none.

## Layout
- `App/Sources/Model/`: signal types, plus the passive catalogue (`SignalCatalogue.swift`) and the
  permission catalogue.
- `App/Sources/Readers/`: passive sources.
- `App/Sources/Permissions/`: permission sources.
- `App/Sources/Scanner/`: `Scanner` (@Observable, in memory only).
- `App/Sources/Sensitive/`, `App/Sources/CheckUp/`, `App/Sources/UI/`.
- `Tests/CatalogueTests.swift`: unique ids, steps on every guided fix, the scheme list matching
  Info.plist (25 max), no URL scheme of our own, owner-name detection, and every passive reading
  having a definition.

## Owed (needs a real iPhone)
1. Run every permission flow:
   - Local Network: does the prompt get detected?
   - Motion: is the first query the prompt?
   - Bluetooth: do devices show up in 4 s?
   - Photos: speed on a large library.
   - Calendars: is access seen straight after granting?
   - Camera: device list.
   - Location: does a fix arrive within 5 s?
2. Apple Music subscription uses `MusicSubscription.current`. It may need the MusicKit service on
   the App ID; until then it shows "Couldn't tell".
3. Settings link lab results, and every sensitive scheme with the app installed and after
   uninstalling it (start with `flo`).
4. Required Reason codes for boot time (35F9.1) and active keyboards (54BD.1). Neither has a
   "display to the user" reason, so prepare reviewer notes.
5. Motion sensors and heading only show values on a device (the Simulator has none).

## Next: Phase 3
- Port the hYYa design layer from Encrypted Notes.
- One calm overall score.
- Before/after re-scan.
- iOS-version scoreboard.
- History kept on the phone.
- Share card.
- Settings screen (Support hYYa, More from hYYa) and hYYa app suggestions on findings.
