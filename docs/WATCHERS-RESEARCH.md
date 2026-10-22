# Who can watch you: research before building (2026-10-22)

Two questions from the owner:
1. Can the app show which installed apps can spy on the person?
2. Can it show that apps such as a bank, employer or government app can check whether
   sensitive apps (dating, LGBTQ+, faith, VPN…) are installed, so the person can choose to use
   the website instead?

Short answer: **no app can prove another app spies, on any store.** What we can honestly do is
show who *holds the access spying needs* (strongest on Android), and tell people plainly that
*any* app can run the same sensitive-app check we do (all platforms), with the website as the
way out. Nothing below needs a new permission, and nothing leaves the device.

## 1. Store rules that shape the design

| Rule | Source | What it means for us |
| --- | --- | --- |
| No misleading claims "such as iOS-based virus and malware scanners" | Apple 2.3.1(a) | Never say "detects spyware/malware" in the app or the listing. Say "who can watch you". |
| Don't collect which apps are installed for analytics or ads | Apple 5.1.2(iv) | We never collect: results stay on the device and aren't saved. |
| Don't surreptitiously build a profile | Apple 5.1.2(iii) | Checks run only when the person taps, and show only to them. |
| Don't use other developers' names in our name/icon, or stuff metadata with app names | Apple 4.1(c), 2.3.7 | App names appear inside the app as findings, never in the store copy. |
| No discriminatory or mean-spirited content about sexual orientation, religion… | Apple 1.1.1 | Calm, protective wording; already the house tone. |
| `QUERY_ALL_PACKAGES` only when finding all apps is the core purpose; "Don't gain broad app visibility via methods not explicitly allowed by policy" | Play Package visibility | **No broad visibility, and no MAIN/LAUNCHER query trick.** Named `<queries>` only, as now. |
| App inventory "may never be sold nor shared for analytics or ads" | Play Permissions policy | Same as above: on-device only. |
| Accessibility API: disclosure and declaration for apps that *use* it | Play Accessibility policy | We don't use it. We only read which services are on, which the policy doesn't cover. |
| Store listing must reflect what the app does; don't mimic system warnings | Play Deceptive Behavior | No fake "threat found" alerts; findings look like ours, not like system security warnings. |
| Stalkerware must disclose itself; parental/enterprise monitoring allowed | Play Stalkerware policy (2020) | Some apps holding these accesses are legitimate (parental control, work). Wording must say "check you know it", not "this is spyware". |

## 2. What each platform allows (tested where the docs were unclear)

### Android: tested on Android 16 (API 36), target SDK 36, 2026-10-22
Two throwaway apps on the emulator: a *target* holding an accessibility service, notification
access and device admin, and an *observer* with **no** `<queries>` entry for it.

| Read by the observer | Result |
| --- | --- |
| `AccessibilityManager.getEnabledAccessibilityServiceList` | ✅ the target's service, **with the app's name** |
| `Settings.Secure` `enabled_accessibility_services` | ✅ package ID |
| `Settings.Secure` `enabled_notification_listeners` | ✅ package ID (alongside the system's own Google and launcher listeners) |
| `DevicePolicyManager.getActiveAdmins()` | ✅ package ID |
| `PackageManager.getPackageInfo(target)` | ❌ not found: no name, icon or permissions for an app we can't see |

So an Android app can, with no permission and no broad visibility, list every app that can read
the screen (accessibility), read every notification, or lock/wipe the device (device admin).
Accessibility entries come with the app's name; the other two give a package ID. The Settings
page each one opens shows the full name.

**Not possible on Android:** reading another app's `<queries>` list (no public API), or naming
bank or government apps without either listing them by package (country-specific and endless)
or broad visibility (not allowed for us).

### iOS / iPadOS
- An app can't see other apps' permissions, traffic, profiles or `LSApplicationQueriesSchemes`.
  It can't list installed apps beyond its own 25 named schemes.
- Monitoring on an iPhone usually comes through a **configuration profile / device management**
  (Settings › General › VPN & Device Management), a shared iCloud account, or a hidden Shortcut
  or Find My share. None of these is readable by an app; Safety Check covers sharing.
- **Gap:** the Check-up sends people to Safety Check and App Privacy Report, but has **no step for
  VPN & Device Management**.

### macOS
- Any Mac app can already see every installed and running app. So every app on a Mac can see
  dating, faith or VPN apps; the Sensitive apps screen already shows that.
- The sandbox blocks reading which apps hold Screen Recording, Accessibility, Input Monitoring
  or Full Disk Access. The Check-up opens each pane.
- **Gap:** no step for **Device Management / Profiles** (System Settings › General › Device
  Management).

## 3. Recommended design

### A. "Apps that can check for these": all platforms, copy only
On the Sensitive apps screen, after a check, a calm card:

> Any app on this device can run this same check, including banking, government, employer and
> ID apps. If you'd rather an organisation couldn't, use its website in the browser: a website
> can't see which apps you have.

- Fix level 3 (guided). No organisation is named: we can't verify which apps check, and naming
  one would be an unverifiable claim (Apple 2.3.1, 1.1.1; Play Deceptive Behavior).
- On Mac the wording changes to "every Mac app can see all your apps".

### B. Android: "Who can watch you" section in the Scan
Three findings built from the public reads above, each listing the apps it found:
- **Can read your screen** (accessibility services): high when any non-system app holds it.
- **Can read every notification** (notification access): medium; the system's own listeners
  (Google, the launcher) are labelled "built into your device" and not counted.
- **Can lock or erase this device** (device admin): high when any non-system app holds it.
- An app holding **two or more** of these is flagged on its own: "worth a close look: this is
  how monitoring apps work. If you don't know it, remove it." Never "spyware".
- Each fix opens the matching Settings page (level 2), where the person sees the full name and
  can turn it off.
- Package IDs that we can't name are shown as-is, with "open Settings to see its name".

### C. Check-up steps to add
- iOS: **VPN & Device Management** ("profiles you don't recognise can route or watch traffic").
- macOS: **Device Management** (profiles).
- Android: **Device admin apps** (Settings › Security › Device admin apps).

### Store copy
Allowed: "see which apps can read your screen or notifications", "who can watch you".
Never: "spyware", "malware", "virus", "detect", "threat". (Already banned in our localisation
scripts.)

## Sources
- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Play: Use of the broad package (app) visibility permission](https://support.google.com/googleplay/android-developer/answer/10158779)
- [Play: Permissions and APIs that access sensitive information](https://support.google.com/googleplay/android-developer/answer/16558241?hl=en)
- [Play: Use of the AccessibilityService API](https://support.google.com/googleplay/android-developer/answer/10964491)
- [Play: Deceptive Behavior](https://support.google.com/googleplay/android-developer/answer/9887877)
- [Android: Package visibility, automatically visible apps](https://developer.android.com/training/package-visibility/automatic)
- Play stalkerware policy coverage: [Security Magazine](https://securitymagazine.com/articles/93394-google-bans-stalkerware-apps-from-the-play-store), [TechRadar](https://www.techradar.com/news/google-finally-bans-stalkerware-apps-but-there-may-still-be-a-problem)
