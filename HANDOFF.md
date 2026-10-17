# HANDOFF: where the work is

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
1. **Privacy policy page** on hyya.com (brief: `docs/WEBSITE-PRIVACY-POLICY-PROMPT.md`). The URL
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
