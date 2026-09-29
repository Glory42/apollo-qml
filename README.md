# My QML's

A Dynamic-Island-style widget for Hyprland, built entirely in QML on top of
Quickshell's native modules (`Quickshell.Bluetooth`, `Quickshell.Networking`,
`Quickshell.Services.{Pipewire,UPower,Mpris,Notifications}`,
`Quickshell.Hyprland`). There is no C++ backend — the original upstream
project's `IslandBackend` plugin and its companion apps/tests/installer have
been removed, and the file layout has been restructured heavily enough that
very little of this still resembles upstream Tide Island beyond the core
idea. See [ROADMAP.md](ROADMAP.md) for the full history of what changed and
why, and for what's still open.

This copy is meant to be generic across Hyprland setups, not tied to any one
specific distro's desktop tooling (see "Portability" below).

## Running it

```bash
quickshell -c ~/Projects/shitthatiamtestting/Tide-island
```

`shell.qml` is the entry point Quickshell loads. Control it remotely with
`quickshell ipc call <target> <function>` — see `qml/ipc/` for the available
targets (`overview`, `island`, `tide`).

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
`islandState` plumbing for all three has since been removed.

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

## Project structure

```
Tide-island/
├── shell.qml                          # entry point Quickshell loads
├── README.md
├── ROADMAP.md                         # refactor history + what's still open
└── qml/
    ├── common/                        # shared singletons + generic helpers
    │   ├── qmldir
    │   ├── StyleTokens.qml            # colors / spacing / design tokens
    │   ├── UserConfig.qml             # user-facing config (singleton)
    │   ├── SystemServices.qml         # power-profile/brightness/volume actions
    │   ├── CompositorBackend.qml      # Hyprland/niri compositor abstraction
    │   ├── HyprlandDispatch.qml       # thin Hyprland IPC dispatch helper
    │   └── BluetoothFormatting.js     # device name/address formatting
    │
    ├── ipc/                           # one file per `quickshell ipc call` target
    │   ├── OverviewIpc.qml
    │   ├── IslandIpc.qml
    │   └── TideIpc.qml                # every panel command lives under `tide`
    │
    ├── services/                      # headless trackers, no visuals
    │   ├── IslandClock.qml
    │   ├── IslandSystemState.qml      # battery/volume/brightness reactive state
    │   ├── IslandMprisController.qml
    │   └── BluetoothConnectionTracker.qml
    │
    ├── workspace/                     # Hyprland/niri workspace overview
    │   ├── WorkspaceLayer.qml
    │   ├── CompositorWorkspaceTracker.qml
    │   ├── HyprlandWorkspaceTracker.qml
    │   ├── HyprlandWindowIntegration.qml
    │   └── OverviewWallpaperCacheController.qml
    │
    ├── notifications/                 # toast + stored history + full panel
    │   ├── NotificationLayer.qml
    │   ├── NotificationHistory.qml
    │   └── NotificationCenterLayer.qml
    │
    ├── island/                        # the window/capsule hub
    │   ├── IslandWindow.qml           # root PanelWindow: layer-shell setup +
    │   │                              # the islandState state machine
    │   ├── IslandCapsule.qml         # the pill's shape/clock/icons/gestures;
    │   │                              # mounts every sub-panel Loader
    │   ├── IslandCommands.js          # shared toggle/close for panels whose
    │   │                              # two call sites behave identically
    │   ├── TimerBubble.qml            # floating timer-ring widget
    │   ├── ConnectivityDetailShells.qml # groups the wifi/bluetooth/power shells
    │   ├── SplitIconLayer.qml
    │   ├── OsdLayer.qml
    │   ├── IslandRootGestureArea.qml
    │   ├── BluetoothExpandedLayer.qml
    │   └── assets/                    # currently unreferenced leftover assets
    │
    ├── player/                        # expanded music/timer player
    │   ├── ExpandedPlayerLayer.qml    # 2-page pager shell
    │   ├── MusicPage.qml
    │   └── TimerPage.qml
    │
    ├── wallpaper/
    │   ├── WallpaperPickerLayer.qml
    │   ├── WallpaperConfig.js         # pure validators
    │   └── scripts/
    │       ├── scan_wallpapers.py
    │       └── apply_wallpaper.py
    │
    ├── weather/
    │   ├── WeatherLayer.qml
    │   ├── WeatherService.qml
    │   └── WeatherIcon.qml
    │
    ├── calendar/
    │   ├── CalendarLayer.qml
    │   └── CalendarMath.js            # pure day-grid math
    │
    ├── controlcenter/                 # split into view + a chain of domain
    │   │                              # controllers via QML component inheritance
    │   ├── ControlCenterLayer.qml     # pure logic; extends PowerActionsController
    │   ├── ControlCenterView.qml      # the visual tree (cards, sliders, drawer)
    │   ├── PowerActionsController.qml # extends BatteryModeController;
    │   │                              # night light + shutdown/restart/sleep/lock
    │   ├── BatteryModeController.qml  # extends ConnectivityController;
    │   │                              # TLP/power-profile state + actions
    │   ├── ConnectivityController.qml # extends Item; wifi+bluetooth
    │   │                              # (base of the inheritance chain)
    │   ├── PowerMenuView.qml
    │   ├── ControlSliderCard.qml
    │   └── MatteSurface.qml
    │
    └── connectivity/                  # wifi/bluetooth/power detail popovers
        ├── ConnectivityDetailShell.qml # picks which panel to load
        ├── WifiDetailPanel.qml
        ├── BluetoothDetailPanel.qml
        ├── PowerDetailPanel.qml
        └── BluetoothDeviceRow.qml
```

**Reading order, if you're new to this codebase:** `shell.qml` →
`qml/island/IslandWindow.qml` (the root window + state machine) →
`qml/island/IslandCapsule.qml` (what's actually drawn) → whichever domain
folder you're touching. `qml/controlcenter/` is the one place with a real
inheritance chain instead of plain composition — `ControlCenterLayer.qml`'s
root type is `PowerActionsController`, whose root type is
`BatteryModeController`, whose root type is `ConnectivityController` — so
`controlCenter.anyMemberFromAnyOfThose` just works, but note that QML `id:`
scoping is *per file*, not inherited: an id declared inside one of those
controller files is invisible by that name to the others, even though their
properties and functions are all shared. See ROADMAP.md's Phase 3/4/6
writeups for what that actually broke and how it was fixed, if you're adding
a `Timer`/`MouseArea`/etc. inside any of these files and need to reach it
from another.
