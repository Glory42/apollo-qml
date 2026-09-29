# Roadmap

This is the history of the file-structure refactor this fork went through —
what was planned, what actually shipped, what got cut or changed along the
way, and why. See [README.md](README.md) for what the project actually is
and how it's laid out today; this document is the "how we got here and
what's still open" record.

**Status: all 5 planned phases complete, plus a Phase 6 view/logic split.**
`DynamicIslandWindow.qml` (3090 lines) is now `qml/island/IslandWindow.qml`
(1918 lines) + `qml/island/IslandCapsule.qml` (769 lines); `ControlCenterLayer.qml`
(2483 lines) is now `ControlCenterLayer.qml` (362 lines) + `ControlCenterView.qml`
(1046 lines) + `PowerActionsController.qml`; `shell.qml` went from ~440 to 196.
Every phase was verified with `qmllint` plus an actual `quickshell` relaunch,
and every panel's toggle/open/close was re-tested over real `quickshell ipc
call` invocations after every file-moving phase (not just a clean-load smoke
test — see Phase 4's and Phase 6's writeups for why that distinction
mattered; both caught real regressions qmllint missed).

**Known open items** (not fixed, left for later — see each note for why):
- `WallpaperPickerLayer.qml` reads `userConfig.wallpaperPywalEnabled` and
  `userConfig.wallpaperTransitionInvertY`, neither of which exist on
  `UserConfig.qml` — both silently resolve to `undefined`/`false`. Verified
  pre-existing (not introduced by this refactor), not a structural issue, so
  it wasn't fixed as part of the file-structure work.
- `qml/island/assets/` (`star-filled.svg`, `star.json`, `star.svg`) are
  confirmed unreferenced anywhere in the codebase — leftover from some
  earlier, removed feature. Never deleted because it's a dead-code cleanup
  item, not a structural one; safe to remove whenever.
- `islandState` (the `~16`-value state machine in `IslandWindow.qml`) and the
  four visual cards inside `ControlCenterView.qml` were deliberately **not**
  split further — see the "Explicit non-goals" and Phase 6 sections below for
  why forcing that split isn't worth it.

Two god-files had absorbed most of the app's logic over time:
`DynamicIslandWindow.qml` (~3090 lines) and
`qml/controlcenter/ControlCenterLayer.qml` (~2480 lines). Several other files
were large enough to be worth splitting too. What follows is the plan that
was written out before any code moved, per the workflow used throughout:
plan the structure, plan the migration, execute in small verified steps —
kept here verbatim (including the parts that turned out wrong) rather than
cleaned up after the fact, because the corrections are as useful as the plan.

## Why these two files got this big

**`DynamicIslandWindow.qml`** mixed together: layer-shell/window setup, the
`islandState` string state machine (~16 states) and ~50 derived visibility
flags, ~25 near-identical IPC wrapper function triples
(`toggleXWindow`/`showXWindow`/`closeXWindow` per panel), a second
duplicate of the same toggle/open/close logic in
`handleConfiguredClickAction()`, the `mainCapsule` visual (clock, icons,
mouse/touch gesture handling with its own swipe-physics math), a
self-contained floating timer-ring widget (`timerBubble`), and 11 `Loader`
blocks wiring in the real sub-panel files (these Loaders were already clean —
not a splitting target themselves).

**`ControlCenterLayer.qml`** bolted together four largely independent
concerns behind one `Item`: volume/brightness slider plumbing, the
TLP/power-profile battery-mode drawer, wifi state+logic, and bluetooth
state+logic. The wifi/bluetooth half was *already* consumed by
`ConnectivityDetailPanel.qml`, `ConnectivityDetailShell.qml`, and
`BluetoothDeviceRow.qml` through a 40-property `provider` interface — meaning
it was already shaped like a separate controller, just not physically
separated yet.

Full per-file structural notes (section line ranges, what's self-contained,
what's cross-cutting, what's called from outside the file) came from a
dedicated audit pass and are summarized in the phase descriptions below.

## Target file structure (as originally planned)

```
Tide-island/
├── README.md
├── shell.qml                          # entry point — stays at repo root
└── qml/
    ├── common/                        # unchanged
    │   ├── qmldir
    │   ├── StyleTokens.qml
    │   ├── UserConfig.qml
    │   ├── SystemServices.qml
    │   ├── CompositorBackend.qml
    │   ├── HyprlandDispatch.qml
    │   └── BluetoothFormatting.js
    │
    ├── ipc/                           # NEW — one file per IpcHandler target
    │   ├── OverviewIpc.qml
    │   ├── IslandIpc.qml
    │   └── TideIpc.qml                # sole namespace for all panel commands
    │                                    (clipboard/weather/calendar duplicate
    │                                    top-level targets were collapsed into
    │                                    this one, matching upstream's own
    │                                    documented `tide.*` IPC surface)
    │
    ├── services/                      # NEW — headless trackers, no visuals
    │   ├── IslandClock.qml
    │   ├── IslandSystemState.qml
    │   ├── IslandMprisController.qml
    │   └── BluetoothConnectionTracker.qml
    │
    ├── workspace/                     # currently-empty dir, finally used
    │   ├── WorkspaceLayer.qml
    │   ├── CompositorWorkspaceTracker.qml
    │   ├── HyprlandWorkspaceTracker.qml
    │   ├── HyprlandWindowIntegration.qml
    │   └── OverviewWallpaperCacheController.qml
    │
    ├── notifications/                 # NEW — consolidates a feature that's
    │   │                               currently split across island/ + controlcenter/
    │   ├── NotificationLayer.qml      # toast popup
    │   ├── NotificationHistory.qml    # stored history/model
    │   └── NotificationCenterLayer.qml # full panel (moved from controlcenter/)
    │
    ├── island/                        # the window/capsule hub — stays the
    │   │                               core, but shrinks from 20 files to ~10
    │   ├── IslandWindow.qml           # renamed from DynamicIslandWindow.qml
    │   ├── IslandCommands.js          # NEW — table-driven panel registry
    │   ├── IslandCapsule.qml          # NEW — mainCapsule visual + clock
    │   ├── IslandGestures.qml         # NEW — capsule mouse/touch swipe handling
    │   ├── TimerBubble.qml            # NEW — extracted, self-contained
    │   ├── ConnectivityDetailShells.qml # NEW — groups the 3 shell instances
    │   ├── SplitIconLayer.qml
    │   ├── OsdLayer.qml
    │   ├── IslandRootGestureArea.qml
    │   └── BluetoothExpandedLayer.qml
    │
    ├── player/                        # NEW — split out of island/
    │   ├── ExpandedPlayerLayer.qml    # pager shell (keeps external API)
    │   ├── MusicPage.qml              # NEW
    │   └── TimerPage.qml              # NEW
    │
    ├── wallpaper/                     # NEW — split out of island/
    │   ├── WallpaperPickerLayer.qml
    │   ├── WallpaperConfig.js         # NEW — pure validators, pulled out
    │   └── scripts/
    │       ├── scan_wallpapers.py     # NEW — pulled out of an embedded JS string
    │       └── apply_wallpaper.py     # NEW
    │
    ├── weather/                       # NEW — split out of island/
    │   ├── WeatherLayer.qml
    │   ├── WeatherService.qml
    │   └── WeatherIcon.qml
    │
    ├── calendar/                      # NEW — split out of island/
    │   ├── CalendarLayer.qml
    │   └── CalendarMath.js            # NEW — pure day-grid math, pulled out
    │
    ├── controlcenter/                 # shrinks from 2480 lines to ~800
    │   ├── ControlCenterLayer.qml     # slimmed: card composition only
    │   ├── ConnectivityController.qml # NEW — wifi+bluetooth state/logic
    │   ├── BatteryModeDrawer.qml      # NEW — TLP/power-profile drawer
    │   ├── PowerMenuView.qml          # NEW — lock/sleep/restart/shutdown
    │   ├── ControlSliderCard.qml
    │   ├── MatteSurface.qml
    │   └── cards/
    │       ├── QuickTogglesCard.qml   # NEW
    │       ├── BrightnessCard.qml     # NEW
    │       ├── VolumeCard.qml         # NEW
    │       └── ConnectivityCardsRow.qml # NEW
    │
    └── connectivity/
        ├── ConnectivityDetailShell.qml
        ├── WifiDetailPanel.qml        # NEW — split out of ConnectivityDetailPanel.qml
        ├── BluetoothDetailPanel.qml   # NEW
        ├── PowerDetailPanel.qml       # NEW
        └── BluetoothDeviceRow.qml
