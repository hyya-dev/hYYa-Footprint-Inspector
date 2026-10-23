# iPhone Duo plan (for v1.0.1)

Written 2026-10-24, before any build. Sources: Apple's Human Interface Guidelines page "Designing for
iPhone Duo" (published 2026-09-09), Apple's "Design for iPhone Duo" tech talk, the iOS 27.1 SDK
interfaces on this Mac (every API named below was checked there), and hands-on press reports.

## How the Duo behaves (facts that shape the plan)

- **Two displays.** The outer display (folded) is wider and shorter than a normal iPhone and uses a
  compact-width layout. The inner display (open) uses a regular-width layout.
  - Apple's main rule: build for these two size classes and let the layout resize. Don't design a
    custom layout per pose, and don't use fixed widths or device checks.
- **Controls move to the side.** On the outer display, and on the inner display in landscape, the
  system moves the tab bar, toolbar, Back/Close, the clock and the status icons into one vertical
  strip on the trailing edge. Only the inner display in portrait keeps normal top and bottom bars.
  - What the owner saw: the unlabelled icon strip on the right is this system rail. Its position
    is fixed by the system; Apple says not to override it. On the small outer display it shows
    icons only.
  - What we control:
    - the titles behind the icons (used in overflow menus and wider forms)
    - which toolbar items stay visible when space runs out
    - whether the tab bar becomes a **labelled sidebar** on the inner display (`.sidebarAdaptable`)
- **Fold (hinge).** When partly folded, the fold is a reserved region. System alerts, menus and
  sheets move off it on their own. Custom buttons must be kept off it by us
  (`GeometryProxy.reservedRegions(kind: .division)`). Scrolling content may cross it.
- **Side-by-side inside one app.** Apple's pattern is Mail: list on the leading side, the chosen
  item on the trailing side when open, and one pane when folded (`NavigationSplitView`).
  `ArrangementView` (new in 27.1) places two views side by side, or stacked, depending on shape,
  and adjusts around the fold.
- **Two apps side by side (Split View).** The system splits the inner display at a fixed 50/50.
  Nobody can drag the divider, not even Apple's own apps. Each app puts its controls on its own
  outer edge. So our app has to work well at half the inner display.
- **Laptop pose.** The system itself turns the bottom half into the keyboard and the top half into
  the app. Folding further splits the keyboard for thumbs.
  - Our app has almost no typing, so the keyboard doesn't apply to us.
  - Apple's optional table/laptop guidance does: glanceable content on top, tappable controls on
    the stable bottom half, with the same controls as every other pose.
- **Hinge state.** `onHingeChange` reports `closed`, `partiallyOpen` and `fullyOpen`. Apple says to
  use it only for small refinements, never to drive the main layout.
- **Testing.** Mostly automated, on the folded Simulator. Device Hub needs the owner at the controls,
  so it's used **once**, at the end, with one written list (see "Check before TestFlight").

## Lessons from hYYa Encrypted Notes (2026-10-24), and where they hit us

- **The Xcode version is the trigger.** Builds from Xcode 27.1 (iOS 27.1 SDK) get the vertical side
  bars on the Duo. This Mac has only 27.1, so our live build 13 already has them; the owner's
  screenshots show it.
- **Standard parts do most of the work:** size classes, system toolbars and sheets, safe areas.
  Never use the device model, screen size or orientation to choose a layout.
- **Every bar button needs an icon.** A text-only button can't stand in the vertical bar; it stays
  across the top and can cover the title. We have two:
  - "Done" in How the score works (`ScanView.swift`)
  - "Close" in Fix them with me (`FixWizard.swift`)

  Both become a `Label` with a symbol (xmark / checkmark).
- **Test Close by tapping it,** folded and open, upright and sideways. Our flow test taps Close
  but never checks that the sheet actually went away, and the store-screenshot test swipes sheets
  away instead.
  - New check: after the tap, something only that sheet shows (for example "Fix 1 of") must be gone.
  - Break the button once on purpose to prove the test can fail.
- **XCTest only photographs the outer (folded) screen;** it's black while the device is open. Open
  poses are checked in Device Hub with the owner turning or folding it, then on the owner's Duo
  through TestFlight.
- **Some Duo failures are the test harness, not the app.** The synthetic Home button and arrow keys
  don't reach the 27.1 Duo, and offsets tuned for one iPhone break at 466 points wide. Sort every
  failure into app or harness before fixing.
- **Store:** Duo screenshots, for both the outer and inner screens, become required from April 2027.
  The App Store Connect API didn't offer that screenshot type as of 2026-10-06, so plan a Duo slide
  set and check the API before then.
- **Laptop pose comes free if the keyboard can push the screen** (lesson 11). Checked 2026-10-24:
  our app has no text input at all and no bottom bar on iPhone. Its only safe-area opt-outs are
  the black background and the fade at the top. So nothing here can block the keyboard.
  - One small follow-on: that top fade (`Components.swift`, 64 points) was made for a clock at the
    top. On the folded Duo the clock is on the side, so the fade only dims our content there.
    Apply it only when there is a top safe area.
  - If text input is ever added: no `.ignoresSafeArea(.keyboard)`, keep any bar on the keyboard
    itself, and test typing in laptop pose in Device Hub.

