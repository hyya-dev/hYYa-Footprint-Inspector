# Action plan

Agreed with the owner on 2026-10-17. The standing decisions are in `../CLAUDE.md`.

## Why this app wins
Loupe (Mysk, June 2026) shows the problem but stops there. Its last update was 12 June 2026, so it
hasn't been updated for iOS 27. It has no fixes, no score and no history, and it carries an advert
for Mysk's own browser.

What people asked for, from App Store reviews, Hacker News, Privacy Guides, Mastodon and Reddit:
1. **"OK, now help me fix it"**: the top demand by far.
2. Plain explanations: what each signal is, why iPhone allows it, and who could misuse it.
3. Concern about apps checking which other apps are installed.
4. The creepy specifics: setup date, motion sensors, AirPods name, VPN detection.
5. Trust: open source, nothing leaves the phone, no upsell, human-reviewed code.
6. Calm, realistic advice rather than alarm or resignation.
7. A fixed-vs-still-open scoreboard tracking Apple's progress.
8. Mac, then Android.

## Phases

### Phase 1: Groundwork
- [x] Repo: MPL 2.0 licence, README, CLAUDE.md, this plan
- [x] Check whether other apps can detect our own hYYa apps → `HYYA-APPS-DETECTABILITY.md`
- [x] Signal inventory (163 signals plus about 50 gaps): every signal, its API, persistence, severity, fix, and iOS 27 status →
  `SIGNAL-INVENTORY.md`
- [x] Sensitive-app catalogue (9 categories, about 100 candidates; a 25-app list is ready, and the device test is still owed), within the 25-scheme cap →
  `SENSITIVE-APP-CATALOGUE.md`
- [x] Settings deep-link test on iOS 26 / 27 (Simulator) → `SETTINGS-LINKS.md`. A device check is still owed.
- [x] XcodeGen project skeleton that builds (iOS 26, arm64, team 8PYFWUL3ND,
  `com.hyya.footprintinspector`)

### Phase 2: Scanner. Built 2026-10-17; device testing still owed
- Our own signal readers, rebuilt from the inventory, organised in three sections:
  - What any app sees without asking
  - What apps see once you say yes
  - Sensitive checks: installed apps by category, chosen by the user; hidden behind a tap, with
    a privacy blur, never saved
- A guided permission check-up for things only Settings can show (which apps can reach Health,
  Location, Photos and so on).

### Phase 3: What makes us better (2–3 weeks)
- A fix on every finding, at the four levels in CLAUDE.md, with a re-scan showing before and after.
- One calm overall score; concerns in amber.
- An iOS-version scoreboard: closed by Apple, still open, new.
- History kept on the phone, and a share card with personal details blurred.
- A Settings screen in the Encrypted Notes layout, including "More from hYYa" and hYYa app
  suggestions on the findings where they fit.

### Phase 4: Launch (1–2 weeks)
- ASO (name, subtitle, keywords), screenshots, privacy policy, a hyya.com page, TestFlight.
- Reviewer notes covering fingerprinting rule 5.1.2(i), the Required Reason APIs, and why we
  declare sensitive app schemes.

### Phase 5: macOS, then Android

## Main risks
- **App Review:** Apple forbids fingerprinting. Our defence is that every value is shown only to
  the device owner, never stored off the phone and never sent anywhere. We'll send clear reviewer
  notes and prepare a fallback build that hides the riskiest checks.
- **The 25-scheme cap** limits the installed-app check, so the catalogue has to choose its 25
  apps carefully.
- **Unofficial Settings links** may break or be rejected. Guided steps are always the fallback.
