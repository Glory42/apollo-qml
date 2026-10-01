# Umbra

A quiet shell for Hyprland, written in QML on top of Quickshell's native modules
(`Quickshell.Bluetooth`, `Quickshell.Networking`,
`Quickshell.Services.{Pipewire,UPower,Mpris,Notifications}`, `Quickshell.Hyprland`).
There is no C++ backend.

Umbra is a set of small, separate pieces. The first is **the pill**: a black pill at
the top of the screen with three sizes (rest, peek, open) and one dock. At rest it
shows only the workspace dots and the clock. Events (notifications, volume,
brightness) peek out and go away, and everything else opens from the pill or from a
keybind.

## Running it

```bash
quickshell -p /path/to/this/repo/shell.qml
```

It runs on every monitor. Events show on all of them, views open on the focused one.
For testing, `UMBRA_DEV=1` offsets the pill down the screen and
`UMBRA_SCREEN=<output>` pins it to one monitor.

## The pill

Views: music, quick settings (volume, brightness, Wi-Fi, Bluetooth, night light,
focus, power profile), timer, weather, calendar, notifications, plus Wi-Fi and
Bluetooth detail views reached from the quick settings tiles.

- It is the notification server (`org.freedesktop.Notifications`), so stop any other
  notification daemon first.
- Bluetooth pairing uses `bluetoothctl` as the pairing agent while the Bluetooth view
  is open.
- Night light uses `hyprsunset`, power profiles use `powerprofilesctl`, brightness uses
  `brightnessctl`.
- Clicking anywhere outside an open view closes it. It never takes keyboard focus,
  except while a Wi-Fi password or Bluetooth passkey box is showing.

## Keybinds

`umbra-ctl` talks to the running shell from any directory:

```
umbra-ctl pill open|toggle <music|quick|timer|weather|calendar|notifications|wifi|bt>
umbra-ctl pill close
umbra-ctl pill notify <app> <summary> <body>
```

```
bind = SUPER CTRL, W, exec, /path/to/umbra-ctl pill toggle wifi
bind = SUPER CTRL, B, exec, /path/to/umbra-ctl pill toggle bt
bind = SUPER CTRL, M, exec, /path/to/umbra-ctl pill toggle music
bind = SUPER CTRL, Q, exec, /path/to/umbra-ctl pill toggle quick
bind = SUPER CTRL, T, exec, /path/to/umbra-ctl pill toggle timer
bind = SUPER CTRL, N, exec, /path/to/umbra-ctl pill toggle notifications
bind = SUPER CTRL, C, exec, /path/to/umbra-ctl pill toggle calendar
bind = SUPER CTRL, E, exec, /path/to/umbra-ctl pill toggle weather
bind = SUPER CTRL, X, exec, /path/to/umbra-ctl pill close
```

A second press closes the view, and opening a view closes it on the other monitors.
Each piece of Umbra is its own IPC target, so later pieces will be called the same way
(`umbra-ctl power open`, and so on).

## Layout

```
shell.qml                  entry point: shared services, one pill per monitor
umbra-ctl                  IPC helper for keybinds
qml/core/                  Config (your settings) and Theme (colors, sizes, motion)
qml/services/              headless state, no visuals
  ClockService, MprisService, SystemService (battery, volume, brightness),
  WeatherService, QuickSettingsService, TimerService,
  ConnectivityService (Wi-Fi and Bluetooth flows), BluetoothAgent (bluetoothctl),
  NotificationService (the notification server and unread count)
qml/pill/                  the pill
  PillScreen (per monitor), PillWindow, PillController, Pill (the shape that morphs),
  Dock, DismissCatcher (click outside to close), PillIpc
  views/                   one file per view, plus ViewFrame they all sit in
qml/widgets/               Icon, Tile, ListRow, QuietSlider, PillButton, ...
```

`qml/qmldir` is the one registry for every component, and each file imports it with
`import ".."` (or `import "../.."` from `qml/pill/views/`). Add new components to it,
because Quickshell does not generate a `qmldir` for every directory on its own.

## Not included on purpose

Workspace overview, lyrics, the power menu, and wallpaper or theme pickers are not part
of the pill. They are meant to be their own pieces.
