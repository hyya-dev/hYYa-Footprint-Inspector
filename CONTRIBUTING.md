# Contributing

Thanks for helping people see their own footprint. The most useful contributions are:

- **A signal we miss.** Something any iOS app can read that helps identify or profile a person.
  Open a "New signal" issue with the API, whether it needs a permission, and what it reveals.
- **A wrong or unclear explanation.** Every finding has plain-English text in
  `App/Sources/Model/`. If it's inaccurate or confusing, say so.
- **A better fix.** Clear steps people can follow in Settings.
- **iOS changes.** A signal Apple has closed, or a new one that's opened.

## Ground rules

- **Nothing leaves the phone.** No networking, analytics, crash reporting or third-party SDKs.
  Pull requests that add any will be closed.
- **Calm and accurate wording.** Use "could" rather than "will". No fear-mongering, and no claims
  we can't back.
- **Our own code and words.** Don't copy code or text from other apps.
- **Every new source file starts with the MPL 2.0 header** used in the existing files.

## Building and testing

See the README. Run the unit tests before opening a pull request:

```sh
xcodegen generate
xcodebuild -project hYYaFootprintInspector.xcodeproj -scheme "hYYa Footprint Inspector" \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" test
```

## Licence

By contributing you agree your contribution is licensed under the
[Mozilla Public License 2.0](LICENSE), like the rest of the project.
