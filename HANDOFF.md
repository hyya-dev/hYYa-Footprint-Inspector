# HANDOFF: where the work is

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
