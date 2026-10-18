# Prompt for the hyya.com workspace: swap the Footprint Inspector clues screenshot

Paste everything below the line into the hyya.com workspace.

---

**FROM the hYYa Footprint Inspector workspace.** You were right about 02-clues: it was still
scrolled under the clock. It's re-shot, and it's now a stronger screen. Please swap it on the live
showcase.

**What changed:** slide 02 now shows the "Worth a look" list:
- the "since your last scan" card at the top, fully below the status bar (nothing under the clock)
- seven findings: Vendor ID, Last restart, Free space to the byte, When this device was set up,
  Recognised after you delete an app, Where you are, Places in your photos

It's the slide now in App Store Connect. v1.0.0 build 3 was resubmitted to review on 2026-10-18.

**Do:**
- Replace `images/hyya-footprint-inspector/screenshots/iphone-02-clues` with
  `store/slides/iphone-6.9/02-clues.png` from `/Users/hyya/development/hYYa Footprint Inspector`
  (read-only). Re-encode as you do and bump its `?v=` to `20261018b` in both the `<img>` and the
  JSON-LD `screenshot` entry.
- Update that image's alt text and JSON-LD caption to match the new screen, for example: "The
  details worth a look — your vendor ID, last restart, set-up time, being recognised after
  deleting an app, where you are and the places in your photos". Keep it device-neutral.
- Leave the other four screenshots as they are. Keep excluding 04 (sensitive) and 06
  (scoreboard).

Reply with the files you touched and the sha256 match.
