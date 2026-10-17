# Sensitive App Catalogue (installed-app check)

Status: Phase 1 research, 2026-10-17. Nothing here is built yet.

## 1. How the check works, and the cap

Any iOS app can ask the system "can something open `scheme://`?" through `UIApplication.canOpenURL`. If the answer is yes, an app that registers that scheme is installed. iOS only answers for schemes the asking app lists in `LSApplicationQueriesSchemes` in its Info.plist. For every other scheme the answer is always "no".

- **Cap today: 50 schemes.** Entries past the 50th are ignored.
- **Cap with the iOS 27 SDK: 25 schemes.** Apple is expected to require that SDK around spring 2027, so we plan both lists now.
- **The list is fixed at build time.** Users cannot add apps. They can only choose which of our built-in categories to scan.

**How category choice works.** Every scheme in the shipped list belongs to exactly one category. The scan screen shows the categories as toggles, all off by default. Only the schemes in the categories the user turns on are checked. Results stay in memory, are shown on the device and are then thrown away. We store only the category toggles, never which apps were found. Because the declared list is visible in our public source and in the app bundle, the categories also explain to users why each scheme is there.

**Known limits, to show in the UI and the README:**
- A "yes" means *some* app registered the scheme, not necessarily the named app. For example, the Session messenger also registers `sgnl` because it started as a fork of Signal. Generic schemes such as `quran`, `bible`, `trust` and `calm` may be claimed by look-alike apps, so a hit means "an app of this kind", which is still the point.
- A "no" doesn't prove the app is absent. A vendor can rename or drop its scheme in any update.
- Any app with a different scheme list can run this same check without the user knowing. That is the lesson we want users to take away.

## 2. Categories: what an app could infer

| # | Category | What a curious app could infer, and why it matters |
|---|---|---|
| 1 | Dating & LGBTQ+ | Whether you are single or looking, and sometimes your sexual orientation. In some countries that can lead to blackmail, being outed or prosecution. |
| 2 | Religion & faith | Your likely religion, which is special-category data under the GDPR and can expose people to discrimination or persecution. |
| 3 | Health, mental health & fertility | That you track periods, are trying to conceive or are pregnant, or see a therapist. Insurers, employers and, in some places, law enforcement may care about this. |
| 4 | Addiction & recovery | That you are recovering from alcohol, drug or other dependence. That carries stigma and can affect insurance or employment. |
| 5 | VPN, Tor & censorship circumvention | That you work around network controls. Where these tools are restricted, that alone can draw attention from the authorities. |
| 6 | Secure & regional messaging | That you value private communication, or roughly where you come from (WeChat, LINE and Viber are strongly regional). Both can single people out. |
| 7 | Finance, crypto & gambling | That you hold crypto or gamble. That makes you a target for scams and phishing, and gambling is illegal in some countries. |
| 8 | Job hunting & workplace | That you may be looking to leave your employer, or that you talk anonymously about your workplace. |
| 9 | Politics & news | Your likely political leaning, judged from partisan news apps, which can be used for profiling or targeting. |
| — | Adult content | **Not included.** See the note below. |

**Why no adult category.** The App Store doesn't allow mainstream adult-content apps, so on most iPhones the check would find nothing. Declaring adult-site schemes would also add App Review risk for no benefit. Dating apps already cover the sexuality-related inference. We can revisit this if a well-known sideloaded or EU alternative-marketplace app turns out to matter.

## 3. Candidate apps per category

Confidence labels:
- **ref**: in the reference implementation's working scheme list.
- **web**: confirmed online, from the app's open-source Info.plist, the vendor's developer docs, or third-party apps on GitHub that declare the scheme and pair it with this app's bundle ID. "web (src)" means we read the vendor's own source. "web (3p)" means third-party evidence only. Older third-party lists can be out of date.
- **unverified**: our best guess. It must be confirmed on a device with the app installed before it ships.

Popularity tiers are rough global estimates of user base, not exact figures: **XL** has more than 100M users, **L** 10–100M, **M** 1–10M, **S** fewer than 1M or niche. "Region" notes where an app is especially strong.

