# Prompt for the hyya.com workspace: hYYa Footprint Inspector privacy policy

Written 2026-10-17 from the app's source code (build 0.1.0). Paste everything below the line into
the hyya.com workspace. It is self-contained.

---

## Task

Write the privacy policy for **hYYa Footprint Inspector** and publish it as one HTML file at:

```
https://hyya.com/privacypolicy/hyya-footprint-inspector.html
```

The app's Settings screen already links to that exact address. Until the page exists, the link
returns 404, so this page blocks launch.

### Look and structure: match the family

- Use the existing hYYa privacy policies as the template:
  `https://hyya.com/privacypolicy/hyya-encrypted-notes.html` and
  `https://hyya.com/privacypolicy/hyya-encrypted-folder.html`. Fetch one first and match it.
- Keep the same shell, heading hierarchy and shared `/privacypolicy/styles.css`, linked the way
  the siblings link it.
- Keep the same "Last updated" convention at the top and the same contact link at the bottom.
- Don't add a framework, CDN script, web font, analytics or cookie banner. A privacy policy that
  loads a tracker would undo everything it says.
- This page uses the family style, not the app's own theme. The app's showcase page will carry
  the app's look; that brief comes separately later.

### Voice

Plain, calm and precise. Be emphatic about the negatives ("None.", "never", "we cannot"). Use short
paragraphs. No marketing adjectives and no exclamation marks. Spelling must match the sibling
policies.

## What the app is

hYYa Footprint Inspector is a free, open-source iPhone app. It shows people what any app on their
iPhone can learn about the device and about them, explains each finding in plain language, and
shows how to reduce it. It reads the same information any app can read, and shows it **only to
the person holding the phone**.

- **Platform:** iPhone and iPad, iOS 26 or later. Bundle id `com.hyya.footprintinspector`.
- **Price:** free. No in-app purchases, no subscription, no ads.
- **Licence:** open source under the Mozilla Public License 2.0. The source is published on
  GitHub, so anyone can check every claim below.
  - ⚠️ The repository is still private. State the open-source claim only once the owner confirms
    it's public. Until then, leave out the GitHub link but keep the licence sentence.
- **No hYYa account, sign-up, login or server.** hYYa runs no backend for this app.

## Facts the policy must state accurately

### What hYYa collects

