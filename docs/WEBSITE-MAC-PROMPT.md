# Prompt for the hyya.com workspace: hYYa Footprint Inspector for Mac (policy and showcase)

Paste everything below the line into the hyya.com workspace.

---

**FROM the hYYa Footprint Inspector workspace.** The Mac version is built.
- Mac v1.0.0 build 5 is set up in App Store Connect: same App Store record, one listing. It is
  **not submitted**, so nothing is live yet.
- Please stage two things now and publish them only on the owner's "publish", after Apple approves
  the Mac version:
  1. a Mac section in the privacy policy
  2. Mac additions to the showcase
- Verify against the code at `/Users/hyya/development/hYYa Footprint Inspector` (read-only):
  - `App/Sources/MacReaders/`
  - `App/Sources/Model/MacSignalCatalogue.swift`
  - `App/macOS/FootprintInspectorMac.entitlements`
  - `docs/MACOS-PLAN.md`

## 1. Privacy policy: Mac additions

Keep your conventions: no platform names except where they are needed to tell the two versions
apart. A Mac section can say "On a Mac". Facts, from the code:

**Without asking, the Mac version also reads** (to show the user, on screen):
- **You:** your full name and account name (and so your home folder name), and whether your
  account is an administrator.
- **This Mac:**
  - its serial number and hardware ID, which are permanent
  - model, chip, memory and graphics chip
  - system version and build
  - the computer name and its name on the network
- **Since you started it:** the last restart time and uptime. Also the battery level.
- **Storage and drives:** total and free space, and the names of connected drives.
- **Screens, sound and accessories:**
  - screens by name and size
  - sound devices (speakers, headsets, microphones) by name
  - connected USB accessories by name
- **Language, region and keyboards:** languages, keyboards, region formats and time zone.
- **Accessibility and appearance:** which accessibility features are on, light or dark mode, and
  the accent colour.
- **Clipboard:** how many times anything has been copied, and what kinds of thing are on it.
  **Never the contents.**
- **Network:** connection type, the network hardware addresses of the Mac's ports, the router
  address, lookup (DNS) servers and network names, and whether a VPN is on.
- **Fonts:** every installed font family.
- **Apps:**
  - the names of every app in Applications, including Apple's own
  - every app that is open
  - a count of background programs
  - the default browser
- **App Store:** the store country, when the app was installed, and when the account first got it
  (as on the other version).

**Sensitive apps on a Mac:**
- The check matches app names from the Applications list against nine categories. A few apps are
  also checked by link type.
- There is no 25-app limit on a Mac, so each category checks more apps.
- Results are hidden until clicked, cleared when the app goes to the background, and never saved.
- Name the categories only, as before. **Never "LGBTQ+"**: say "dating".

**Permissions on a Mac:**
- Location, Contacts, Calendars, Reminders, Photos, Camera (camera names only, no capture) and
  Bluetooth.
- Each is asked only when the user clicks "Show me".
- The Mac version has **no** Motion & Fitness, no Media & Apple Music and no Local Network.

**Not on a Mac:** "What websites see". The Mac version has no network entitlement at all, so it
cannot connect anywhere, even to load a page.

**Unchanged on a Mac:**
- Data Not Collected; no account, no server, no analytics, no third-party code.
- Scan history keeps scrambled markers only and is excluded from backups.
- The keychain install-date demonstration works the same way.
- Settings opens in a separate window, with the same links as before.

**Store screenshots** use made-up sample values (name, serial number, apps). No real person's
details appear.

## 2. Showcase additions (on publish)
- Availability: add Mac next to iPhone · iPad, and macOS to JSON-LD `operatingSystem`. Do this on
  launch day only.
- Add a short "On a Mac it sees even more" block, because the Mac genuinely reveals more:
  - the serial number and hardware ID (permanent, even after erasing)
  - your full name
  - every installed and running app (no limit)
  - the router and network names that can reveal an employer
  - many fixes open the right System Settings page in one click
- Mac screenshots (2880×1800, sample data):
  - `store/slides/mac/01-results.png`
  - `store/slides/mac/02-finding.png`
  - `store/slides/mac/03-name.png`
  - `store/slides/mac/05-checkup.png`
  - Skip `04-sensitive` (it shows app names and the "LGBTQ+" label).
- `llms.txt` and `llms-full.txt`: add the Mac facts above. Add ⛔ guards:
  - not a malware scanner
  - never stores or sends the serial number, name or app list
  - no "What websites see" on Mac
  - no Motion, Music or Local Network on Mac

Reply with the staged text and files. Publish waits for Apple's approval of the Mac version and the
owner's "publish".
