# "Take me there": which Settings screens can we open?

## Official (safe for App Review)
| Link | Opens |
|---|---|
| `UIApplication.openSettingsURLString` | **Our own** page in Settings (our permissions, notifications) |
| `UIApplication.openNotificationSettingsURLString` | Our own notification settings |

There's no official link to any other Settings screen.

## Unofficial `App-prefs:` links: Simulator test, 2026-10-17
**Setup.** iPhone 17 Pro simulators on **iOS 26.4** and **iOS 27.0** (Xcode 27.1). Each link was
opened with `simctl openurl` from a cold start and again with Settings already open, then
screenshotted.

| Link | iOS 26.4 | iOS 27.0 |
|---|---|---|
| `App-prefs:` | Settings home | Settings home |
| `App-prefs:Privacy` | Settings home only | Settings home only |
| `App-prefs:Privacy&path=LOCATION` / `HEALTH` / `PHOTOS` / `CONTACTS` / `CALENDARS` / `BLUETOOTH` / `USER_TRACKING` / `PROBLEM_REPORTING` / `LOCKDOWN_MODE` | Settings home only | Settings home only |
| `App-prefs:Bluetooth`, `General&path=About`, `General&path=Keyboard`, `MOBILE_DATA_SETTINGS_ID`, `SAFARI`, `CASTLE` | Settings home only | Settings home only |
| `App-prefs:root=Privacy&path=LOCATION`, `settings-navigation://…` | Settings home only | not tested |
| `prefs:root=Privacy` | Rejected | Rejected |

**Result.** iOS accepts the `App-prefs:` scheme, but in the Simulator it **lands on the Settings
home screen every time**, never on the requested page.

**Caveat.** The Simulator's Settings app is a cut-down version (no Mobile Data, no Health and so
on). The real device may behave differently. To check:
1. Run a Debug build on an iPhone.
2. Open **Developer › Settings link lab** (`App/Sources/SettingsLinkLab.swift`).
3. Tap each link and note where it lands.

## Decision for now
- Fix guides use **illustrated, step-by-step instructions**. Where the fix concerns our own
  permissions, they use the official own-page link.
- An "Open Settings" button that lands on the Settings home screen is still useful: it saves the
  user finding the Settings app. Label it honestly as **"Open Settings"**, never "Take me there".
- Revisit after the device test. Ship an unofficial deep link only if it lands correctly on iOS 26
  **and** 27, and accept that Apple may object to it.
