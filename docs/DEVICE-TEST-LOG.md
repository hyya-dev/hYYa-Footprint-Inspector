# Device test log

Fill in each row, or tell Claude the results and it will fill them in. "Result" is what you saw.
✅ worked · ⚠️ worked oddly · ❌ didn't work.

## Run 1: 2026-10-17
- **Device:** iPhone 17 Pro Max (iPhone18,2)
- **iOS:** 27.0.1 (24A446)
- **Build:** 0.1.0 (1), Debug, installed from Xcode
- **How:** automated XCUITests (`UITests/DeviceWalkthroughUITests.swift`, scheme "hYYa Footprint Inspector UITests"),
  run from the Mac with the phone unlocked. Timings below include the test tapping the system prompt
  (well under a second), not human reaction time. Screenshots stayed on the Mac (they hold personal data).

### A. Scan tab (no permissions)
| # | Check | Result |
|---|---|---|
| A1 | Start scan finishes in under 10 s and shows a score | ✅ 3.0–3.1 s, score 64 ("Moderate footprint", 48 things, 5 worth a look). Comparison card "Since your last scan" appeared. |
| A2 | Motion sensors shows real numbers, and "Which way you're facing" appears | Not checked (section shows "details" in the list; detail page not opened by the test) |
| A3 | Connected headphones show by name. If they're called "Name's AirPods", it's flagged amber with your first name | Not checked (no headphones confirmed connected) |
| A4 | "Remembered after deleting" says installed once. Delete the app, reinstall from Xcode, scan: it should say installed 2 times | First half ✅ ("Installed once on this iPhone", amber). Reinstall half not done (no uninstalling). |
| A5 | Free space and Last restart look right | ✅ plausible values, both flagged amber in "Worth a look" |

### B. Permission categories ("Show me")
| # | Category | Prompt appeared? | Readings appeared, and how long? | Result |
|---|---|---|---|---|
| B1 | Motion & Fitness | Yes (Allow / Don't Allow) | 3 of 3 rows, 2.2 s | ✅ activity mix, steps and distance, air pressure + altitude |
| B2 | Location: fix within ~5 s? | Yes; tapped "Allow While Using App" | 4 of 4 rows, 1.8 s | ✅ coordinates, altitude ±30 m, "Speed not known", Precise On |
| B3 | Camera: list of your lenses | Yes | 1 row, 1.3 s | ⚠️ says "7 cameras: 4 on the back, 3 on the front". Looks like virtual/combined devices are counted, not physical lenses |
| B4 | Bluetooth: nearby devices in ~4 s | Yes | 1 row, 4.9 s | ✅ "16 devices nearby, 3 with a name" |
| B5 | Local Network: devices on your Wi-Fi | Yes, prompt detected | 1 row, 4.0 s | ✅ "14 named devices and services found" |
| B6 | Contacts: counts and labels only, no names | Yes, two steps: Continue, then "Share All N Contacts" | 3 of 3 rows, 3.0 s | ⚠️ counts only, no names ✅. "Relationship labels" shows phone labels (mobile, home, other), not relationships, yet is flagged amber |
| B7 | Photos: places and likely home/work. Time it on your library | Yes; tapped "Allow Full Access" | 3 of 3 rows, 1.5 s (~7k photos) | ✅ places count, "Two places stand out", library size |
| B8 | Calendars: accounts and busy count straight after allowing | Yes; "Allow Full Access" | 2 of 2 rows, 1.4 s | ✅ straight after allowing |
| B9 | Reminders | Yes | 2 of 2 rows, 1.4 s | ✅ lists and open/overdue counts |
| B10 | Media & Apple Music: does subscription say Yes/No or "Couldn't tell"? | Yes | 3 of 3 rows, 1.5 s | ✅ says "Not subscribed"; library size and top genre shown |

### C. Settings links (Lab tab, Debug only)
Each row tapped with Settings force-quit first (cold start). Full detail in `docs/SETTINGS-LINKS.md`.
| Link | Landed on |
|---|---|
| Official: this app's Settings page | ✅ our page (Apps › Footprint Inspector, all our permissions listed) |
| Official: this app's notifications | ⚠️ the global Notifications page (we never asked for notifications, so iOS has no per-app page yet) |
| `App-prefs:` | Settings home |
| `App-prefs:Privacy`, every `App-prefs:Privacy&path=…` (LOCATION, HEALTH, PHOTOS, CONTACTS, CALENDARS, BLUETOOTH, USER_TRACKING, PROBLEM_REPORTING, LOCKDOWN_MODE) | ❌ Settings › **Apps** list |
| `App-prefs:Bluetooth`, `General&path=About`, `General&path=Keyboard`, `MOBILE_DATA_SETTINGS_ID`, `SAFARI`, `CASTLE` | ❌ Settings › **Apps** list |
| `prefs:root=Privacy` | ❌ rejected, nothing opens (red cross in the lab) |

### D. Sensitive apps
Not run by the automated pass (the owner ran it by hand and it found apps).
Turn on the categories for apps you **do** have installed, then tap Check.
| App you have installed | Found? |
|---|---|
| | |
| | |

Also: after tapping Reveal, switch to another app and come back. The results should be gone.

### E. Look and feel
| # | Check | Result |
|---|---|---|
| E1 | Light and dark mode both look right | Dark mode only (phone is in dark): looks right |
| E2 | Share my result opens the share sheet with the card image | |
| E3 | Large text (Settings › Display & Brightness › Text Size): nothing is cut off | |
