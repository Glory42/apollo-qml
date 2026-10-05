# Apollo

A quiet shell for Hyprland, written in QML on top of Quickshell's native modules
(`Quickshell.Bluetooth`, `Quickshell.Networking`,
`Quickshell.Services.{Pipewire,UPower,Mpris,Notifications}`, `Quickshell.Hyprland`).
There is no C++ backend. (yeah iam a soyboy)

Apollo is a set of small, separate pieces, named after the space programme. The first is
**the capsule**: a black notch
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

## What it needs installed

Apollo calls a few programs. A piece whose program is missing just does nothing; the rest
keep working. Arch package names:

| Package | Used for |
|---|---|
| `quickshell`, `hyprland` | Everything. |
| `pipewire`, `wireplumber` | Volume and the Sound view. |
| `networkmanager` | Wi-Fi, Ethernet and DNS (`nmcli`). |
| `iputils` | `ping` on the connection page. |
| `bluez`, `bluez-utils` | Bluetooth, and pairing through `bluetoothctl`. |
| `upower` | Battery. |
| `brightnessctl` | Screen and keyboard brightness. |
| `hyprsunset` | Night light, and dimming every screen. |
| `power-profiles-daemon` | Power profiles (`powerprofilesctl`). |
| `wl-clipboard`, `wtype` | Logbook: recording copies, and pasting. |
| `awww` | Setting wallpapers, from Visor and Earthrise (`wallpaperCommand`). |
| `libvips` | Small previews of the wallpapers for the Visor and Earthrise cards (`vipsthumbnail`); ImageMagick's `magick` works too. Without either the cards show the full pictures, which appear later. |
| `uwsm` | Optional; Log out uses `uwsm stop` when it is there. |
| `libnotify` | `notify-send`, for scripts and binds that announce something, such as a screenshot. |
| `qrencode` | The QR code when sharing a Wi-Fi network; without it only the password shows. |
| `grim` | Saving screenshots (Hasselblad). |
| `satty` | Editing a screenshot (`screenshotEditCommand`). |
| `gpu-screen-recorder` | Screen recording. |
| `ffmpeg` | Tidying a recording after it stops (`ffprobe` comes with it). |
| `hyprpicker` | Picking a colour. |
| `xdg-utils` | Opening a saved recording from its notification (`openFileCommand`). |

Planned, not needed yet:

| Package | Will be used for |
|---|---|
| `mullvad-vpn` | The VPN toggle, once there is one. |

## The capsule

The dock has six tabs, in this order: quick settings, music, timer, weather,
calendar, notifications. Quick settings holds volume, brightness, Wi-Fi, Bluetooth,
night light, focus, the power profile and battery details (time left and
power draw), and its Wi-Fi and Bluetooth tiles open
detail views for joining networks and pairing devices. The arrow at the end of the volume
slider opens the Sound view: pick the output and input device, set their levels, and give
each app that is playing its own volume (up to 150%) and mute. The arrow on the brightness
slider, or on the night light tile, opens the Display view: screen and keyboard brightness, a
dim slider that darkens every screen through hyprsunset (external monitors too, never below
25%), how warm the night light is (dragging it turns the night light on), and a schedule that turns
it on and off at `nightLightFrom` and `nightLightTo` in `Config.qml`. The dimming, the warmth and whether
the schedule is on are remembered between sessions.

In the Wi-Fi view, "Details" on the connected network (or on the wired row, on a machine
with an Ethernet port or adapter) opens the connection page: ping and packet loss to
1.1.1.1, current traffic, totals, IP address and gateway, all measured only while the page is
open. It also sets that network's DNS (Automatic, Cloudflare, Google, or your own servers),
shares a Wi-Fi network as a QR code with its password behind a show button, and holds
Disconnect and Forget. `houston capsule open connection` opens it for the connection in use.

- It is the notification server (`org.freedesktop.Notifications`), so stop any other
  notification daemon first.
- A notification marked transient (`notify-send -e`) only peeks: it is not listed in the
  notifications view or counted as unread. That suits "screenshot taken" and the like.
