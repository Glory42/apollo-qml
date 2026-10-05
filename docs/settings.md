# Settings

Edit the values in `qml/core/Config.qml`:

| Setting | What it does |
|---|---|
| `fontFamily` | Font for all text. |
| `clockFormat` | `"24"` or `"12"`. |
| `windowGap` | Extra space between the capsule and your windows, on top of `gaps_out`. |
| `mediaPeek` | Show a short "now playing" peek when media starts or the track changes. |
| `swipeReverse` | Set to `true` if the touchpad swipe goes the wrong way. |
| `weatherEnabled`, `weatherLocation`, `weatherUnits`, `weatherRefreshInterval` | Weather. An empty location is detected from your IP, units are `"metric"` or `"imperial"`. |
| `nightLightFrom`, `nightLightTo` | When the night light's schedule turns it on and off, as `"HH:MM"`. The schedule itself is switched on in the Display view. |
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
