# Apollo

A quiet shell for Hyprland, written in QML on top of Quickshell's native modules
(`Quickshell.Bluetooth`, `Quickshell.Networking`,
`Quickshell.Services.{Pipewire,UPower,Mpris,Notifications}`, `Quickshell.Hyprland`).
There is no C++ backend. (yeah iam a soyboy)

Apollo is a set of small, separate pieces, named after the space programme. The first is
**the capsule**: a black notch
hanging from the top edge of the screen with three sizes (rest, peek, open) and one dock. At rest it
shows the workspace dots, the clock, and icons for the connection (Wi-Fi bars, a cable, or
crossed out) and the battery level. Events (notifications, now playing,
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

## The pieces

| Piece | What it is |
|---|---|
| [The capsule](docs/capsule.md) | The notch at the top: workspaces, clock, peeks, and views for quick settings, music, timer, weather, calendar, notifications, Wi-Fi, Bluetooth, sound and display. |
| [Launchpad](docs/launchpad.md) | Application launcher. |
| [Visor and Earthrise](docs/themes.md) | Theme picker and wallpaper picker, and how themes are laid out. |
| [Logbook](docs/logbook.md) | Clipboard history. |
| [Airlock](docs/airlock.md) | Lock screen. |
| [Idle](docs/idle.md) | Screens off, lock and suspend after inactivity, in place of `hypridle`. |
| [Splashdown](docs/splashdown.md) | Power menu. |
| [Hasselblad](docs/hasselblad.md) | Screenshots, screen recording and colour picking. |

## More

- [Settings](docs/settings.md): what you can change in `qml/core/Config.qml`.
- [Keybinds](docs/keybinds.md): `houston`, example binds, and Hyprland global shortcuts.
- [Layout](docs/layout.md): where things are in the code, for changing it.
- [Glossary](docs/glossary.md): what the names (piece, surface, lander, orbiter, ...) mean.
- [Roadmap](docs/roadmap.md): what is done, what might come, and known gaps.