## What we'll do

### Phase 1: get the basics right (every pose)
1. **Labelled pages.**
   - Use `.tabViewStyle(.sidebarAdaptable)` so the inner display shows a labelled sidebar
     (Footprint, Sensitive apps, Tracker, Check-up, Settings).
   - Make sure every tab and toolbar item has both a title and a symbol.
   - On the folded screen the rail stays icons-only (system rule). There, the new first page with
     the four step cards (v1.0.1 item 1) tells people what else the app does.
2. **Nothing under the system strip.**
   - Remove the fixed sizes and paddings that ignore the side safe area.
   - Move Back/Close/Done into standard toolbar placements, so the system puts them at the top of
     the strip in the right order: Back or Close first, then Done.
   - Fix the Fix-wizard button that sits off the bottom of the folded screen.
   - Fix the Check-up Back button that lands by the clock.
3. **Sheets.** Fix them with me, How the score works and Share each get one standard Close in the
   toolbar, **with an icon**, so the system places it correctly in every pose. Each one is tested by
   tapping it, then checking that something only that sheet shows has disappeared.
   - This covers the owner's "x doesn't work" finding, seen in other apps; ours must never do it.
4. **No faded cards.** Drop the 55% fade at the screen edges (`scrollIn3D`), keep the gentle tilt.
5. **Half-width check.** Every page must work at half the inner display, for when two apps share it.

### Phase 2: use the open display (book-like, side by side)
6. **List and detail side by side**, Mail's pattern, using `NavigationSplitView` on each page that
   has a list:
   - Footprint: clues on the left, the open clue and its fix on the right.
   - Tracker: apps on the left, what the chosen app did on the right.
   - Check-up: steps on the left, the open step on the right.
   - Sensitive apps: kinds on the left, the result on the right.

   Folded, each collapses to one pane, exactly as today. The system sizes the two columns and evens
   them out when the device is partly folded. There's no draggable divider: Apple doesn't offer one
   on the Duo, even between apps.
7. **Even columns.** Any grid uses an even number of columns, so nothing is split by the fold.

### Phase 3: laptop and table pose (small refinements only)
8. When the device is partly open with the fold across the middle, pages with a big result keep it
   in the top half and their buttons on the bottom half:
   - Footprint: score on top; Scan again and Fix them with me below.
   - Tracker: summary on top; the app list below.

   We use `reservedRegions(kind: .division)` for this, plus `onHingeChange` only to smooth the
   change. The controls stay the same as in every other pose. No keyboard work is needed.

### Not doing (and why)
- **A draggable divider between our pages or between apps.** The system doesn't allow one.
- **Moving the system rail or showing two of our five pages side by side** (for example Footprint
  next to Tracker). Apple says to keep the app's hierarchy and show one extra level when open
  (list plus detail), and not to rearrange the app per pose. The four-step first page solves "what
  else is there" more simply.
- **Detecting the device or using the hinge angle to choose the layout.** Apple advises against both.

## Mac and Android
- **Mac:** already uses a sidebar with list and detail, so no Duo work is needed.
- **Android foldables:** get the same idea, list and detail side by side on wide screens (Compose
  adaptive list-detail), checked on a foldable emulator profile.

## Check before TestFlight (how, in this order)

Every result is reported with how it was checked: **code reading**, **Simulator (folded)**,
**Device Hub** or **owner's Duo**. A Simulator pass is never described as "works on Duo".

1. **Code reading** (finds most Duo problems). Look for:
   - layout keyed to device model, orientation or screen size instead of size class
   - bar items without an icon
   - keyboard safe-area opt-outs or fixed heights
   - custom close buttons in the top-trailing corner, where the Duo's status column sits

   Every API name is checked against the 27.1 SDK interfaces, never taken from blogs.
2. **Simulator, folded and headless** (`fi-iPhone-Duo`; the Simulator app never needs to open).
   - Run `FlowCheckUITests` and the close-button tests:
     `xcodebuild … -destination "id=<duo>" -collect-test-diagnostics never test`.
   - Sideways in the same tests with `XCUIDevice.shared.orientation = .landscapeLeft`. Landscape
     captures come out rotated.
   - Screens: `xcrun simctl io <udid> screenshot --display=1` is the outer screen (1398×2034);
     `--display=3` is the inner one (2007×2853). The one showing black isn't in use.
   - Sort every failure into app defect or harness limit. Known harness limits: the synthetic Home
     press and arrow keys don't reach the Duo, and offsets tuned to one iPhone break at 466 points.
   - Also run on a regular iPhone and on the iOS 26.0 Simulator.
3. **Close buttons, by tapping.** Each custom close or dismiss is tapped, upright and sideways. The
   test checks that something only that screen has is gone, and the button is broken once on
   purpose to prove the test fails.
4. **Device Hub, once.** Code can't fold or open the Simulator. One request to the owner, with the
   full written list of poses and screens, all captured in that one sitting. Never pose by pose.
   - Poses: open portrait, open landscape, book, laptop, and half-width Split View.
   - Screens: each of the five pages, a finding, Fix them with me, a Check-up step, and How the
     score works.
5. **The owner's Duo through TestFlight.** This is the final check, and the only one for book, tent
   and laptop feel. Log the result. No submission before it.
