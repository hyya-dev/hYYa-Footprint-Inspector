# Can other apps detect our hYYa apps?

Checked 2026-10-17 by reading each project's Info.plist / project.yml for `CFBundleURLTypes`.

On iOS, another app can only tell that one of ours is installed if ours declares a custom URL
scheme, which the other app then probes with `canOpenURL`. Universal links (https) and Google's
OAuth redirect handled inside `ASWebAuthenticationSession` don't register a scheme, so they can't
be probed.

| App | Custom URL scheme | Detectable by other apps? |
|---|---|---|
| hYYa Encrypted Notes | none | No |
| hYYa Encrypted Folder | none. Its Google Drive redirect is intercepted by `ASWebAuthenticationSession`, with no `CFBundleURLTypes` entry (see `App/Core/Drive/DriveConfig.swift`) | No |
| hYYa Prayer Pal | none (checked `ios/App/App/Info.plist` and the 3.5.7 archive) | No |
| hYYa ink | none found | No |
| hYYa Vault (Mac) | none found | No |
| hYYa Subscriptions Tracker | **`com.hyya.subscriptionstracker`** | **Yes** |

## Notes
- Prayer Pal not being detectable matters most. Religious apps are among the sensitive categories
  Footprint Inspector warns about.
- Subscriptions Tracker's scheme is low-sensitivity. It's probably there for Capacitor or auth
  callbacks. It's worth confirming it's needed: if the callback can move to a universal link or
  `ASWebAuthenticationSession`, the scheme can go.
- Not checked yet: hYYa ai (web) and Anarchy Browser (not built yet). The browser should avoid a
  custom scheme, or accept being detectable.
- Footprint Inspector itself should declare **no** custom URL scheme.