- Apollo says a few things itself in a short peek: the charger going in or out, Wi-Fi and
  Bluetooth connecting or dropping, the microphone being muted or unmuted (however it was done), and the night light, silence and stay-awake binds. A
  battery at 20%, 10% and 5% is a real notification that shows even while silenced.
- The weather is fetched again within seconds if a request fails, so it shows soon after a
  login where the shell came up before the network. A restart shows the last weather at
  once (when it is under three hours old) while the new one loads.
- Bluetooth pairing uses `bluetoothctl` as the pairing agent while the Bluetooth view
  is open.
- Night light uses `hyprsunset`, power profiles use `powerprofilesctl`, and brightness
  uses `brightnessctl`.
- Icons are Material Symbols (Rounded) pasted in as SVG paths in `qml/widgets/IconPaths.js`, so no
  font or image files are needed (I got tired of fighting icon fonts). To add one, copy its path from the SVG on
  fonts.google.com/icons into that file.
- The capsule is attached to the top edge and reserves its own height, so windows start
  below it, plus your Hyprland `gaps_out`.
- Clicking anywhere outside an open view closes it. The capsule never takes keyboard
  focus, except while a Wi-Fi password or Bluetooth passkey box is showing.
- Clicking a notification's peek does what clicking the notification would: its main action
  (open the chat, edit the screenshot), or the notifications view when it has none.
- The resting capsule hides under fullscreen windows like a bar, but peeks (notifications,
  now playing, volume) and open views show above them.
- A two-finger horizontal swipe on the touchpad over an open capsule moves between tabs.

## Launchpad

The application launcher, in a lander. Type to search installed applications by name or
keyword; the matches are listed under the search field, best first.

- Enter starts the highlighted application, Down and Up (or Tab and Shift+Tab) move the
  highlight, Escape or a click outside closes.
- Applications you start most often rank first, and with nothing typed the list shows
  those. The counts are kept in `launchpad.json` in Quickshell's state directory.

## Themes, Visor and Earthrise

A theme is a folder in the rice, not in this repo:

```
~/.config/theme/
  themes/<name>/
    theme.json            { "name": "...", "main_wallpaper": "a.png", "wallpapers": ["b.jpg"] }
    palette.json          the theme's colours
    wallpapers/           only the files theme.json lists are used
  palette.json            the current theme's palette, which everything reads
```

**Visor** picks the current theme and **Earthrise** picks a wallpaper from the current
theme. Both are a carousel in the middle of the focused monitor: the current card is large
and its neighbours peek out on each side. Left, Right and Tab move, Enter chooses, Escape
or a click outside closes. A Visor card is the theme's main wallpaper with its name and
colours under it, outlined in the theme's accent.

- The cards show small JPEG previews, made in the background when Apollo starts and
  whenever a wallpaper is added or changed, so the pictures are there as soon as the
  carousel opens. They live in `previews/` in Quickshell's cache directory
  (`~/.cache/quickshell/by-shell/<id>/previews`) and can be deleted at any time; the cards
  then show the full pictures until the previews are made again. Setting a wallpaper always
  uses the original file.
- Choosing a theme copies its `palette.json` over `~/.config/theme/palette.json`, runs
  `themeApplyCommand` to recolour the rest of the rice, and sets the main wallpaper.
- Apollo takes its own colours from `~/.config/theme/palette.json` (`bg`, `fg`, `accent`,
  `regular1` for warnings; the greys are mixed from `bg` and `fg`) and follows the file when
  it changes. Without that file it uses the colours in `qml/core/Theme.qml`.
- Wallpapers are set with `wallpaperCommand`, `awww img <file>` by default.

## Logbook

Clipboard history, in an **orbiter**: a hull floating in the middle of the focused monitor.
Search and the list of entries are on the left, the highlighted entry in full on the right.

- Enter pastes the entry into the window you were in, Shift+Enter only copies it,
  Shift+Delete removes it from the history, Escape or a click outside closes.
- Apollo records the clipboard itself with two `wl-paste --watch` processes (text and PNG
  images), so it needs `wl-clipboard`, and `wtype` for pasting. Do not run `cliphist` or
  another recorder for it.
- The newest 300 entries are kept, in `logbook.json` in Quickshell's state directory, with
  images as files in `logbook-images/` next to it. Text over 100 kB and anything a
  password manager marks as secret are not recorded.
