# My QML's

A quiet, Dynamic-Island-style shell widget for Hyprland, written in QML on top of
Quickshell's native modules (`Quickshell.Bluetooth`, `Quickshell.Networking`,
`Quickshell.Services.{Pipewire,UPower,Mpris,Notifications}`, `Quickshell.Hyprland`).
There is no C++ backend.

One pill, three sizes (rest, peek, open), one dock. At rest it shows only the
workspace dots and the clock. Events (notifications, volume, brightness) peek out
and go away; everything else opens from the pill or from a keybind.

## Running it

```bash
quickshell -p /path/to/this/repo/shell.qml
```

It runs on every monitor. Events show on all of them, views open on the focused one.
For testing, `SURFACE_DEV=1` offsets it down the screen and `SURFACE_SCREEN=<output>`
pins it to one monitor.

## Views

Music, quick settings (volume, brightness, Wi-Fi, Bluetooth, night light, focus,
power profile), timer, weather, calendar, notifications, plus Wi-Fi and Bluetooth
detail views reached from the quick settings tiles.

- It is the notification server (`org.freedesktop.Notifications`), so stop any other
  notification daemon first.
- Bluetooth pairing uses `bluetoothctl` as the pairing agent while the Bluetooth view
  is open.
- Night light uses `hyprsunset`, power profiles use `powerprofilesctl`, brightness uses
  `brightnessctl`.

## Keybinds

`surface-ctl` talks to the running shell from any directory:

```
surface-ctl open|toggle <music|quick|timer|weather|calendar|notifications|wifi|bt>
surface-ctl close
surface-ctl notify <app> <summary> <body>
```

```
bind = SUPER CTRL, W, exec, /path/to/surface-ctl toggle wifi
bind = SUPER CTRL, B, exec, /path/to/surface-ctl toggle bt
bind = SUPER CTRL, M, exec, /path/to/surface-ctl toggle music
bind = SUPER CTRL, Q, exec, /path/to/surface-ctl toggle quick
bind = SUPER CTRL, T, exec, /path/to/surface-ctl toggle timer
bind = SUPER CTRL, N, exec, /path/to/surface-ctl toggle notifications
bind = SUPER CTRL, C, exec, /path/to/surface-ctl toggle calendar
bind = SUPER CTRL, E, exec, /path/to/surface-ctl toggle weather
bind = SUPER CTRL, X, exec, /path/to/surface-ctl close
```

A second press closes the view, and opening a view closes it on the other monitors.

## Layout

```
shell.qml                  entry point: shared services, one window per monitor
surface-ctl                IPC helper for keybinds
qml/core/                  Config (your settings) and Theme (colors, sizes, motion)
qml/services/              headless state, no visuals
  ClockService, MprisService, SystemService (battery, volume, brightness),
  WeatherService, QuickSettingsService, TimerService,
  ConnectivityService (Wi-Fi and Bluetooth flows), BluetoothAgent (bluetoothctl),
  NotificationService (the notification server and unread count)
qml/surface/               SurfaceScreen (per monitor), SurfaceWindow, SurfaceController, SurfacePill,
                           DismissCatcher (click outside to close), SurfaceIpc
qml/views/                 one file per view, plus ViewFrame they all sit in
qml/widgets/               Icon, Dock, Tile, ListRow, QuietSlider, PillButton, ...
```

`qml/qmldir` is the one registry for every component, and each file imports it with
`import ".."`. Add new components to it, because Quickshell does not generate a `qmldir`
for every directory on its own.

## Not included on purpose

Workspace overview, lyrics, and wallpaper or theme pickers are meant to live outside
the island.
