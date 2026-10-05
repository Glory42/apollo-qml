# The capsule

The black notch hanging from the top edge of every monitor. It has three sizes: at **rest**
it shows only the workspace dots and the clock; a
**peek** briefly shows an event (a notification, now playing, volume, brightness); and
**open** shows a view, with a dock of tabs to move between them.

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