- Pasting sends Shift+Insert, which works in terminals and elsewhere because the entry is
  put on both the clipboard and the primary selection.

## Airlock

The lock screen: a clock, a password field and a status row with the battery level, what
is playing (with play/pause) and how many notifications arrived while locked. Only the
count is shown, never what they say.

- It is a real session lock (`ext-session-lock`): the compositor shows nothing else on any
  monitor, and if the shell dies while locked the session stays locked.
- The password is your login password, checked through PAM with
  `qml/airlock/pam/password.conf`.
- Nothing unlocks it except the password. `houston` can lock, not unlock.
- Behind it is the current wallpaper, blurred and dimmed. That is the wallpaper last set
  through Visor or Earthrise; before either has been used it is the plain background colour.
- Before relying on it, lock once with a TTY you can reach (Ctrl+Alt+F3), in case it does
  not accept your password on your system.

## Idle

Apollo does what `hypridle` would, so that does not need to run alongside it:

- After `idleScreenOffSeconds` without input the screens turn off, and come back on the
  first key or mouse move.
- After `idleLockSeconds` Airlock locks.
- After `idleSleepSeconds` the machine suspends. This is off (`0`) by default.
- Airlock also locks before any suspend, whoever asked for it: Splashdown, the lid, or
  `systemctl suspend`. Apollo holds sleep back until the lock is drawn.
- A video or anything else that inhibits idle keeps all of this from starting.
- `houston awake toggle` stops the idle steps until it is toggled again or Apollo restarts.
- None of it runs under `APOLLO_DEV=1`.

## Splashdown

The power menu: Lock, Log out, Suspend, Restart, Shut down. It rises from the bottom edge
of the focused monitor in a **lander**, the capsule's shape mirrored, which is only there
while it is open and holds the keyboard and mouse until it closes. Launchpad uses the same
lander.

- Left, Right and Tab move the highlight, Enter runs it, Escape or a click outside closes.
- Nothing asks for confirmation. The highlight starts on Lock, so a reflex Enter only locks.
- Lock hands over to Airlock.
- Only one piece is open at a time: opening Splashdown closes an open capsule view and the
  other way round. Peeks still show.

## Hasselblad

Capturing the screen. A screenshot with `houston hasselblad screenshot` (bind it to `Print`)
goes straight to the picker; everything else starts from Hasselblad's own menu, which rises
from the bottom edge in a lander like Splashdown: Screenshot, Record, Colour.

- The picker freezes the screen for a screenshot. The window under the pointer is outlined;
  click it or press Enter to take it, drag to take a region, Ctrl+Enter takes the whole
  monitor, Tab and the arrows move between windows, Escape or a right click cancels.
- A screenshot is saved to `screenshotDir` as `screenshot-<date>_<time>.png`, copied, and
  announced with a notification showing it. Clicking that notification, or
  `houston hasselblad edit`, opens the newest screenshot in satty (`houston capsule invoke` does the same while the screenshot
  is the newest notification).
- Record asks what sound to take (none, desktop, or desktop and microphone), then uses the
  same picker without the freeze. While it runs the resting capsule shows a red dot and the
  time; clicking the capsule, or `houston hasselblad record` again, stops it.
- A recording goes to `recordingDir` as `recording-<date>_<time>.mp4`. On stopping, ffmpeg
  trims the first frame and evens out the sound, as Omarchy does, and a notification opens
  the file.
- Colour runs hyprpicker, copies the colour as `#rrggbb`, and peeks with the colour itself.

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
| `idleScreenOffSeconds`, `idleLockSeconds`, `idleSleepSeconds` | Seconds without input before the screens turn off, Airlock locks and the machine suspends. `0` turns a step off. |
| `screenOffCommand`, `screenOnCommand` | Commands that turn the screens off and on; the defaults are Hyprland's `dpms` dispatcher in its Lua form. |
| `themeDir` | Where themes live, `~/.config/theme` by default. `APOLLO_THEME_DIR` overrides it. |
| `themeApplyCommand` | Shell command run after the palette changes: `apply-theme` (also looked for in `~/.local/bin`), then `hyprctl reload`. |
| `logoutCommand` | Shell command behind Splashdown's Log out: `uwsm stop` when uwsm is installed, otherwise Hyprland's exit. |
| `wallpaperCommand` | Command that sets a wallpaper; the file is added as the last argument. |
| `screenshotDir`, `recordingDir` | Where Hasselblad saves screenshots and recordings: `~/Pictures/Screenshots` and `~/Videos/Recordings`. |
| `screenshotEditCommand` | Shell command that edits a screenshot, given as `$1`: satty, saving over the file. |
| `openFileCommand` | Shell command that opens a saved recording, given as `$1`: `xdg-open`. |