### 3.1 Dating & LGBTQ+
| App | Scheme | Popularity / region | Confidence |
|---|---|---|---|
| Tinder | `tinder` | XL, global | ref |
| Bumble | `bumble` | L, global | ref |
| Hinge | `hinge` | L, US/UK/EU | ref |
| Grindr (LGBTQ+) | `grindr` | L, global incl. Middle East and Asia | ref |
| OkCupid | `okcupid` | L, global, strong in India | web (3p) |
| Blued (LGBTQ+) | `blued` | L, China and Southeast Asia | web (3p) |
| Tantan | `tantanapp` | L, China | web (3p) |
| Jack'd (LGBTQ+) | `jackd` | M, global | web (3p) |
| Plenty of Fish | `pof` | L, US/UK/Canada | web (3p) |
| Happn | `hppn` | L, Europe and Latin America | web (3p, old) |
| Match | `match` | L, US | web (3p). Generic name, so collisions are possible |
| Hornet (LGBTQ+) | `hornet` | M, Turkey, Russia, Brazil | unverified |
| Badoo | `badoo` | XL, Europe, Latin America, Russia | unverified |
| Muzz (Muslim marriage) | `muzz` | M, UK, Middle East, South Asia | unverified |
| Taimi (LGBTQ+) | `taimi` | M | unverified |
| Feeld | `feeld` | M, US/UK | unverified |

### 3.2 Religion & faith
| App | Scheme | Popularity / region | Confidence |
|---|---|---|---|
| Muslim Pro | `muslimpro` | XL, Middle East, Southeast Asia, Europe | web (3p) |
| YouVersion Bible | `youversion` | XL, global | web (3p) |
| Quran apps (various) | `quran` | L, generic | web (3p). Any Quran app may register it |
| Bible apps (various) | `bible` | L, generic | web (3p) |
| Athan (IslamicFinder) | `athan` | L, Middle East and South Asia | web (3p, single hit) |
| Hallow (Catholic) | `hallow` | M, US | unverified |
| Pray.com | `pray` | M, US | unverified |

### 3.3 Health, mental health & fertility/pregnancy
| App | Scheme | Popularity / region | Confidence |
|---|---|---|---|
| Flo (period and pregnancy) | `flo` | XL, global | unverified. Top priority to test on a device |
| Clue (period) | `clue` | L, Europe and global | web (3p) |
| Glow (fertility) | `glow` | M | web (3p) |
| Ovia Fertility | `oviaFertility` | M, US | web (3p) |
| Natural Cycles | `naturalcycles` | M, Europe | unverified |
| Talkspace (therapy) | `talkspace` | M, US | web (3p) |
| BetterHelp (therapy) | `betterhelp` | M, US and global | unverified |
| Headspace | `headspace` | L, global | web (3p, two sources) |
| Calm | `calm` | L, global | web (3p). Generic name |
| Amwell (telehealth) | `amwell` | M, US | web (3p) |

### 3.4 Addiction & recovery
No source we found confirms a scheme for any of these apps. Every one needs a device test.
| App | Scheme | Popularity / region | Confidence |
|---|---|---|---|
| I Am Sober | `iamsober` | M, global | unverified |
| Reframe (alcohol) | `reframe` | M, US | unverified |
| Nomo | `nomo` | S | unverified |
| Smoke Free | `smokefree` | M | unverified |
| QuitNow! | unknown | M | unverified (named in a third-party list, scheme not found) |

### 3.5 VPN, Tor & censorship circumvention
| App | Scheme | Popularity / region | Confidence |
|---|---|---|---|
| Proton VPN | `protonvpn` | L, global | ref + web (src) |
| NordVPN | `nordvpn` | L, global | web (3p) |
| Psiphon | `psiphon` | L, Iran, Russia, China, Middle East | web (src) |
| Onion Browser (Tor) | `onionhttp` (also `onionbrowser`) | M, global | web (src) |
| Orbot (Tor VPN) | `orbot` | M, global | web (src) |
| Shadowrocket (proxy client) | `shadowrocket` | L, China, Iran, Russia | web (3p) |
| Hotspot Shield | `hotspotshield` | L, global | web (3p) |
| Lantern | `lantern` | M, China and Iran | web (3p, single hit) |
| Quantumult X | `quantumult-x` | M, China | web (3p, single hit) |
| Stash | `stash` | M, China | web (3p). Generic name |
| ExpressVPN / Surfshark / Windscribe / Mullvad | — | L–M | unverified. Mullvad's open-source iOS app declares no URL scheme, so it can't be detected this way |