```

> This is the *original* plan, kept for the record — it didn't all ship this
> way. `IslandGestures.qml` was never built (gesture handling stayed inside
> `IslandCapsule.qml`). The `controlcenter/cards/` split was dropped (Phase 3).
> `BatteryModeDrawer.qml` shipped as `BatteryModeController.qml` with a
> different shape (component inheritance, not instantiate-as-child) once the
> `provider` contract turned out not to support it. See README.md for the
> structure that actually shipped.

`ConnectivityDetailPanel.qml` was retired once its three `panelKind` branches
became the three files above. Everything else not listed as removed kept
its current filename, just moved.

## New shared-logic modules this introduced

- **`island/IslandCommands.js`** (`pragma library`) — shared toggle/close
  helper consulted by the IPC wrapper functions and
  `handleConfiguredClickAction()` for the panels where both call sites
  behave identically.
- **`calendar/CalendarMath.js`** — pure day-grid functions
  (`daysInMonth`/`firstDayOfWeek`/`getWeekNumber`/etc.), zero UI coupling.
- **`wallpaper/WallpaperConfig.js`** — pure validators
  (`boundedInt`/`boundedReal`/`nonEmptyString`/`validTransitionType`).
- **`wallpaper/scripts/*.py`** — the wallpaper scan/apply Python source,
  formerly embedded as JS template-string properties inside
  `WallpaperPickerLayer.qml`, now real `.py` files referenced by path.

## Explicit non-goals

- **Splitting `islandState` itself out of `IslandWindow.qml`.** It's read
  from `mainCapsule`'s geometry switches, `Keys.onPressed`, the click-action
  handler, and the visibility-flag block — six-plus places. Promoting it to
  a separate `IslandStateMachine.qml` buys organizational purity but risks
  far more breakage than it's worth. `islandContainer` (the state machine +
  its derived flags) stays in `IslandWindow.qml`.
- **Deduping the swipe-physics math** shared between `capsuleMouseArea`,
  `twoFingerTouchArea`, and `IslandRootGestureArea.qml`. Genuinely
  near-duplicate code, but animation/gesture math is the easiest kind of
  thing to subtly break in a refactor. Worth a `SwipePhysics.js` extraction
  someday, but as its own separate, carefully-tested task.
- **Building the application launcher / file shelf / clipboard history
  panels.** Their half-built `islandState` plumbing (state flags, capsule
  sizing, IPC toggle functions, keyboard-focus/mask wiring, with zero visual
  component behind any of it) was removed rather than finished or kept
  around. If these come back, they get designed and built as real features,
  not resurrected from leftover scaffolding.
- **Splitting the four visual cards inside `ControlCenterView.qml`**
  (quick-toggles, brightness, volume, connectivity row) — see Phase 3/6, same
  reasoning: real sibling-to-sibling coupling that isn't worth the
  indirection to untangle for the size win.

## Migration plan

### Validation ritual (applied to every phase below)

1. Character-count brace/paren balance check on every file touched.
2. `qmllint -I qml -I . <file>` on every touched file — must produce no new
   errors (only known pre-existing false positive: `HyprlandDispatch.qml`
   crashes qmllint by itself, unrelated to any edits here).
3. **Actually relaunch** `quickshell -c ~/Projects/shitthatiamtestting/Tide-island`
   and manually retest the specific feature(s) touched. qmllint is syntax-only
   — it cannot catch the kind of runtime-only breakage this project hit
   multiple times (wrong Quickshell API shape, missing `PwObjectTracker`
   binding, singleton signal-timing races, QML's per-document `id:` scoping).
   No phase counted as done without a real relaunch test, and the riskier
   phases (3, 4, 6) needed a full `quickshell ipc call` sweep across every
   panel, not just a load-and-exit check.

### Phase 0 — Safety net — done

- `git init` + initial commit of the working tree. There was no git history
  for this project before this refactor, which would have made a change this
  size much riskier to do safely (no diffs, no easy revert).

### Phase 1 — Pure moves (no logic changes, just relocation + import paths) — done

Mechanical `git mv` + updating `import "../X"` strings at call sites, in
order of increasing blast radius:

1. `workspace/` group (fewest external references)
2. `weather/` group
3. `calendar/` group
4. `wallpaper/` group (move only — splitting the Python strings out was Phase 5)
5. `player/` group (move only — splitting pages was Phase 2)
6. `services/` group
7. `notifications/` group (touches both `island/` and `controlcenter/`
   import sites)
8. **Last**: rename + relocate `DynamicIslandWindow.qml` →
   `island/IslandWindow.qml`, updating `shell.qml`'s import and
   instantiation (`DynamicIslandWindow { ... }` → `IslandWindow { ... }`).
   The root component — a full app relaunch + smoke test happened right
   after this one, before moving to Phase 2.

### Phase 2 — Extract self-contained sub-components (behavior-preserving) — done

- `TimerBubble.qml` out of `IslandWindow.qml` (confirmed zero external
  coupling beyond bindings already passed in).
- `ConnectivityDetailShells.qml` grouping the 3 shell instantiations out of
  `IslandWindow.qml`.
- `PowerMenuView.qml` out of `ControlCenterLayer.qml`.
- Split `ConnectivityDetailPanel.qml` into `WifiDetailPanel.qml` /
  `BluetoothDetailPanel.qml` / `PowerDetailPanel.qml`; `ConnectivityDetailShell.qml`
  picks which to instantiate based on `panelKind` instead of one file
  branching three ways internally.
- Split `ExpandedPlayerLayer.qml`'s two pager pages into `MusicPage.qml` /
  `TimerPage.qml`; kept the pager shell + its externally-called
  `grabKeyboardFocus()`/`openTimerPage()` on the top-level file.

Each extraction's specific panel was tested individually, not batched.

### Phase 3 — Extract `ControlCenterLayer.qml`'s sub-controllers (biggest win) — done, scope adjusted

**What actually shipped, and why it's not quite what was planned:** the
original plan called for `ConnectivityController.qml` to be instantiated as
a child (`provider: connectivityController`) the same way `TimerBubble` and
`PowerMenuView` were. That doesn't work — the `provider` contract
consumed by the wifi/bluetooth/power detail panels is satisfied by the
*whole* `controlCenter` object (power's `triggerLock`/`triggerSleep`/etc.
live on `controlCenter` itself, not in the wifi/bluetooth domain), so
swapping `provider` to point at a separate child object would break the
power panel. Re-exposing ~40 wifi/bluetooth members via `property alias` +
wrapper functions was the fallback, but that reintroduces exactly the
boilerplate the extraction was meant to remove, with real risk of a
copy-paste mismatch in hard-won wifi/bluetooth logic.

Instead, this uses **QML component inheritance**: `ConnectivityController.qml`
is a standalone `Item` type holding all wifi+bluetooth state/actions;
`BatteryModeController.qml`'s root is `ConnectivityController { ... }` and
adds the TLP/power-profile state/actions; `ControlCenterLayer.qml`'s root is
`BatteryModeController { id: controlCenter }`. Every member from both bases
is directly accessible as `controlCenter.*` — zero forwarding code, and the
`provider` contract keeps pointing at `controlCenter` unchanged. QML
resolves identifiers dynamically against the live object's full property
table, not lexically against the file that declared the code, so this works
in both directions (derived code calling a base member, *and* a base
type's own function bodies calling something only the final derived type
declares, e.g. `ConnectivityController`'s `connectWifiNetwork()` calling the
`trimString()` helper that only exists on `ControlCenterLayer.qml`) —
verified empirically with a standalone quickshell test before relying on it.

1. **`ConnectivityController.qml`** — all wifi+bluetooth properties,
   functions, `Connections`, and the bluetooth device-state-observer
   `Repeater`. ~580 lines.
2. **`BatteryModeController.qml`** — TLP/power-profile state,
   functions, the `Connections { target: SystemServices }` handlers for
   `onTlpStateReady`/`onTlpSetFinished` (split out of a block that also
   handles brightness/volume, which stayed on `ControlCenterLayer.qml`),
   and the two battery timers. ~300 lines. `controlCenterExtraHeight`/
   `controlCenterMaximumExtraHeight` stayed on `ControlCenterLayer.qml` as
   originally planned — no forwarding needed, they just read their inherited
   `batteryDrawerProgress` etc. by bare name.
3. **The four visual cards (`cards/QuickTogglesCard.qml`, etc.) — dropped
   from this pass.** Reading the actual layout code showed they're more
   cross-coupled than the original audit assumed: `batteryDrawer.cardWidth`
   reads `connectivityCardsRow.spacing` directly, and the root-level
   `Behavior on displayedBrightness`/`displayedVolume` read
   `brightnessCard.pressed`/`volumeCard.pressed` directly. Splitting them
   out would mean threading several sibling-to-sibling bindings through as
   properties for a much smaller size win than the controller extraction —
   not worth the added indirection.

Result: `ControlCenterLayer.qml` went from 2483 lines to 1569 at this point
(later reduced further in Phase 6).

### Phase 4 — Collapse the triplicated panel-toggle logic — done, scope adjusted

**Reality check vs. the plan:** re-reading the current code (after Phases
1-3) showed the "~25 near-identical triples" was an overstatement. Several
of the root-level `showXWindow`/`toggleXWindow` functions (clock, timer,
custom info, lyrics, swipe-left/right, wallpaper picker) either aren't
toggle-shaped at all or only exist at one call site. The genuine duplication
— the exact same `if (state === X) smartRestoreState(); else showX();`
shape appearing in *both* the root IPC wrappers *and*
`handleConfiguredClickAction()`'s switch — was really just **weather,
calendar, and notificationCenter**. `controlCenter` and `expandedPlayer`
looked identical at a glance but each has one real, pre-existing behavioral
difference between its two call sites (`toggleControlCenterWindow` resets
`powerViewActive` on open, its click-action counterpart doesn't;
`toggleExpandedPlayer`'s click-action path calls `autoHideTimer.stop()`
before closing, its root counterpart doesn't) — unifying those would have
silently changed one of the two behaviors, so they stayed hand-written.

Shipped `island/IslandCommands.js` (`.pragma library`) with `toggle(container,
key, showFn)` / `close(container, key)` covering `weather`, `calendar`,
`notificationCenter`, `wallpaperPicker` (root-only, but same shape), and
`controlCenter` (click-action path only, since that's the one *without* the
`powerViewActive` side effect). Both the root wrapper functions and the
click-action switch now call into it for those five panels; `controlCenter`'s
root wrapper, `expandedPlayer` (both call sites), and the power-menu function
stayed exactly as they were, with a comment in `IslandCommands.js` explaining
why they're not folded in.

**A real regression, caught by actually testing:** the Phase 3 controller
extraction turned out to have broken bluetooth-panel-close and the battery
drawer's drag-to-cancel-settle behavior. Root cause: QML `id:` scoping is
**per-document, not inherited** — a `Timer { id: bluetoothScanStopTimer }`
declared inside `ConnectivityController.qml` is invisible by that name from
`ControlCenterLayer.qml`, even though `ControlCenterLayer.qml`'s root
*extends* `ConnectivityController` and freely inherits its *properties* and
*functions* by bare name. `qmllint` did not catch this on either file. It
only surfaced by actually launching the shell and exercising the toggles
over real IPC calls (`quickshell ipc -p <path> call tide toggleControlCenter`
etc.) and reading the shell's own log output for `ReferenceError`s — a
"launch and see if it loads" smoke test is not enough for this class of bug.
Fixed by adding small wrapper functions (`startBluetoothScanForPanel()`,
`stopBluetoothActivityForPanelClose()`, `stopBatteryDrawerSettle()`) next to
the timers in the files that declare them, since *functions* do cross the
inheritance boundary safely — only bare `id:` references don't. Anyone doing
further work on this inheritance chain should assume the same: properties
and functions inherit, `id:`-based references never do.

### Phase 5 — Low-priority hygiene extractions — done

- **`shell.qml`'s `IpcHandler` blocks → `qml/ipc/{Overview,Island,Tide}Ipc.qml`.**
  Discovered along the way: `IpcHandler` reflects *every* property declared
  directly on it as an IPC-facing property, and warns loudly at startup for
  any that aren't IPC-marshalable — which a plain object reference like
  `shellRoot` never is. Declaring `required property var shellRoot` straight
  on the handler produced three `Type QVariant cannot be used across IPC`
  warnings per launch. Fixed by wrapping each handler in a plain `QtObject`
  that holds `shellRoot` and exposes the `IpcHandler` as one of its own
  properties — only the handler's own functions are then part of its
  reflected surface. Verified warning-free and re-tested every `tide`/
  `island`/`overview` IPC call afterward.
- **`calendar/CalendarMath.js`** — `daysInMonth`, `daysInPrevMonth`,
  `firstDayOfWeek`, `getWeekNumber` pulled out as a `.pragma library` module;
  `CalendarLayer.qml` calls them as `CalendarMath.fn(...)` instead of
  `root.fn(...)`. Verified via a real `toggleCalendar` IPC round-trip.
- **`wallpaper/WallpaperConfig.js`** — `boundedInt`, `boundedReal`,
  `nonEmptyString`, `validTransitionType` pulled out the same way.
  `validTransitionType` now takes `transitionTypes` as a parameter instead
  of reading it off `root`, since a `.pragma library` module has no `root`
  to read from.
- **Wallpaper scan/apply Python source → real `.py` files.** Was two
  `readonly property string` values built from string concatenation, passed
  to `python3 -c <script>`. Now `wallpaper/scripts/scan_wallpapers.py` and
  `wallpaper/scripts/apply_wallpaper.py`, invoked as `python3 <path>
  <args...>` with `Qt.resolvedUrl("scripts/scan_wallpapers.py").toString()
  .replace("file://", "")` resolving the real filesystem path relative to
  the QML file — `sys.argv` indexing is unaffected either way, since
  `argv[0]` is the script identifier and the real arguments start at
  `argv[1]` in both invocation styles. Verified both scripts still
  byte-for-byte match the original inline source (`python3 -m py_compile`
  clean) and exercised a real wallpaper-picker open over IPC afterward.

## Resolved decisions

Both open questions from the original plan were settled ahead of the
phased migration:

1. **Duplicate IPC namespaces → collapsed.** The standalone `clipboard`,
   `weather`, and `calendar` top-level `IpcHandler` targets were removed
   from `shell.qml`. `weather.refresh` became `tide.refreshWeather`.
   Everything panel-related now lives under the single `tide` namespace,
   matching what upstream's own README actually documented (it never
   mentioned the standalone targets). `overview` and `island` stay as their
   own targets — those are genuinely distinct concerns, not duplicates.
2. **The three unbuilt panels → removed.** All `application_launcher`,
   `file_shelf`, and `clipboard` `islandState` plumbing was deleted from
   `DynamicIslandWindow.qml` and `shell.qml`: the state-visibility flags,
   the three IPC wrapper functions per panel, the
   `handleConfiguredClickAction` cases, the capsule width/height/radius
   switch cases, and the file-shelf-specific auto-open bookkeeping
   (`fileShelfOpenedManually`, `closeAutoOpenedFileShelf`, etc.) that had no
   caller even before this cleanup.

## Phase 6 — view/logic split for the two remaining god files

After Phase 5, `ControlCenterLayer.qml` (1393 lines, after also extracting
`PowerActionsController.qml`) and `IslandWindow.qml` (2652 lines) were still
genuinely large — large enough that "the refactor is done" wasn't an honest
claim. The remaining size wasn't more hidden domains, though; in both files
it was one thing: a huge declarative visual tree sitting next to a much
smaller amount of real logic. That splits cleanly along a "view vs. logic"
line in a way that further domain-splitting can't, so this phase did exactly
that for both files.

**`ControlCenterLayer.qml` → `ControlCenterLayer.qml` (362 lines) +
`ControlCenterView.qml` (1046 lines).** The file's `Column { id: mainContent
}` — literally everything visual, ~1035 lines — moved out wholesale.
`ControlCenterView.qml` takes `controlCenter` as an explicit property (it
can't inherit the controller chain the way `ControlCenterLayer` does,
since a separate file extending the same base types would instantiate its
*own* independent copy of the state, not share the live object). The ~150
bare references to `controlCenter`'s members inside that tree were rewritten
to `controlCenter.member` by a scripted pass — cross-checked against every
locally-declared id and property inside the column first, to rule out
collisions — rather than by hand; manually prefixing hundreds of references
across 1035 lines was judged too error-prone to trust.

**`IslandWindow.qml` → `IslandWindow.qml` (1918 lines) + `IslandCapsule.qml`
(769 lines).** The `Rectangle { id: mainCapsule }` block — the pill's visual
shape, clock, icons, gesture handling, and the 11 `Loader`s that mount every
sub-panel — moved out the same way, taking `root` and `islandContainer` as
explicit properties. Unlike the control-center split, the new instance keeps
the *same id* (`IslandCapsule { id: mainCapsule }`) at its instantiation
site, so the ~19 existing `mainCapsule.foo` references elsewhere in
`IslandWindow.qml` needed no changes at all.

**Two real bugs, both caught by actually exercising the app, not by
`qmllint`:**

1. The scripted prefixing pass corrupted property *assignments* where a
   child component's own property name happened to match a state-object
   member — e.g. `WeatherIcon`'s `iconFontFamily: controlCenter.iconFontFamily`
   became the invalid `controlCenter.iconFontFamily: controlCenter.iconFontFamily`.
   45 such corruptions in `ControlCenterView.qml` and another 45 in
   `IslandCapsule.qml`, all found and fixed the same way: search for
   `<name>.<member>:` (a qualified name sitting in property-key position,
   which is never valid QML) and un-qualify the key while leaving the value
   qualified.
2. Both splits left behind bare references to ids that used to be reachable
   for free (single file, QML's per-document id scoping) and now weren't:
   `ControlCenterLayer.qml`'s brightness/volume-slider `Behavior`s read
   `brightnessCard.pressed`/`volumeCard.pressed` by bare id, and
   `IslandWindow.qml`'s root-level functions and computed properties read
   eight different Loaders and the capsule's own `MouseArea` by bare id
   (`controlCenterLoader`, `overviewLoader`, `capsuleMouseArea`, etc. — 44
   call sites across the file, not a handful). Both fixed the same way as
   the Phase 3 regression: expose the needed child as
   `readonly property alias name: name` on the new view/capsule file, then
   reach it through that file's own instantiation id
   (`controlCenterView.brightnessCardPressed`, `mainCapsule.controlCenterLoader`).

Every step was verified with a full `quickshell ipc call` sweep — overview,
island show/hide, weather, calendar, notification center, wallpaper picker,
control center, power menu, player, timer, clock/lyrics/swipe — after each
extraction, not just a load-and-exit smoke test.

**Deliberately not done, for the same reason as before:** `islandState`
itself, and the four visual cards inside `ControlCenterView.qml`
(quick-toggles, brightness, volume, connectivity row) are not split further.
Both would require threading many more sibling-to-sibling bindings through
as properties for a much smaller size win than this phase's split — not
worth the added indirection.

## Phase 7 — direct-open panels, weather rework, Control Center content swap

**Status: all three parts shipped.** Unlike Phases 1–6, this isn't a
file-structure refactor — it's real behavior/content changes, grilled out
before writing any code so the reasoning is captured here rather than
rediscovered later.

**1. Direct-open connectivity panels — done.** Today `tide` only had
`toggleControlCenter` — there was no single call that opened Control Center
already expanded to one connectivity detail. Added, on `IslandWindow.qml` /
`TideIpc.qml`:
- `showWifiWindow()` / `showBluetoothWindow()` (IPC: `showWifi` /
  `showBluetooth`), each calling `islandContainer.showControlCenter()` then
  `mainCapsule.controlCenterLoader.item.setConnectivityPanelOpen(kind,
  true)` — the same path a real click on the wifi/bluetooth card already
  took, so the card itself and the mounted detail overlay both end up in the
  correct "open" state, not just the overlay. One IPC call now opens Control
  Center pre-expanded to that detail, instead of "open Control Center, then
  tap the card" by hand. Verified over real `quickshell ipc call` + `grim`
  screenshots for both.
- `showPowerMenuWindow()` (IPC: `showPowerMenu`) — a `show`-not-`toggle`
  sibling of the existing `togglePowerMenuWindow()`, since a direct-open
  shortcut should always land on the power menu, never close it. Verified
  the same way; the 5-icon row (see part 3) rendered correctly.
- **Explicitly not** reviving `panelKind: "power"`
  (`PowerDetailPanel.qml`, wired end-to-end through
  `ControlCenterLayer.setConnectivityPanelOpen("power", …)` /
  `IslandWindow.setConnectivityDetailVisible("power", …)` but with zero UI
  entry points anywhere) — confirmed dead code, a near-duplicate of
  `PowerMenuView` minus Logout. Left alone, not deleted, not built on.
- Hyprland keybinds (e.g. mirroring Omarchy's `SUPER+CTRL+W` →
  network-panel scheme) are **not** this repo's concern — they get
  configured in the user's own `~/.config/hypr/bindings.lua`, outside this
  project, same as Omarchy's own bindings are never touched here.

**2. Weather rework (`qml/weather/WeatherService.qml`) — done.** Old
implementation was a single `wttr.in/<location>?format=j1` XHR fetch for
everything (current conditions + forecast + display name) — chosen as
unreliable/inaccurate in practice. Replaced with:
- `api.open-meteo.com/v1/forecast` (coordinate-based) as the sole weather
  data source once a location is known — current conditions, 3-day forecast,
  sunrise/sunset, UV index, all in one call. WMO weather codes (Open-Meteo's
  scheme) mapped to the same `weatherType`/`iconGlyph`/`iconColor` buckets
  `WeatherIcon.qml` already understood, so that file needed no changes.
  Verified the exact response shape against the live API with `curl` before
  writing the parser, not guessed from memory.
- `wttr.in` kept for exactly one thing: `wttr.in/?format=%l` IP-based
  auto-location when no location is configured yet (Open-Meteo has no
  equivalent). **Not** used as a data-format fallback as originally
  sketched — a single data source is easier to keep correct than two
  parallel parsers, and Open-Meteo alone covers everything the UI needs.
  **Bug caught by testing, not review:** wttr.in serves a full HTML page
  instead of the requested plain-text `%l` format when the User-Agent
  doesn't look like curl — Qt's `XMLHttpRequest` looks like a browser by
  default, so every auto-detect call was silently getting an HTML document
  back (surfaced as "Location not found: <!DOCTYPE html>..." in the UI).
  Fixed with an explicit `xhr.setRequestHeader("User-Agent", "curl/8.0")`,
  plus a defensive length/`<` check on the response as a second line of
  defense. Reproduced the exact failure with `curl -A "Mozilla/5.0..."`
  before fixing, to confirm the cause rather than guess at it.
- A location search/autocomplete UI in `WeatherLayer.qml` (click the pin
  icon or the location name), backed by `geocoding-api.open-meteo.com/v1/
  search`, debounced 300ms, with stale-response protection (a query that
  moved on while a request was in flight can't clobber a newer one). There
  was previously no location input at all — `displayLocation` was read-only
  text.
- The chosen location (lat/lon + display name) persists across shell
  restarts via `FileView` + `JsonAdapter` at
  `~/.local/state/tide-island/weather-location.json`, read on startup and
  falling back to `UserConfig.weatherLocation`/auto-detect if absent or not
  yet `configured`. This is the first place in the project where a runtime
  choice gets written back to disk — every other setting lives in the
  hand-edited, `readonly` `UserConfig.qml` singleton. Verified `FileView`
  auto-creates missing parent directories on write and correctly no-ops
  (`onLoadFailed`) on a missing file, with a standalone throwaway QML
  harness, before wiring it into the real service. Considered and rejected:
  skip persistence and
  make the search UI a one-time lookup you hand-copy into
  `UserConfig.weatherLocation` yourself — rejected because search-and-remember
  is the actual point.
- **Second bug caught by testing:** a persisted (search-picked) location
  intermittently reverted to the auto-detected one on startup. Root cause:
  `property bool weatherEnabled: userConfig ? userConfig.weatherEnabled :
  true` is a *binding*, not a plain default — its first evaluation counts as
  a change from bool's zero-value (`false`) to `true`, so `onWeatherEnabledChanged`
  fired once during construction, before the `FileView` had a chance to load
  the persisted location. That kicked off the auto-detect chain (3 sequential
  network round-trips) racing the persisted-location fetch (1 round-trip);
  whichever finished last silently won. Confirmed with a standalone headless
  harness logging the actual call order, not by staring at the code. Fixed
  with a `_bootstrapped` flag set only once, inside the `FileView`'s
  `onLoaded`/`onLoadFailed`, that gates `onWeatherEnabledChanged` and
  `onLocationChanged` — they now only react to *genuine* post-startup
  changes, never the initial binding-evaluation firing. Re-verified with the
  same harness after the fix.

**3. Control Center content swap — done.** In `ControlCenterView.qml`:
- Removed the `brightnessCard`/`volumeCard` `ControlSliderCard`s (Display /
  Sound sliders) and the Silent(focus)/Night-mode two-button row —
  redundant with existing hardware/OSD controls. `ControlSliderCard.qml`
  deleted outright (nothing else instantiated it). All slider-only plumbing
  in `ControlCenterLayer.qml` (local/pending/displayed/lastApplied volume
  and brightness, the intro-animation timer, the `SystemServices` brightness/
  volume `Connections` block, both apply timers) was removed too — it only
  ever existed to serve those two sliders. `focusEnabled`/`toggleFocus` and
  `nightLightEnabled`/`toggleNightLight` themselves were **kept**: they sync
  to `shellRootController` and have callers beyond the deleted card, so only
  their Control Center buttons went away, not the underlying feature.
- Added a new always-visible row (`actionsCard`) with three buttons:
  **Theme** (rendered now, disabled/dimmed — no theme system exists yet,
  wired up later without a layout change), **Wallpaper** (new
  `wallpaperRequested()` signal on `ControlCenterLayer.qml`, wired the same
  way `weatherRequested`/`calendarRequested` already are, opening the
  existing `WallpaperPickerLayer.qml`), **Power** (sets `powerViewActive =
  true` — same effect as `togglePowerMenuWindow()`, but from a click; there
  was previously no on-screen button that reached `PowerMenuView` at all,
  only IPC/configured-mouse-action).
- Added **Logout** as a 5th action on `PowerActionsController.qml` /
  `PowerMenuView.qml`, alongside Lock/Sleep/Restart/Shutdown — same pattern
  as the existing ones (a `Process`), running `hyprctl dispatch exit`,
  falling back to `loginctl terminate-session`.
- **Plan correction, caught by the user after the first visual pass:** the
  original plan reused the existing collapsible "battery drawer" slot (a
  pull-down handle that revealed Silent/Night-mode, or the whole row when
  TLP was off) for the new Theme/Wallpaper/Power row, since that was the
  Silent/Night-mode row's old location. The user wanted these — and the
  Battery/TLP mode card beside them — visible immediately, the same as the
  Wi-Fi/Bluetooth row, not behind a pull gesture. Fixed by promoting both to
  always-visible rows and deleting the entire drawer/handle-drag mechanism
  (`batteryDrawerOpen`/`Dragging`/`Progress`/`Settling`/`Moving`,
  `setBatteryDrawerOpen`/`toggleBatteryDrawer`/`stopBatteryDrawerSettle`,
  the handle `MouseArea`'s drag math, `batteryDrawerHandleHeight`/
  `batteryDrawerContentGap`) from `BatteryModeController.qml` and
  `ControlCenterView.qml` — none of it had another caller once nothing was
  left to reveal. `controlCenterExtraHeight`/`controlCenterMaximumExtraHeight`
  (`ControlCenterLayer.qml`) collapsed from a drag-progress interpolation
  into a static `tlpControlsEnabled ? (batteryModeCardHeight + 12) : 0`,
  since the battery card's presence is now a fixed per-session fact, not
  something that animates open/closed.
- **Follow-on bug, also caught visually:** the Control Center window's
  height is a hardcoded constant (`320` pre-Phase-7) plus
  `controlCenterExtraHeight`, computed independently in `IslandCapsule.qml`
  and `IslandWindow.qml` rather than measured from actual content — a
  pre-existing fragility, not something this phase introduced. Removing the
  sliders and adding two always-visible rows shifted the true content
  height enough that the first working version clipped the bottom of the
  Battery card. Recalibrated by hand to `236 + controlCenterExtraHeight`
  (content height plus the `anchors.margins: 12` top/bottom, which the
  original `320` estimate had also implicitly absorbed) and reverified with
  a screenshot. If Control Center content changes again, re-check this
  constant the same way — it is not derived, it is tuned.
- Verified with `qmllint` (all touched files clean beyond the environment's
  own missing-import-path noise) and an actual `quickshell -c` relaunch +
  `quickshell ipc call tide toggleControlCenter` + `grim` screenshot, at
  each step, per this project's usual testing discipline.
