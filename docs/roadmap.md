# Roadmap

Apollo grows as separate pieces. Each new piece gets its own window, its own IPC
target (`houston <piece> ...`) and its own folder under `qml/`, so the repo keeps one
top-level directory and the capsule stays small.

Done:

- [x] The capsule: music, quick settings, weather, calendar, notifications, Wi-Fi,
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
