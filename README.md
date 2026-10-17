# hYYa Footprint Inspector

See what apps can learn about your iPhone, and about you, and fix it.

Every app you install can read dozens of small details about your device without asking: when it
was set up, how it's configured, what's connected to it. Together those details can recognise you
across apps, a technique called fingerprinting. Grant an app a permission and it can see far more.

hYYa Footprint Inspector reads the same things any app can, shows them to you in plain language,
flags what's worth worrying about, and walks you through fixing what can be fixed.

- **Free.** No ads, no subscription, no in-app purchase.
- **Private.** No account, no server, no analytics. Nothing leaves your phone.
- **Open source** under the [Mozilla Public License 2.0](LICENSE).

## Status
Planning and groundwork (Phase 1). See [docs/ACTION-PLAN.md](docs/ACTION-PLAN.md).

## Requirements
- Xcode 26 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- Deployment target: iOS 26

## Building
```sh
xcodegen generate
xcodebuild -project hYYaFootprintInspector.xcodeproj \
  -scheme "hYYa Footprint Inspector" -configuration Debug \
  -destination "generic/platform=iOS Simulator" build
```

## Licence
[MPL 2.0](LICENSE). You may use this code in your own projects. If you change any of our files,
those changed files must stay open under the same licence.

Part of the [hYYa](https://hyya.com) family of apps.