### 3.6 Secure & regional messaging
| App | Scheme | Popularity / region | Confidence |
|---|---|---|---|
| Signal | `sgnl` | L, global | ref + web (src). Session also matches |
| Telegram | `tg` | XL, Russia, Iran, Middle East, global | ref + web (3p) |
| Threema | `threema` | M, German-speaking Europe | web (vendor docs) |
| Session | `sessionmessenger` | S–M | web (src) |
| Element (Matrix) | `element` | M | web (src) |
| Wire | `wire` | S–M, Europe | web (3p, old) |
| WeChat | `weixin` | XL, China and diaspora | web (vendor SDK guides) |
| Viber | `viber` | XL, Eastern Europe, Middle East, Southeast Asia | web (vendor docs + 3p) |
| LINE | `lineauth2` (also `line`) | XL, Japan, Thailand, Taiwan | web (vendor SDK docs) |
| KakaoTalk | `kakaolink` (also `kakaotalk`) | L, Korea | web (vendor SDK docs) |
| imo | `imo` | L, Middle East, Africa, South Asia | web (3p) |

### 3.7 Finance, crypto & gambling
| App | Scheme | Popularity / region | Confidence |
|---|---|---|---|
| Binance | `bnc` | XL, global ex-US | web (3p, many plists) |
| Coinbase | `coinbase` | L, US/EU | ref |
| MetaMask | `metamask` | L, global | web (3p, many WalletConnect plists) |
| Trust Wallet | `trust` | L, global | web (vendor docs + 3p) |
| OKX | `okx` | L, Asia and global | web (3p) |
| Bybit | `bybit` | L, Asia and global | web (3p) |
| Kraken | `kraken` | M, US/EU | web (3p) |
| Crypto.com | `crypto` | L, global | web (3p) |
| Robinhood | `robinhood` | L, US | web (3p) |
| Revolut | `revolut` | L, Europe | web (3p) |
| bet365 | `bet365` | L, UK, EU, global | web (3p) |
| DraftKings | `draftkings` | L, US | web (3p) |
| FanDuel | `fanduel` | L, US | web (3p) |
| BetMGM / Caesars | `betmgm` / `caesars` | M, US | web (3p) |
| Stake | `stake` | M | web (3p). Generic name |

### 3.8 Job hunting & workplace
| App | Scheme | Popularity / region | Confidence |
|---|---|---|---|
| Indeed | `indeed` | XL, global | unverified |
| Blind (anonymous workplace) | `teamblind` | M, US tech, India, Korea | web (3p) |
| LinkedIn | `linkedin` | XL, global | ref. Too common to tell you much on its own |
| Glassdoor / Naukri / Bayt / ZipRecruiter | — | L, regional | unverified |

### 3.9 Politics & news
| App | Scheme | Popularity / region | Confidence |
|---|---|---|---|
| Fox News | `foxnews` | L, US (right-leaning) | web (3p) |
| The Guardian | `theguardian` | L, UK and global (left-leaning) | web (3p) |
| Truth Social | `truthsocial` | M, US (right-leaning) | unverified |
| Al Jazeera | `aljazeera` | L, Middle East and global | unverified |
| CNN / BBC News | `cnn` / `bbcnews` | XL | web (3p). Too mainstream to show a leaning |

## 4. Recommended lists

Rules for picking: (a) the highest-harm signals come first (sexual orientation, circumvention, religion, reproductive health); (b) the list must work worldwide, so Middle Eastern, Asian and European apps are included alongside US ones; (c) where two apps are equally sensitive, the one with a verified scheme wins; (d) each **unverified** entry (*) has a fallback from the same category that is already verified, used if the device test fails.

### 4.1 Today: exactly 50