- **Nothing.** The app has:
  - no analytics, telemetry or crash-reporting SDK
  - no advertising and no advertising identifier
  - no third-party SDKs of any kind (it uses only Apple's own frameworks)
  - no hYYa server to send anything to
- The App Store privacy label is **"Data Not Collected"**, and the policy must agree with it.
- The app does **not** ask to track the user. It only reads whether tracking requests are turned
  on in Settings, to show it to the user.

### What the app reads, and where it goes

The app reads device information to show it to the user. **None of it leaves the phone.** Group it
the way the app does:

1. **Without asking (any app can read these).**
   - Device model, iOS version, storage and free space.
   - Last restart time, and the date the phone was set up.
   - Screen, battery, language, region, keyboards, time zone and accessibility settings.
   - Connected headphones and speakers by name.
   - Network type and whether a VPN is on.
   - Motion sensors, fonts and voices.
   - Clipboard *status*: whether something is copied and of what kind. **Never the clipboard's
     contents.**
   - It also loads a blank page in a hidden web view to show what websites can read. **Nothing is
     downloaded; the page is empty.**
2. **Only after the user taps "Show me" and allows the permission.**
   - Motion & Fitness, Location (While Using only), Camera (the list of cameras only; **no photo
     or video is ever taken**), Bluetooth, Local Network, Contacts, Photos, Calendars, Reminders,
     and Media & Apple Music.
   - The app asks for each permission only when the user taps "Show me", never at launch, and
     never asks for "Always" location.
3. **What it shows, and what it deliberately doesn't.**
   - **Contacts:** counts, account names and the labels on numbers. **Never names, numbers or
     addresses.**
   - **Calendars:** account names and how busy the calendar is. **Never event titles.**
   - **Reminders:** list names and counts.
   - **Photos:** the places photos were taken, grouped on the phone into areas about 1 km wide and
     shown as rounded coordinates. **No place names are looked up**, because that would mean
     sending coordinates to a mapping service.
4. **Installed apps ("Sensitive apps").**
   - iOS lets an app ask whether specific apps are installed (up to 25 named apps).
   - The user chooses which categories to check; all are off until switched on.
   - Results are shown blurred until tapped, disappear when the user leaves the app, and are
     **never saved, logged or shared**.
   - Only the user's choice of categories is remembered.

### What is stored on the phone

All of this stays on the user's iPhone, is never sent anywhere, and is removed when the app is
deleted, with one exception explained below:

- **Scan history.** Each entry holds the date, iOS version, score, which findings were "worth a
  look", and a scrambled marker (a salted one-way hash) of each value. The markers let the app
  tell what changed between scans. **The values themselves are never saved.** The history is
  excluded from iCloud and device backups, and Settings has a "Clear history" button.
- **Preferences:** the sensitive-app categories chosen, check-up ticks, whether the rating card
  was dismissed, and whether suggestions for other hYYa apps are shown.
- **The one exception, stated honestly.** To demonstrate how apps recognise you after you delete
  and reinstall them, the app keeps a list of its **own** install dates in the iPhone's keychain.
  - The keychain survives deleting the app; that is the point of the demonstration.
  - The list holds dates only.
  - It is set to stay on this device only, so it doesn't sync to iCloud Keychain and isn't
    restored to another phone.
  - Erasing the iPhone removes it.

### Contact with Apple, not hYYa

Three features talk to Apple's own services through Apple's frameworks, the same way any app
does. Name them so the policy is complete:

- **App Store country, and when the user's account first got the app:** read through StoreKit.
- **Apple Music subscription status:** read through MusicKit, only after the user allows Media &
  Apple Music.
- **"Rate the App":** opens Apple's App Store review page or Apple's own rating prompt.

Apple's handling of these is covered by Apple's privacy policy, not hYYa's. Make that boundary
clear, the way the sibling policies do for iCloud.

### Links that leave the app

Settings has links that open outside the app:
- Share
- the privacy policy
- Contact hYYa
- the source code
- other hYYa apps
- a security-report email address

Nothing is attached to these links: **no tracking parameters**.

### Diagnostics

The only diagnostics that can reach anyone are Apple's own crash and analytics sharing. The user
controls it in iOS Settings, and it goes to **Apple**, not hYYa.

### Sharing, sale and legal requests

- No sale, no sharing, no disclosure. There's nothing to share.
- hYYa cannot produce user data in response to a legal demand because it holds none.

### Children

The app isn't directed at children under 13, and it collects nothing from anyone of any age.

### Your rights

Keep this short and honest. hYYa holds no personal data, so access, correction, portability and
deletion are already in the user's hands: everything is on their phone, "Clear history" deletes
the history, and deleting the app removes the rest. **Don't invent** a data-protection officer,
request process, retention schedule, sub-processors or certifications.

## Suggested sections

1. Who We Are
2. The Short Version
3. Information We Collect
4. What the App Reads, and Why
5. Permissions You Can Grant
6. Installed-App Check
7. What Is Stored on Your iPhone
8. The Reinstall Demonstration
9. Apple Services
10. Links That Leave the App
11. Diagnostics
12. Data Sharing
13. Security and Open Source
14. Children
15. Policy Updates
16. Contact

## Rules

- **Every sentence must be true of the app as described here.** If unsure, leave it out and flag
  it back rather than writing it confidently.
- **Never claim hYYa can see, recover or delete anything on the user's phone.** It can't.
- **State the caveats:** the keychain install list and the three Apple services. A reader who
  finds one overstatement stops trusting the rest.
- Set "Last updated" to the publish date.
- Output **one complete HTML file**, ready to publish at the address above.
- Afterwards, reply with:
  - the live URL
  - its HTTP status
  - anything you left out or flagged
