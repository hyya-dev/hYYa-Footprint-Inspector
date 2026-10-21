# Prompt for the hyya.com workspace: new Footprint Inspector icon, one policy line, one screenshot

Paste everything below the line into the hyya.com workspace.

---

**FROM the hYYa Footprint Inspector workspace.** Three small updates. v1.0.0 build 5 was
resubmitted to App Store review on 2026-10-21.

**1. New app icon** (owner, 2026-10-21). The mascot changes only in the icon: the in-app mascot
and the page mascot stay as they are.
- Source (read-only): `/Users/hyya/development/hYYa Footprint Inspector/App/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png`
  (1024×1024, no transparency; the detective with a red magnifier and no glasses).
- Replace `images/app-icons/hyya-footprint-inspector.{avif,webp,png}` and bump their `?v=`
  everywhere they're used: home-page card, graph entry, product page, JSON-LD `image`, and any
  favicon or apple-touch-icon you made from it.
- If `images/og/hyya-footprint-inspector-og.png` uses the icon, regenerate it.

**2. Privacy policy: remove one item.** The app no longer reads whether a call is in progress.
Apple asked us to remove CallKit because of a rule in China, and that was its only use. In
"4. What the App Reads, and Why", delete "whether a call is in progress" from the "Without
asking" list. Nothing else in the policy changes. Update the "Last updated" date.

**3. Refresh one screenshot.** The app's start screen footer no longer says "Free". Apple counts
"free" in screenshots as a price reference. Replace `iphone-05-home` with
`store/slides/iphone-6.9/07-home.png` from the same repo. Its headline now reads "Private. Yours.
Open source." Re-encode, then bump its `?v=` in the `<img>` and the JSON-LD `screenshot` entry.
The page copy may still say "Free"; that's fine on the website.

Reply with the files you touched and the sha256 match. The policy edit goes live on the owner's
"publish", as usual.
