# Hasselblad

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
