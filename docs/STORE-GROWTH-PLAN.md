# Store growth plan: hYYa Footprint Inspector

Written 2026-10-17. App Store Connect app 6824033636 (version 1.0 is in "Prepare for Submission").
Owner's rules:
- Use every App Store Connect growth feature that can help.
- **🚨 Never submit anything for Apple or Google review without explicit consent.** Everything
  below is prepared up to the submit step, then the owner decides.

## What App Store Connect offers this app (seen in ASC, 2026-10-17)
Growth & Marketing:
- **In-App Events**
- **Custom Product Pages** (new)
- **Asset Library** (new)
- **Product Page Optimization** (new)
- **Promo Codes**

Elsewhere:
- **Featuring › Nominations**
- **App Accessibility** (Trust & Safety)

## 1. Asset Library: one source for every image
Asset Library holds screenshots, app previews and **creative assets**. Creative assets are larger
artwork, up to 5244 × 2950 px, that Apple can use across App Store touchpoints for discovery.

What we'll put there:
- **Screenshots.** One set in the Quiet Noir look, captured from the real app on the 6.9″ and
  13″ sizes.
- **App preview video.** About 20 s: scan, then the score, then a finding, then the fix.
- **Creative assets.**
  - The mascot over a footprint on black, with the sand accent.
  - Wide 5244 × 2950 and square crops.
  - Text-free versions so Apple can overlay its own copy.

Every custom product page and optimization test then picks from this library, so the art stays
consistent.

## 2. Custom Product Pages: one page per audience
Each page has its own screenshots, promotional text and deep link. They're used in Apple Search
Ads, social posts and the hyya.com page.

| Page | Audience | Lead screenshot | Deep link opens |
|---|---|---|---|
| Default | Everyone | "What do your apps know about you?" | Scan |
| Privacy-curious | People who saw news about app tracking | The setup-date and restart clues | Scan |
| Sensitive apps | LGBTQ+, faith, health and travel communities | "Which apps give you away?" | Sensitive apps tab |
| Family check-up | Parents helping relatives | The 12-step permission check-up | Check-up tab |
| VPN and travel | VPN users and frequent travellers | Time zone and VPN clues, travel advice | Scan |
| iOS 27 | People updating iOS | The scoreboard: what Apple fixed | Scoreboard |

**App work needed:** deep links into each tab (a universal link or a URL scheme).
- A custom URL scheme would make our own app detectable by other apps
  (`docs/HYYA-APPS-DETECTABILITY.md`).
- So we'll use universal links on hyya.com. That needs an `apple-app-site-association` file,
  which will go in the hyya.com brief.

## 3. Product Page Optimization: test, don't guess
Runs on the live default page after 1.0 is approved. Up to three treatments at a time.

First tests, in this order:
1. **Icon.** The mascot on black vs. on sand vs. a close-up of the magnifier.
   - Alternate icons must ship inside the app binary, so they go into 1.0 now.
2. **First screenshot.** "What do your apps know about you?" vs. the score ring vs. "I found your
   setup date".
3. **Preview video** vs. no video.

We read the conversion data in App Analytics and keep the winners.

## 4. In-App Events: timely reasons to come back
Event cards appear on the product page and in search.
- **"iOS 27 privacy check-up"**: when iOS 27.x ships, see what Apple fixed.
- **"Before you travel"**: holiday seasons, sensitive-app and VPN check.
- **Data Privacy Day** (28 January): a yearly full check-up.

Each event needs its own artwork (from the Asset Library) and **App Review approval**, so each
one is a separate consent from the owner.

## 5. Nominations: ask Apple to feature it
After 1.0 is approved, nominate it under Featuring › Nominations. The angle: a free,
open-source privacy app with no data collected, built for iOS 26/27, with Liquid Glass and an
on-device-only design.

## 6. App Accessibility and App Privacy
- **App Privacy:** "Data Not Collected". The privacy policy is with hyya.com
  (brief delivered; in git history).
- **App Accessibility:** declare what's true once tested: VoiceOver, larger text, reduced motion.
  The mascot animation already respects Reduce Motion.

## 7. Not used
- **Promo Codes:** the app is free, so codes add nothing.
- **In-App Purchases and Subscriptions:** none, by design.
- **Game Center:** not applicable.

## Order of work
1. Store listing: name, subtitle (ASO), keywords, description, promo text, support/marketing
   URLs, category and age rating.
2. App Privacy answers, then the privacy policy goes live on hyya.com.
3. Screenshots and creative assets into the Asset Library.
4. Reviewer notes covering the fingerprinting rules, the declared app schemes and the Required
   Reason APIs.
5. TestFlight build.
6. **Stop and ask the owner before submitting 1.0.**
7. After approval: custom product pages (each needs review, so ask first), PPO tests,
   nominations, in-app events.
