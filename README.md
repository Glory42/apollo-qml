# Tide Island (this fork)

A Dynamic-Island-style widget for Hyprland, built entirely in QML on top of
Quickshell's native modules (`Quickshell.Bluetooth`, `Quickshell.Networking`,
`Quickshell.Services.{Pipewire,UPower,Mpris,Notifications}`,
`Quickshell.Hyprland`). There is no C++ backend — the original upstream
project's `IslandBackend` plugin and its companion apps/tests/installer have
been removed. This copy is meant to be generic across Hyprland setups, not
tied to any one specific distro's desktop tooling (see "Portability" below).

Run it with:

```bash
quickshell -c ~/Projects/shitthatiamtestting/Tide-island
```

`shell.qml` is the entry point Quickshell loads.

## Features

- Persistent clock + resting pill
- Music player (MPRIS) with lyrics
- Control Center (volume, brightness, wifi, bluetooth, night light, focus/DND,
  power profile / TLP mode, power menu)
- Notifications (toast + history/center)
- Timer
- Weather & forecast
- Calendar
- Wallpaper switcher
- Workspace overview (Hyprland)
- Bluetooth pairing/connection flows, wifi connect/forget flows

Upstream also had an application launcher, file shelf, and clipboard
history — this fork never built visuals for them, and the unused
`islandState` plumbing for all three has since been removed (see the
resolved "unbuilt panels" question below).

## Portability

This project targets whatever Hyprland "rice" it ends up living on — **not**
specifically the Omarchy setup used for day-to-day development/testing on
this machine. Only genuinely standard, cross-distro tools are treated as
real integrations worth fixing when broken: `powerprofilesctl`,
`brightnessctl`, `hyprsunset`/`gammastep`, `systemctl`, native Pipewire/
UPower/Bluetooth/Networking via Quickshell's own modules. Tools like `awww`
(wallpaper apply), `hyprlock`/`swaylock`/`i3lock` (lock), `wl-clipboard`/
`cliphist` (clipboard) are upstream's intended tools for the eventual target
system and should **not** be swapped for distro-specific alternatives just
because they aren't installed on the current dev machine.

---

# Architecture Refactor Plan

