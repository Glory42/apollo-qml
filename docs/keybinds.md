# Keybinds

`houston` talks to the running shell from any directory:

```
houston capsule open|toggle <quick|music|weather|calendar|notifications|wifi|bt|sound|display|connection>
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

## Global shortcuts

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
| `capsule-toggle-<view>` | `houston capsule toggle <view>`, for `quick`, `music`, `weather`, `calendar`, `notifications`, `wifi`, `bt`, `sound`, `display` and `connection` |
| `capsule-next`, `capsule-prev`, `capsule-close`, `capsule-invoke` | `houston capsule next`, `prev`, `close`, `invoke` |
| `launchpad-toggle`, `splashdown-toggle`, `logbook-toggle`, `visor-toggle`, `earthrise-toggle` | `houston <piece> toggle` |
| `airlock-lock` | `houston airlock lock` |
| `hasselblad-toggle`, `hasselblad-screenshot`, `hasselblad-record`, `hasselblad-edit`, `hasselblad-colour` | `houston hasselblad <function>` |
| `nightlight-toggle`, `silence-toggle`, `awake-toggle` | `houston <switch> toggle` |

`houston` stays for scripts and anything that needs arguments, such as `notify` and `say`.
The binds in the rice's own Hyprland config are changed over by hand; until then they keep
working through `houston`.
