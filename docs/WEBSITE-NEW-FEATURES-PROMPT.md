# Prompt for the hyya.com workspace: hYYa Footprint Inspector new features, AEO/SEO

Paste everything below the line into the hyya.com workspace.

---

**FROM the hYYa Footprint Inspector workspace.** The app has been redesigned around four steps and
gained several features. Please update everything on hyya.com that describes it:
- the product page `hyya-footprint-inspector.html`
- its home-page card
- every SEO/AEO file that lists the apps (llms.txt, structured data, sitemap, FAQ blocks, whatever
  you keep)
- the privacy policy `privacypolicy/hyya-footprint-inspector.html` (section 4)

Follow your own conventions for design, CSS, the served-comment rule, deploy and verification.

**Status:** iOS and macOS v1.0.0 (build 13) are in App Store review, submitted 2026-10-22. Android
1.0.0 is in **closed testing** on Google Play and is not public yet: production opens around
2026-11-04.
- Stage everything now.
- Publish only when the owner says "publish".
- Do not link or mention Google Play until the owner says Android is public. No "coming soon" or
  review status goes in served files.

## 1. Facts (unchanged)

| | |
|---|---|
| Name | **hYYa Footprint Inspector** (always the full name) |
| App Store | https://apps.apple.com/app/id6824033636: one app for iPhone, iPad and Mac |
| Price | Free. No in-app purchases, no subscription, no ads |
| Data | App Store label "Data Not Collected". Nothing leaves the device; no account, no server, no analytics |
| Open source | Mozilla Public License 2.0, https://github.com/hyya-dev/hYYa-Footprint-Inspector |
| Privacy policy | https://hyya.com/privacypolicy/hyya-footprint-inspector.html |

## 2. The app now: four simple steps (wording is yours, these are the facts)

Audience: ordinary people, not developers. Write the way the app now talks: calm and plain.

1. **Footprint.** One tap checks what any app can read about the device. The result is a **score
   out of 100, where higher is better**, and a **colour chart**: red is worth a look, amber is
   worth knowing, green is fine. A "What your score means" card explains the bands (under 50 heavy,
   50 to 74 moderate, 75 and up light) and how far the score can rise.
2. **Sensitive apps.** Shows which of the person's apps any other app can detect, such as dating,
   faith, health or VPN apps, and what that could reveal. Banking, government and employer apps can
   run the same check; the app suggests using their website instead. Names stay hidden until the
   person taps "Show the apps", and nothing is saved.
3. **Tracker** (new).
   - **iPhone and iPad:** the person opens their device's own **App Privacy Report**, a file they
     save from Settings. The app explains in plain words which apps used their location, photos,
     contacts, camera or microphone, and which ones **shared data with outside advertising or
     analytics companies**. Normal activity is left calm: an app talking to its own service, to
     Apple, to sign-in and hosting services, or to public services like weather is not flagged. It
     is honest about limits: the report covers 7 days and shows who an app talked to, not what it
     sent.
   - **Mac:** one-click links to the settings that show which apps can record the screen, read the
     keyboard, control the Mac or read all files.
   - **Android:** shows which apps can read the screen, read every notification, or lock the
     device. Apps holding more than one of these are flagged, because that's how monitoring apps
     work.
4. **Check-up.** A list of settings to review one area at a time, each opening the right place in
   Settings.

**Fix them with me** (new): from the score card, the app walks through each fixable finding one at
a time and opens the right setting, then asks the person to scan again to see the new score. Be
accurate: the app can't change settings itself; it guides the person to each one.

**Every finding** now says how serious it is ("Serious", "Worth knowing" or "Minor"), who can read
it, how long it lasts, and what it lets someone do, in plain words.

**Re-scan reminder** (new, Settings): optional, off by default; a weekly or monthly local
notification on the device. No server, no push service.

**Never write:** "spyware", "malware", "virus", "detects tracking", "hack", or any claim that the
app knows what an app sent. Correct framing: "see who can watch you", "see which apps shared with
advertising companies", "take back access".

## 3. Privacy policy: add to section 4 (what the app reads), wording yours

- **Tracker (iPhone and iPad):** the app reads only a file the person chooses themselves (their App
  Privacy Report), on the device. It is never stored, uploaded or sent, and is cleared when the app
  closes.
- **Re-scan reminder:** if turned on, the app asks permission to show notifications and schedules
  a local reminder on the device. Nothing is sent. On Android this is the "notifications"
  permission.
- **Android "who can watch you" check:** the app reads which apps hold accessibility, notification
  access or device admin, on the device. Nothing is stored or sent.
- The "Data Not Collected" statement and everything else stays true. Keep the page noindex.

## 4. AEO/SEO

Use the four steps and Tracker as the core of descriptions, structured data and FAQ. Suggested
questions (answer each in one or two plain sentences from the facts above):
- How can I see which apps on my iPhone share my data with advertising companies?
- What is the App Privacy Report and how do I read it?
- How can I tell if an app can watch my screen or read my notifications on Android?
- What does a footprint score mean?
- Can other apps see which apps I have installed?
- Does hYYa Footprint Inspector send my data anywhere? (No: nothing leaves the device.)

Keep the device-neutral rule for marketing copy ("your device", "phone, tablet or computer"); name
iPhone, iPad, Mac or Android only where a feature genuinely differs, as in section 2.

## 5. Slides (English), sample data only

New slides are in the app repo, read-only for you to copy:
`/Users/hyya/development/hYYa Footprint Inspector/store/slides/`
- `iphone-6.9/` and `ipad-13/` (7 each): 01-results, 02-tracker, 03-fix, 04-finding, 05-sensitive,
  06-checkup, 07-home.
- `mac/` (6): 01-results, 02-fix, 03-finding, 04-sensitive, 05-checkup, 06-home.
- `android-phone/` (7): **don't use until Android is public.**

Replace the old screenshots on the product page with the iPhone set in this order; Tracker (02) and
Fix it step by step (03) are the new headline features.

## 6. When done

Tell the owner what changed (pages, files, privacy policy diff), and stop before publishing.
