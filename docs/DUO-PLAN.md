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
- **Testing.** Device Hub in Xcode previews every pose. Taps from the Simulator panel don't reach
  the Duo, so `FlowCheckUITests` drives it. **The owner turns, folds and opens the device when
  asked**, at each step below.

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
   toolbar, so the system places it correctly in every pose.
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

## Check before TestFlight (every phase)
- `FlowCheckUITests` passes on `fi-iPhone-Duo`, on a regular iPhone and on the iOS 26.0 Simulator.
- In Device Hub: folded, open portrait, open landscape, book, laptop and half-width Split View. The
  owner turns or folds the device when asked, and I review a screenshot of every page.
- Then TestFlight, and the owner tests on their Duo before any submission.
