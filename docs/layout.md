# Layout

```
shell.qml                  entry point: shared services, one capsule per monitor
houston                    IPC helper for keybinds
docs/                      these pages
qml/core/                  Config (your settings) and Theme (colors, sizes, motion)
qml/services/              headless state, no visuals
  ClockService, MprisService, SystemService (battery, volume, brightness),
  WeatherService, QuickSettingsService,
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
