# macOS plan: hYYa Footprint Inspector for Mac

Status 2026-10-21: a native Mac target builds, sharing the model, scanner and screens with iOS.
It's the same bundle id, so one App Store record and one listing cover both. The Mac readers come
next. Research was verified in a sandboxed test app on macOS 27.0.1; it needs re-checking on 26.x.

## What's different on a Mac (and why the Mac version matters)

A Mac App Store app can read far more about a Mac than an iPhone app can about a phone, with no
prompt:

| Finding | iPhone | Mac |
|---|---|---|
| Permanent hardware ID | No | **Serial number and hardware ID**, which survive even erasing the Mac |
| Your real name | No | **Your full name** and account name |
| Installed apps | 25 named apps at most | **Every app.** No limit, so 350+ apps on a typical Mac |
| What's running | No | **Every running app and about 1,000 background processes**, by name |
| Network | Little | Network hardware addresses, router and DNS (which can reveal an employer), every network name |
| Connected hardware | Little | USB devices by name (a connected phone shows up), audio devices that reveal installed apps (e.g. "Microsoft Teams Audio") |
| Computer name | Hidden | Readable, often "Sam's MacBook Pro" |
| Fixing it | Guided steps only | **Most System Settings pages open directly**, so many fixes become one click |

## What the Mac version will show

Same structure and tone as iOS: Scan → clues grouped by what they reveal, each with what an app
learns, why the system allows it, how long it lasts, and the fix.

**Seen without asking (Mac):**
- **You:** full name, account name, admin or not.
- **This Mac:** serial number, hardware ID, model, chip, memory, system version, computer and network names.
- **Since you started it:** boot time and uptime.
- **Storage and drives:** size, free space to the byte, connected drive names.
- **Screens, Sound and accessories:** displays, audio devices, microphones, USB devices.
- **Language, region and keyboards:** as on iOS.
- **Accessibility and appearance:** as on iOS.
- **Clipboard:** change count and kinds, never the contents.
- **Network:** connection, network hardware addresses, router and DNS, VPN.
- **Fonts:** 500+ fonts, which reveal apps like Office and Adobe.
- **Apps on this Mac:** a count of every installed app, the default browser, and every running app.
- **Remembered after deleting:** keychain note, plus the app's leftover folder.
- **What websites see:** as on iOS.

**Seen once you allow it:** Location (and the Wi-Fi network name), Contacts, Calendars,
Reminders, Photos, Camera, Bluetooth.

**Sensitive apps:** the same nine categories and the same new result cards. With no 25-app limit,
each category checks a much longer list.

**Check-up:** the same guided areas, with Mac System Settings paths and "Open in System Settings"
buttons that go straight to the right page.

## Safety rules that change on a Mac
- **Store screenshots use a sample Mac.** A screenshot mode replaces the real serial number, name,
  hardware ID and app list with made-up values. The owner's real values must never appear in a
  public image.
- The share card never includes the serial number, name, hardware ID or app names.
- Scan history keeps scrambled markers only, as on iOS.

## Layout
The window has a sidebar with Scan, Sensitive apps and Check-up. Settings live in the standard
Mac Settings window (⌘,), with the same content and order as the iOS Settings screen.
Quiet Noir look throughout: dark only, mascot on every page.

## Steps
1. Owner approves this plan and the layout draft.
2. Mac readers and the catalogue entries for Mac-only findings, with fixes and Settings links.
3. Sensitive apps on Mac: longer lists per category.
4. Mac check-up with direct System Settings links.
5. Sidebar window and Settings window.
6. Screenshot mode, Mac store screenshots (2880×1800) and slides.
7. App Store Connect: add the macOS platform to the record, v1.0.0, listing (shared), screenshots, build. **No submission without the owner's consent.**
8. Privacy policy and website brief for hyya.com (the Mac reads more, so the policy needs a Mac section).
