<p align="center">
  <img src="App/Resources/Assets.xcassets/MascotCutout.imageset/mascot-cutout.png" width="160" alt="The hYYa Footprint Inspector detective">
</p>

<h1 align="center">hYYa Footprint Inspector</h1>

<p align="center">
  <b>See what any app can learn about your iPhone, and how to hide it.</b><br>
  Free · Open source · Nothing leaves your phone
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/licence-MPL%202.0-D2AE88" alt="Licence: MPL 2.0"></a>
  <img src="https://img.shields.io/badge/iOS-26%2B-black" alt="iOS 26+">
  <img src="https://img.shields.io/badge/data%20collected-none-7CD9A8" alt="Data collected: none">
  <img src="https://img.shields.io/badge/App%20Store-coming%20soon-lightgrey" alt="App Store: coming soon">
</p>

<p align="center"><img src="docs/images/readme-hero.jpg" alt="Screens from hYYa Footprint Inspector" width="100%"></p>

## Why

Every app you install can quietly read dozens of details about your iPhone without asking:
- when it was set up, to the second
- when it last restarted
- your free space, to the byte
- your headphones' name, which often includes your first name
- your languages and keyboards

Each one looks harmless. Together they can recognise your phone across apps, a technique called
**fingerprinting**. Grant a permission and an app can see far more.

hYYa Footprint Inspector reads exactly what any app can read, shows it to you in plain language,
flags what's worth a look, and walks you through hiding what can be hidden.

## What it does

- **Scan.** Checks dozens of details any app can read without asking, and gives one calm score
  that counts only what you can change.
- **Clues explained.** For each one: what an app learns, why iPhone allows it, and how long it
  lasts.
- **Fixes.** Short steps for what you can change, and an honest "only Apple can fix this" for
  the rest.
- **What apps see once you say yes.** Tap a permission (Location, Photos, Contacts, Calendars,
  Bluetooth, Local Network, Motion and more) to see exactly what an app gets. You're asked only
  when you tap.
- **Which apps give you away.** Apps can ask whether specific apps are installed. Choose the
  categories to check (dating, faith, health, VPN, messaging, crypto and more). Results are
  blurred until you tap, cleared when you leave, and never saved.
- **Permission check-up.** iOS never tells one app which other apps can reach your data, so a
  guided walk through Settings does it instead.
- **Keep track.**
  - Before/after comparisons and an iOS scoreboard of what Apple has fixed.
  - Scan history kept only on your phone.
  - A share card that holds none of your personal details.

## Privacy

- **No account, no server, no analytics, no ads, no third-party SDKs.** The app uses only Apple's
  frameworks.
- **Everything stays on the device.**
  - Scan history keeps scrambled markers, never the values.
  - Sensitive-app results are never stored.
  - No place names are looked up for your photos.
- **App Store privacy label: "Data Not Collected".** Full policy:
  [hyya.com/privacypolicy/hyya-footprint-inspector.html](https://hyya.com/privacypolicy/hyya-footprint-inspector.html)

Read the code to check. That's why it's open source.

## Building

Requirements: Xcode 26 or later,
[XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`), iOS 26.

```sh
xcodegen generate
xcodebuild -project hYYaFootprintInspector.xcodeproj -scheme "hYYa Footprint Inspector" \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" test
```

`project.yml` is the source of truth; the `.xcodeproj` is generated and not committed.

| Folder | What's in it |
|---|---|
| `App/Sources/Readers`, `App/Sources/Permissions` | How each signal is read |
| `App/Sources/Model` | What we say about each signal: meaning, persistence, severity, fix |
| `App/Sources/UI` | The interface (dark "Quiet Noir" look) |
| `docs/` | Research, signal inventory, design notes |

## Contributing

Found a signal we miss, a wrong explanation or a better fix? See
[CONTRIBUTING.md](CONTRIBUTING.md). Security issues: [SECURITY.md](SECURITY.md).

## Licence

[Mozilla Public License 2.0](LICENSE).
- You may use this code in your own projects, including closed-source ones.
- Changes to *our* files must stay open under the same licence.
- The hYYa name, the mascot and the app icon are not covered by the licence. Please don't use
  them for your own builds.

Part of the [hYYa](https://hyya.com) family of privacy-first apps.