**Status: all 5 phases complete.** `DynamicIslandWindow.qml` (3090 lines) is
now `qml/island/IslandWindow.qml`; `ControlCenterLayer.qml` went from 2483 to
1569 lines; `shell.qml` went from ~440 to 196. Every phase was verified with
`qmllint` plus an actual `quickshell` relaunch, and every panel's
toggle/open/close was re-tested over real `quickshell ipc call` invocations
after Phase 3's and Phase 5's file moves specifically (not just a clean-load
smoke test — see Phase 4's writeup for why that distinction mattered). One
pre-existing, unrelated bug was surfaced along the way and left alone:
`WallpaperPickerLayer.qml` reads `userConfig.wallpaperPywalEnabled` and
`userConfig.wallpaperTransitionInvertY`, neither of which exist on
`UserConfig.qml` — both silently resolve to `undefined`/`false`. Not
introduced by this refactor (verified pre-existing), not a structural issue,
so it wasn't fixed here.

Two god-files had absorbed most of the app's logic over time:
`DynamicIslandWindow.qml` (~3090 lines) and
`qml/controlcenter/ControlCenterLayer.qml` (~2480 lines). Several other files
are large enough to be worth splitting too. This section is the plan for
turning the current flat/oversized layout into a properly organized,
domain-based file structure — written out fully before any code moves, per
the workflow we're using: plan the structure, plan the migration, execute in
small verified steps.

## Why these two files got this big

**`DynamicIslandWindow.qml`** mixes together: layer-shell/window setup, the
`islandState` string state machine (~16 states) and ~50 derived visibility
flags, ~25 near-identical IPC wrapper function triples
(`toggleXWindow`/`showXWindow`/`closeXWindow` per panel), a second
duplicate of the same toggle/open/close logic in
`handleConfiguredClickAction()`, the `mainCapsule` visual (clock, icons,
mouse/touch gesture handling with its own swipe-physics math), a
self-contained floating timer-ring widget (`timerBubble`), and 11 `Loader`
blocks wiring in the real sub-panel files (these Loaders are already clean —
not a splitting target themselves).

**`ControlCenterLayer.qml`** bolts together four largely independent
concerns behind one `Item`: volume/brightness slider plumbing, the
TLP/power-profile battery-mode drawer, wifi state+logic, and bluetooth
state+logic. The wifi/bluetooth half is *already* consumed by
`ConnectivityDetailPanel.qml`, `ConnectivityDetailShell.qml`, and
`BluetoothDeviceRow.qml` through a 40-property `provider` interface — meaning
it's already shaped like a separate controller, just not physically
separated yet.

Full per-file structural notes (section line ranges, what's self-contained,
what's cross-cutting, what's called from outside the file) came from a
dedicated audit pass and are summarized in the phase descriptions below.

## Target file structure

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
    ├── controlcenter/                 # shrank from 2483 to 1569 lines
    │   ├── ControlCenterLayer.qml     # extends BatteryModeController
    │   ├── BatteryModeController.qml  # NEW — extends ConnectivityController;
    │   │                               TLP/power-profile state + actions
    │   ├── ConnectivityController.qml # NEW — extends Item; wifi+bluetooth
    │   │                               state + actions (base of the chain)
    │   ├── PowerMenuView.qml          # NEW — lock/sleep/restart/shutdown
    │   ├── ControlSliderCard.qml
    │   └── MatteSurface.qml
    │
    └── connectivity/
        ├── ConnectivityDetailShell.qml
        ├── WifiDetailPanel.qml        # NEW — split out of ConnectivityDetailPanel.qml
        ├── BluetoothDetailPanel.qml   # NEW
        ├── PowerDetailPanel.qml       # NEW
        └── BluetoothDeviceRow.qml
```

`ConnectivityDetailPanel.qml` is retired once its three `panelKind` branches
become the three files above. Everything else not listed as removed keeps
its current filename, just moves.

## New shared-logic modules this introduces

- **`island/IslandCommands.js`** (`pragma library`) — a single table mapping
  panel key → `{ stateName, show(container), ... }`, consulted by the IPC
  wrapper functions and `handleConfiguredClickAction()` instead of both
  independently hardcoding the same ~10-panel list.
- **`calendar/CalendarMath.js`** — pure day-grid functions
  (`daysInMonth`/`firstDayOfWeek`/`getWeekNumber`/etc.), zero UI coupling.
- **`wallpaper/WallpaperConfig.js`** — pure validators
  (`boundedInt`/`boundedReal`/`nonEmptyString`/`validTransitionType`).
- **`wallpaper/scripts/*.py`** — the wallpaper scan/apply Python source,
  currently embedded as JS template-string properties inside
  `WallpaperPickerLayer.qml`, moved to real `.py` files referenced by path.

## Explicit non-goals

- **Splitting `islandState` itself out of `IslandWindow.qml`.** It's read
  from `mainCapsule`'s geometry switches, `Keys.onPressed`, the click-action
  handler, and the visibility-flag block — six-plus places. Promoting it to
  a separate `IslandStateMachine.qml` buys organizational purity but risks
  far more breakage than it's worth. `islandContainer` (the state machine +
  its derived flags) stays in `IslandWindow.qml` even after every other
  phase completes.
- **Deduping the swipe-physics math** shared between `capsuleMouseArea`,
  `twoFingerTouchArea`, and `IslandRootGestureArea.qml`. Genuinely
  near-duplicate code, but animation/gesture math is the easiest kind of
  thing to subtly break in a refactor. Worth a `SwipePhysics.js` extraction
  someday, but as its own separate, carefully-tested task — not part of this
  pass.
- **Building the application launcher / file shelf / clipboard history
  panels.** Their half-built `islandState` plumbing (state flags, capsule
  sizing, IPC toggle functions, keyboard-focus/mask wiring, with zero visual
  component behind any of it) has been removed rather than finished or kept
  around. If these come back, they get designed and built as real features,
  not resurrected from leftover scaffolding.

## Migration plan

### Validation ritual (applies to every phase below)

1. Character-count brace/paren balance check on every file touched.
2. `qmllint -I qml -I . <file>` on every touched file — must produce no new
   errors (only known pre-existing false positive: `HyprlandDispatch.qml`
   crashes qmllint by itself, unrelated to our edits, confirmed earlier).
3. **Actually relaunch** `quickshell -c ~/Projects/shitthatiamtestting/Tide-island`
   and manually retest the specific feature(s) touched. qmllint is syntax-only
   — it cannot catch the kind of runtime-only breakage this project has
   already hit multiple times (wrong Quickshell API shape, missing
   `PwObjectTracker` binding, singleton signal-timing races). No phase is
   "done" without a real relaunch test.

### Phase 0 — Safety net — done

- `git init` + initial commit of the current working tree. There is
  currently no git history for this project, which makes a refactor this
  size much riskier to do safely (no diffs, no easy revert). Do this before
  moving anything.

### Phase 1 — Pure moves (no logic changes, just relocation + import paths) — done

Mechanical `git mv` + updating `import "../X"` strings at call sites, in
order of increasing blast radius:

1. `workspace/` group (fewest external references)
2. `weather/` group
3. `calendar/` group
4. `wallpaper/` group (move only — splitting the Python strings out is
   Phase 5)
5. `player/` group (move only — splitting pages is Phase 2)
6. `services/` group
7. `notifications/` group (touches both `island/` and `controlcenter/`
   import sites)
8. **Last**: rename + relocate `DynamicIslandWindow.qml` →
   `island/IslandWindow.qml`, updating `shell.qml`'s import and
   instantiation (`DynamicIslandWindow { ... }` → `IslandWindow { ... }`).
   This is the root component — after this one, do a full app relaunch and
   smoke-test everything, not just one feature, before moving to Phase 2.

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
  `TimerPage.qml`; keep the pager shell + its externally-called
  `grabKeyboardFocus()`/`openTimerPage()` on the top-level file.

Test each extraction's specific panel individually after that extraction,
don't batch several before testing.

### Phase 3 — Extract `ControlCenterLayer.qml`'s sub-controllers (biggest win) — done, scope adjusted

**What actually shipped, and why it's not quite what was planned:** the
original plan called for `ConnectivityController.qml` to be instantiated as
a child (`provider: connectivityController`) the same way `TimerBubble` and
`PowerMenuView` were. That doesn't work here — the `provider` contract
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

1. **`ConnectivityController.qml`** (done) — all wifi+bluetooth properties,
   functions, `Connections`, and the bluetooth device-state-observer
   `Repeater`. ~580 lines.
2. **`BatteryModeController.qml`** (done) — TLP/power-profile state,
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
   not worth the added indirection. They stay composed together in
   `ControlCenterLayer.qml`'s `mainContent` Column, same as the decision to
   leave `islandState` alone in `IslandWindow.qml`.

Result: `ControlCenterLayer.qml` went from 2483 lines to 1569. Tested wifi,
bluetooth, and the battery drawer's `qmllint` + load cleanliness after each
extraction (interactive re-test of each still pending a real relaunch by
whoever's at the keyboard next).

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

Both open questions from the original plan have been settled and already
acted on, ahead of the phased migration below:

1. **Duplicate IPC namespaces → collapsed.** The standalone `clipboard`,
   `weather`, and `calendar` top-level `IpcHandler` targets have been
   removed from `shell.qml`. `weather.refresh` became `tide.refreshWeather`.
   Everything panel-related now lives under the single `tide` namespace,
   matching what upstream's own README actually documented (it never
   mentioned the standalone targets). `overview` and `island` stay as their
   own targets — those are genuinely distinct concerns, not duplicates.
2. **The three unbuilt panels → removed.** All `application_launcher`,
   `file_shelf`, and `clipboard` `islandState` plumbing has been deleted
   from `DynamicIslandWindow.qml` and `shell.qml`: the state-visibility
   flags, the three IPC wrapper functions per panel, the
   `handleConfiguredClickAction` cases, the capsule width/height/radius
   switch cases, and the file-shelf-specific auto-open bookkeeping
   (`fileShelfOpenedManually`, `closeAutoOpenedFileShelf`, etc.) that had no
   caller even before this cleanup. Verified brace-balanced and
   `qmllint`-clean on both files afterward.
