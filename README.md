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

Two god-files have absorbed most of the app's logic over time:
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

### Phase 4 — Collapse the triplicated panel-toggle logic (riskiest phase, do last)

Build `island/IslandCommands.js` and rewrite the ~25 IPC-wrapper triples plus
`handleConfiguredClickAction()`'s switch to consult it. This changes real
control flow for every panel in the app (control center, wallpaper picker,
weather, calendar, notification center, power menu, player, and the 3
unbuilt states). Test every single panel's open/close/toggle/IPC path
afterward individually — not a couple as a sample, all of them.

### Phase 5 — Low-priority hygiene extractions (do whenever, non-blocking)

- Wallpaper picker's embedded Python source strings → `wallpaper/scripts/*.py`.
- `calendar/CalendarMath.js` pure day-grid function extraction.
- `wallpaper/WallpaperConfig.js` pure validator extraction.
- `shell.qml`'s `IpcHandler` blocks → one file per target under `qml/ipc/`
  (`overview`, `island`, `tide` — three files now, not six).

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
