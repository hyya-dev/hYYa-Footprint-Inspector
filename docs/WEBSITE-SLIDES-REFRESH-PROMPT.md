# Prompt for the hyya.com workspace: refresh the Footprint Inspector screenshots

Paste everything below the line into the hyya.com workspace.

---

**FROM the hYYa Footprint Inspector workspace.** Please refresh the screenshots on the staged
showcase (branch `footprint-showcase`) before it publishes.

**Why:** the app's wording is now device-neutral. The old slides you took show "iPhone" in their
captions and inside the screens (for example "Why iPhone allows it" and "about this iPhone"). The
app now says "device" and "the system" everywhere.
- v1.0.0 build 3 was resubmitted to App Store review on 2026-10-18.
- The new slides are the ones live in App Store Connect.

**What to take** (read-only, from `/Users/hyya/development/hYYa Footprint Inspector`). Same
numbering as before:

| Your current image | Take from `store/slides/iphone-6.9/` |
|---|---|
| iphone-01-results | `01-results.png` |
| iphone-02-clues | `02-clues.png` (no longer half-scrolled under the clock) |
| iphone-03-finding | `03-finding.png` |
| iphone-04-checkup | `05-checkup.png` |
| iphone-05-home | `07-home.png` |

Keep your exclusions:
- `04-sensitive` still shows the in-app "Dating and LGBTQ+" label and app names.
- `06-scoreboard` shows a live system version.

Still iPhone frames only, as your convention.

**Copy changes in the app** (only if the page quotes them):
- "iOS scoreboard" is now **"Privacy scoreboard"**.
- "Why iPhone allows it" is now **"Why the system allows it"**.
- The first slide's chip now reads **"Nearly 50 details checked"**, which matches your "nearly 50".

**Then:**
- Re-encode the images (avif/webp as you do) and bump the `?v=` cache keys.
- Update the JSON-LD `screenshot` entries and captions.
- Grep the page and `llms*.txt` for "iPhone's", "this iPhone" and "iOS scoreboard".

Reply with the files you touched. Publish still waits for Apple's approval and the owner's
"publish".
