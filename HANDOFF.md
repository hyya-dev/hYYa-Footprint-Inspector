# HANDOFF: where the work is

**2026-10-17: Phase 1 groundwork done, except the device tests.** Nothing is committed yet. The
local git repo has `origin` set to hyya-dev/hYYa-Footprint-Inspector and nothing has been pushed.

## Done
- Repo scaffold: MPL 2.0 `LICENSE`, `README.md`, `CLAUDE.md` (standing decisions),
  `docs/ACTION-PLAN.md`.
- `project.yml`: iOS 26, arm64, `com.hyya.footprintinspector`. The skeleton app builds for the
  Simulator. In Debug builds a "Settings link lab" screen is available.
- `docs/SIGNAL-INVENTORY.md`: 163 signals plus about 50 gaps, inference cards and our
  permission needs.
- `docs/SENSITIVE-APP-CATALOGUE.md`: 9 categories, a 50-app list and a prioritised 25-app list.
  **25 is the binding cap:** this Mac only has Xcode 27.1 (iOS 27 SDK).
- `docs/SETTINGS-LINKS.md`: in the Simulator, `App-prefs:` links only reach the Settings home
  screen, on both iOS 26.4 and iOS 27.0.
- `docs/HYYA-APPS-DETECTABILITY.md`: only Subscriptions Tracker declares a probe-able scheme.

## Owed (needs a real iPhone)
1. Run the Settings link lab on a device and record where each link lands.
2. Test every sensitive-app scheme with the app installed and after uninstalling it. Start with
   `flo`.
3. Check the Required Reason codes for boot time and active keyboards against Apple's current list.
   No "show to user" reason may exist for them.

## Next: Phase 2
Build the scanner from `docs/SIGNAL-INVENTORY.md`.
- Don't use the undocumented Lockdown Mode key.
- Name photo places offline: `CLGeocoder` sends coordinates to Apple.
