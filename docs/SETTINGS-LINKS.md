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

## Real device test, 2026-10-17
**Setup.** iPhone 17 Pro Max, **iOS 27.0.1** (24A446), Debug build. Driven by the XCUITest
`test3_SettingsLinks` (taps every Lab row, Settings force-quit before each one) and
`test4_SettingsLinkVariants` (the test runner opens extra variants, cold and warm Settings).

| Link | Lands on |
|---|---|
| `UIApplication.openSettingsURLString` | ✅ **Our own page** (Settings › Apps › Footprint Inspector) |
| `UIApplication.openNotificationSettingsURLString` | ⚠️ The **global** Notifications page. We never ask for notifications, so iOS has no per-app page for us |
| `App-prefs:` | Settings home |
| `App-prefs:Privacy`, all `App-prefs:Privacy&path=…` | ❌ Settings › **Apps** list |
| `App-prefs:Bluetooth`, `WIFI`, `General&path=About`, `General&path=Keyboard`, `MOBILE_DATA_SETTINGS_ID`, `SAFARI`, `CASTLE` | ❌ Settings › **Apps** list |
| `App-prefs:root=Bluetooth`, `App-prefs:root=Privacy&path=LOCATION` | ❌ Settings › **Apps** list |
| `App-prefs:com.apple.mobilesafari` | Safari's page (under Apps), cold and warm |
| `App-prefs:com.hyya.footprintinspector` | Apps list (cold), our page (warm). Inconsistent; use the official link instead |
| `App-prefs:com.apple.Preferences` | Apps list |
| `prefs:root=Privacy`, `prefs:root=Bluetooth`, `settings-navigation://…` | ❌ Rejected: no app opens (LSApplicationWorkspace error 115) |

**Reading.** On iOS 27 the Settings app treats whatever follows `App-prefs:` as an **app bundle
id**. A real bundle id opens that app's page under Apps; anything else (all the old pane names)
falls back to the Apps list. The device therefore behaves *worse* than the Simulator, which at
least landed on Settings home. **No unofficial link reaches a Privacy, Bluetooth, General or
Mobile Data pane on iOS 27.0.1.** iOS 26 on a real device was not tested (no iOS 26 iPhone here).

## Decision for now
- Fix guides use **illustrated, step-by-step instructions**. Where the fix concerns our own
  permissions, they use the official own-page link.
- An "Open Settings" button that lands on the Settings home screen is still useful: it saves the
  user finding the Settings app. Label it honestly as **"Open Settings"**, never "Take me there".
- ~~Revisit after the device test.~~ Device test done (above): no unofficial link lands on the
  right pane on iOS 27, so **ship none**. Plain `App-prefs:` (Settings home) is the only useful
  unofficial link, and the official own-page link covers our own permissions.
- The notifications link is only worth showing once the app has asked for notifications.