Sizes and motion live in `qml/core/Theme.qml`, along with the colours used when there is no
palette.

## Keybinds

`houston` talks to the running shell from any directory:

```
houston capsule open|toggle <quick|music|timer|weather|calendar|notifications|wifi|bt>
houston capsule next|prev
houston capsule close
houston capsule notify <app> <summary> <body>
houston capsule say <icon> <text>
houston capsule invoke
houston splashdown open|toggle|close
houston launchpad open|toggle|close
houston logbook open|toggle|close
houston airlock lock
houston visor open|toggle|close
houston earthrise open|toggle|close
houston hasselblad open|toggle|close
houston hasselblad screenshot
houston hasselblad record
houston hasselblad edit
houston hasselblad colour
houston nightlight toggle
houston silence toggle
houston awake toggle
```

`invoke` runs the newest notification's main action, such as editing the screenshot just
taken. `say` shows a short peek of an icon and a few words that is not kept anywhere, for a script to
say what it just did; the icon is a name from `qml/widgets/IconPaths.js`, such as `bell`,
`sun` or `lock`. `nightlight` is the night light, `silence` stops notifications from peeking (critical ones
still do), and `awake` holds off the idle steps. Each shows a short peek saying what it
changed to.

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
bind = SUPER, Escape, exec, /path/to/houston splashdown toggle
bind = SUPER, Space, exec, /path/to/houston launchpad toggle
bind = SUPER CTRL, V, exec, /path/to/houston logbook toggle
bind = SUPER CTRL, L, exec, /path/to/houston airlock lock
bind = SUPER CTRL, SPACE, exec, /path/to/houston visor toggle
bind = SUPER ALT, SPACE, exec, /path/to/houston earthrise toggle
bind = SUPER CTRL, D, exec, /path/to/houston silence toggle
bind = SUPER CTRL, K, exec, /path/to/houston nightlight toggle
bind = SUPER CTRL, I, exec, /path/to/houston awake toggle
bind = , Print, exec, /path/to/houston hasselblad screenshot
bind = ALT, Print, exec, /path/to/houston hasselblad record
bind = SUPER, Print, exec, /path/to/houston hasselblad colour
bind = SUPER ALT, comma, exec, /path/to/houston capsule invoke
```

These are Omarchy's keys: `Print` takes a screenshot, `Alt + Print` asks what sound to record
or stops a recording, `Super + Print` picks a colour, and `Super + Alt + ,` runs the newest
notification's action, which right after a screenshot opens it in satty. The full menu (`houston hasselblad
toggle`) is there for a bind if you want one.

- A second press of a toggle bind closes the view, and opening a view closes it on the
  other monitors.
- `next` and `prev` move through the dock tabs and wrap around. When nothing is open
  they open the last view you used.
- Each piece of Apollo is its own IPC target, so later pieces will be called the same way.

### Global shortcuts

Every `houston` call starts a Quickshell process, which takes about 60 ms before Apollo
hears of it. For keybinds Apollo also registers Hyprland global shortcuts under the app id
`apollo`, which reach it with no process at all. Bind them with Hyprland's `global`
dispatcher instead of `exec`:

```
bind = SUPER CTRL, W, global, apollo:capsule-toggle-wifi
```

or, in a Lua config:

```lua
hl.bind("SUPER + CTRL + W", hl.dsp.global("apollo:capsule-toggle-wifi"))
```

| Shortcut | Same as |
|---|---|
| `capsule-toggle-<view>` | `houston capsule toggle <view>`, for `quick`, `music`, `timer`, `weather`, `calendar`, `notifications`, `wifi`, `bt`, `sound` and `connection` |
| `capsule-next`, `capsule-prev`, `capsule-close`, `capsule-invoke` | `houston capsule next`, `prev`, `close`, `invoke` |
| `launchpad-toggle`, `splashdown-toggle`, `logbook-toggle`, `visor-toggle`, `earthrise-toggle` | `houston <piece> toggle` |
| `airlock-lock` | `houston airlock lock` |
| `hasselblad-toggle`, `hasselblad-screenshot`, `hasselblad-record`, `hasselblad-edit`, `hasselblad-colour` | `houston hasselblad <function>` |
| `nightlight-toggle`, `silence-toggle`, `awake-toggle` | `houston <switch> toggle` |

`houston` stays for scripts and anything that needs arguments, such as `notify` and `say`.
The binds in the rice's own Hyprland config are changed over by hand; until then they keep
working through `houston`.

## Layout

```
shell.qml                  entry point: shared services, one capsule per monitor
houston                    IPC helper for keybinds
qml/core/                  Config (your settings) and Theme (colors, sizes, motion)
qml/services/              headless state, no visuals
  ClockService, MprisService, SystemService (battery, volume, brightness),
  WeatherService, QuickSettingsService, TimerService,
  ConnectivityService (Wi-Fi and Bluetooth flows), BluetoothAgent (bluetoothctl),
  NotificationService (the notification server and unread count),
  ClipboardService (records what is copied),
  IdleService (screens off, lock and sleep when idle, lock before sleep),
  SwitchesIpc (night light, silence and stay-awake for keybinds),
  SoundService (devices, apps that are playing, the microphone's mute),
  RecorderService (gpu-screen-recorder, and ffmpeg after it),
  ConnectionService (one connection's traffic, ping, addresses, DNS and sharing; lives with its page),
  ThemeService (the rice's themes, the current theme and wallpaper)
qml/airlock/               the lock screen: Airlock (the lock and the password check),
                           AirlockScreen (what one monitor shows), AirlockBackdrop (the blurred wallpaper),
                           AirlockIpc, pam/
qml/capsule/               the capsule
  CapsuleScreen (per monitor), CapsuleWindow, CapsuleController, Capsule (the shape that morphs),
  Dock, CapsuleIpc
  views/                   one file per view, plus ViewFrame they all sit in
qml/earthrise/             the wallpaper picker: Earthrise, EarthriseIpc
qml/launchpad/             the application launcher: Launchpad, LaunchpadIpc
qml/logbook/               clipboard history: Logbook, LogbookIpc, capture.sh (run on every copy)
qml/splashdown/            the power menu: Splashdown, SplashdownIpc
qml/hasselblad/            capturing the screen: Hasselblad (the menu and what each choice does),
                           Picker (the frozen or live window and region picker), HasselbladIpc
qml/surface/               where pieces appear: SurfaceWindow (screen, keyboard, a window no larger than the surface),
                           LanderWindow and Lander (bottom edge), OrbiterWindow (centre, with or without a hull),
                           DismissCatcher (the click outside the capsule or a surface)
qml/visor/                 the theme picker: Visor, VisorIpc
qml/widgets/               Carousel (the slanted picture cards, drawn by shaders/card.frag), Icon, Tile, ListRow, QuietSlider, RoundButton, ...
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
- [x] Airlock: lock screen
- [x] Earthrise: wallpaper picker
- [x] Idle: screens off, lock and suspend after inactivity, and lock before sleep
- [x] Sound view: output and input devices, per-app volume
- [x] Connection page: traffic, ping, addresses, DNS per network, Wi-Fi sharing; Ethernet
- [x] Hasselblad: screenshots with Apollo's own picker, screen recording, colour picker
- [x] Launchpad: application launcher
- [x] Logbook: clipboard history
- [x] Splashdown: power menu (lock, log out, suspend, restart, shut down)
- [x] Visor: theme picker

Ideas, not decided yet:

- [ ] Emoji picker
- [ ] Polkit password prompt (authentication agent)
- [ ] VPN toggle, through Mullvad's app, once it is installed

Not planned: system tray, airplane mode, workspace overview and lyrics. (I'm lazy, not sorry)

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
