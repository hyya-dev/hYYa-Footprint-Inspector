# Play Console: App content answers (from the code)

## Data safety
- Does your app collect or share any of the required user data types? **No.**
  - Google defines "collect" as transmitting data off the device. The app has **no INTERNET
    permission** and cannot send anything. Everything it reads is processed on the device only.
- Is all of the user data collected by your app encrypted in transit? Not applicable (nothing collected).
- Do you provide a way for users to request that their data is deleted? Not applicable. Settings
  has "Clear history" for the on-device scan history.

## Privacy policy
https://hyya.com/privacypolicy/hyya-footprint-inspector.html

## Ads
No, the app has no ads.

## App access
All functionality is available without special access. No login.

## Target audience and content
- Target age: 18 and over (a privacy tool; not designed for children).
- Not appealing to children.

## Content rating (IARC questionnaire)
- Category: Utility / Tools. No violence, sexual content, profanity, drugs, gambling or user
  interaction. Users can't communicate or share content. The app shares no location with others.
- Expected rating: Everyone / PEGI 3 / 4+.

## Sensitive permissions and APIs
- Location, Nearby devices (BLUETOOTH_CONNECT), Contacts, Calendar: runtime permissions, each
  asked only when the user taps "Show me", shown on screen only. No declaration form needed for
  these at targetSdk 36.
- No QUERY_ALL_PACKAGES, no Photos/Videos permission, no Accessibility service, no SMS/Call log.
- Package visibility: named `<queries>` packages for the user-initiated Sensitive apps check.

## Government apps / financial features / health
None. Not a news app. No health features.