| Category | Count | Schemes |
|---|---|---|
| Dating & LGBTQ+ | 8 | `tinder`, `bumble`, `hinge`, `grindr`, `okcupid`, `jackd`, `blued`, `tantanapp` |
| Religion & faith | 4 | `muslimpro`, `youversion`, `quran`, `bible` |
| Health, mental health & fertility | 7 | `flo`* (fallback `amwell`), `clue`, `glow`, `oviaFertility`, `talkspace`, `headspace`, `calm` |
| Addiction & recovery | 2 | `iamsober`*, `reframe`* (if both fail: fold the category into Health and use `naturalcycles`* or `pof` from Dating) |
| VPN, Tor & circumvention | 8 | `protonvpn`, `nordvpn`, `psiphon`, `onionhttp`, `orbot`, `shadowrocket`, `hotspotshield`, `lantern` |
| Secure & regional messaging | 8 | `sgnl`, `tg`, `threema`, `sessionmessenger`, `element`, `weixin`, `viber`, `lineauth2` |
| Finance, crypto & gambling | 8 | `bnc`, `coinbase`, `metamask`, `trust`, `okx`, `bet365`, `draftkings`, `fanduel` |
| Job hunting & workplace | 2 | `indeed`* (fallback `linkedin`), `teamblind` |
| Politics & news | 3 | `foxnews`, `theguardian`, `truthsocial`* (fallback `bbcnews`) |
| **Total** | **50** | |

### 4.2 iOS 27 SDK: prioritised 25

| Category | Count | Schemes |
|---|---|---|
| Dating & LGBTQ+ | 4 | `grindr`, `blued`, `tinder`, `bumble` |
| Religion & faith | 2 | `muslimpro`, `youversion` |
| Health, mental health & fertility | 4 | `flo`* (fallback `glow`), `clue`, `talkspace`, `headspace` |
| Addiction & recovery | 1 | `iamsober`* (fallback: fold into Health with `calm`) |
| VPN, Tor & circumvention | 4 | `psiphon`, `onionhttp`, `protonvpn`, `nordvpn` |
| Secure & regional messaging | 4 | `sgnl`, `tg`, `threema`, `weixin` |
| Finance, crypto & gambling | 4 | `bnc`, `coinbase`, `metamask`, `bet365` |
| Job hunting & workplace | 1 | `teamblind` |
| Politics & news | 1 | `foxnews` |
| **Total** | **25** | |

**Before shipping:** test every scheme on a real device with the app installed and again after uninstalling it. Record the result and the date in a test log kept in the repo. Re-test every release, because vendors change schemes without notice.

## 5. Safety notes

**Risk to users**
- A list of detected circumvention, LGBTQ+ or religious apps is itself sensitive. Someone holding the phone, at a border check or a police stop, or an abusive partner, could read it. So:
  - Every category is **off by default** and is scanned only when the user turns it on and taps Scan. Nothing scans automatically.
  - Results appear **behind a tap with a privacy blur**. They are hidden again when the app goes to the background and are never shown in notifications, widgets, Spotlight or the app-switcher snapshot.
  - Results are **never stored, logged, sent, shared or included in any export or crash report**. They are recomputed every time.
  - The circumvention and LGBTQ+ categories show a short, calm notice before the scan, for example: "In some countries, having these apps can be risky. This check runs only on your phone and shows results only to you."
- Wording stays factual ("an app that opens `psiphon://` is installed") and avoids judgement.
- Even when the user never runs the scan, our declared list shows which apps we *could* check. Anyone inspecting the phone learns nothing personal from that, because the list is identical on every install.

**App Review risk**
- Apple has rejected apps that query long lists of unrelated schemes ("fingerprinting"). Guideline 5.1.1 and its data-minimisation rules apply. Our defence is that showing users this exposure is the app's core, disclosed purpose, the results never leave the device, and nothing is collected.
- App Review may ask why an app declares Tor, VPN or dating schemes. Answer in the review notes up front, keep the privacy policy consistent with them, and make the "Data Not Collected" privacy label true.
- Suggested reviewer note (adapt as needed):

  > hYYa Footprint Inspector is a privacy-education app. One screen shows users which sensitive kinds of apps (for example dating, health, VPN) any other app could detect on their phone using canOpenURL. The schemes in LSApplicationQueriesSchemes are used only for this on-device demonstration. Every category is off until the user turns it on, results are shown only on screen and are never stored, logged or transmitted, and the app collects no data. The code is open source at [repo URL]. To test: open Installed Apps, turn on a category and tap Scan.

- If App Review objects, offer to cut the list down (for example, to the 25-scheme list) rather than drop the feature.
