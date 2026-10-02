# Apollo

A quiet shell for Hyprland, written in QML on top of Quickshell's native modules
(`Quickshell.Bluetooth`, `Quickshell.Networking`,
`Quickshell.Services.{Pipewire,UPower,Mpris,Notifications}`, `Quickshell.Hyprland`).
There is no C++ backend. (yeah iam a soyboy)

Apollo is a set of small, separate pieces. The first is **the capsule**: a black notch
hanging from the top edge of the screen with three sizes (rest, peek, open) and one dock. At rest it
shows only the workspace dots and the clock. Events (notifications, now playing,
volume, brightness) peek out and go away, and everything else opens from the capsule or from a
keybind.

## Running it

```bash
quickshell -p /path/to/this/repo/shell.qml
```

It runs on every monitor. Events show on all of them, views open on the focused one.
For testing, `APOLLO_DEV=1` offsets the capsule down the screen and
`APOLLO_SCREEN=<output>` pins it to one monitor.

## The capsule

The dock has six tabs, in this order: quick settings, music, timer, weather,
calendar, notifications. Quick settings holds volume, brightness, Wi-Fi, Bluetooth,
night light, focus, the power profile and battery details (time left and
power draw), and its Wi-Fi and Bluetooth tiles open
detail views for joining networks and pairing devices.

- It is the notification server (`org.freedesktop.Notifications`), so stop any other
  notification daemon first.
- Bluetooth pairing uses `bluetoothctl` as the pairing agent while the Bluetooth view
  is open.
- Night light uses `hyprsunset`, power profiles use `powerprofilesctl`, and brightness
  uses `brightnessctl`.
- Icons are Material Symbols (Rounded) pasted in as SVG paths in `qml/widgets/Icon.qml`, so no
  font or image files are needed (I got tired of fighting icon fonts). To add one, copy its path from the SVG on
  fonts.google.com/icons into that file.
- The capsule is attached to the top edge and reserves its own height, so windows start
  below it, plus your Hyprland `gaps_out`.
- Clicking anywhere outside an open view closes it. The capsule never takes keyboard
  focus, except while a Wi-Fi password or Bluetooth passkey box is showing.
- The resting capsule hides under fullscreen windows like a bar, but peeks (notifications,
  now playing, volume) and open views show above them.
- A two-finger horizontal swipe on the touchpad over an open capsule moves between tabs.

## Settings

Edit the values in `qml/core/Config.qml`:

| Setting | What it does |
|---|---|
| `fontFamily` | Font for all text. |
| `clockFormat` | `"24"` or `"12"`. |
| `windowGap` | Extra space between the capsule and your windows, on top of `gaps_out`. |
| `mediaPeek` | Show a short "now playing" peek when media starts or the track changes. |
| `swipeReverse` | Set to `true` if the touchpad swipe goes the wrong way. |
| `weatherEnabled`, `weatherLocation`, `weatherUnits`, `weatherRefreshInterval` | Weather. An empty location is detected from your IP, units are `"metric"` or `"imperial"`. |

Colors, sizes and motion live in `qml/core/Theme.qml`.

## Keybinds

`houston` talks to the running shell from any directory:

```
houston capsule open|toggle <quick|music|timer|weather|calendar|notifications|wifi|bt>
houston capsule next|prev
houston capsule close
houston capsule notify <app> <summary> <body>
```

Example Hyprland binds:

```
bind = SUPER CTRL, W, exec, /path/to/houston capsule toggle wifi
bind = SUPER CTRL, B, exec, /path/to/houston capsule toggle bt
bind = SUPER CTRL, M, exec, /path/to/houston capsule toggle music
bind = SUPER CTRL, Q, exec, /path/to/houston capsule toggle quick
bind = SUPER CTRL, T, exec, /path/to/houston capsule toggle timer
bind = SUPER CTRL, N, exec, /path/to/houston capsule toggle notifications
bind = SUPER CTRL, C, exec, /path/to/houston capsule toggle calendar
bind = SUPER CTRL, E, exec, /path/to/houston capsule toggle weather
bind = SUPER CTRL, X, exec, /path/to/houston capsule close
bind = SUPER CTRL, right, exec, /path/to/houston capsule next
bind = SUPER CTRL, left, exec, /path/to/houston capsule prev
```

- A second press of a toggle bind closes the view, and opening a view closes it on the
  other monitors.
- `next` and `prev` move through the dock tabs and wrap around. When nothing is open
  they open the last view you used.
- Each piece of Apollo is its own IPC target, so later pieces will be called the same
  way (`houston splashdown open`, and so on).

## Layout

```
shell.qml                  entry point: shared services, one capsule per monitor
houston                    IPC helper for keybinds
qml/core/                  Config (your settings) and Theme (colors, sizes, motion)
qml/services/              headless state, no visuals
  ClockService, MprisService, SystemService (battery, volume, brightness),
  WeatherService, QuickSettingsService, TimerService,
  ConnectivityService (Wi-Fi and Bluetooth flows), BluetoothAgent (bluetoothctl),
  NotificationService (the notification server and unread count)
qml/capsule/               the capsule
  CapsuleScreen (per monitor), CapsuleWindow, CapsuleController, Capsule (the shape that morphs),
  Dock, CapsuleIpc
  views/                   one file per view, plus ViewFrame they all sit in
qml/surface/               DismissCatcher (click outside to close)
qml/widgets/               Icon, Tile, ListRow, QuietSlider, RoundButton, ...
```

`qml/qmldir` is the one registry for every component, and each file imports it with
`import ".."` (or `import "../.."` from `qml/capsule/views/`). Add new components to it,
because Quickshell does not generate a `qmldir` for every directory on its own.

## Roadmap

Apollo grows as separate pieces. Each new piece gets its own window, its own IPC
target (`houston <piece> ...`) and its own folder under `qml/`, so the repo keeps one
top-level directory and the capsule stays small.

Done:

- [x] The capsule: music, quick settings, timer, weather, calendar, notifications, Wi-Fi,
  Bluetooth, battery details and a now-playing peek

Planned, each as its own piece outside the capsule:

- [ ] Launchpad: application launcher
- [ ] Splashdown: power menu (lock, log out, suspend, restart, shut down)
- [ ] Earthrise: wallpaper changer
- [ ] Visor: theme changer
- [ ] Airlock: lock screen
- [ ] Logbook: clipboard history

Ideas, not decided yet:

- [ ] System tray for apps that use tray icons
- [ ] Screenshot and screen recording controls
- [ ] Per-app volume mixer and output device picker
- [ ] Emoji picker
- [ ] Polkit password prompt (authentication agent)
- [ ] Idle handling (dim, lock and suspend after inactivity)
- [ ] VPN, Ethernet and airplane mode toggles

Not planned: workspace overview and lyrics. (I'm lazy, not sorry)

## Known gaps

- Hyprland only. (it's the only thing I use, sorry)
- Another notification daemon has to be stopped first, because only one can own
  `org.freedesktop.Notifications`.
- Commands sent in the first few seconds after launch are ignored, because the capsule
  window does not exist yet. (be patient, it's a notch, not a miracle)
- The Wi-Fi view cannot join hidden networks, or WEP and enterprise (802.1X) networks.
- The swipe gesture works with a touchpad only, not a touchscreen.
- Joining a new Wi-Fi network with a password and pairing a new Bluetooth device have not
  been tried on real hardware, only the pieces around them. (it works on my machine, probably)
