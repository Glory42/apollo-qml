# Logbook

Clipboard history, in an **orbiter**: a hull floating in the middle of the focused monitor.
Search and the list of entries are on the left, the highlighted entry in full on the right.

- Enter pastes the entry into the window you were in, Shift+Enter only copies it,
  Shift+Delete removes it from the history, Escape or a click outside closes.
- Apollo records the clipboard itself with two `wl-paste --watch` processes (text and PNG
  images), so it needs `wl-clipboard`, and `wtype` for pasting. Do not run `cliphist` or
  another recorder for it. If `wl-clipboard` or `wtype` is missing, Apollo says so in a
  notification when it starts, and Logbook's empty list says what to install. Without `wtype`,
  choosing an entry only copies it.
- If the watchers stop (the compositor restarting, say), they are started again after two
  seconds. After five restarts without a minute of running in between they are left stopped, and
  Logbook says recording stopped until Apollo is restarted.
- The newest 300 entries are kept, in `logbook.json` in Quickshell's state directory, with
  images as files in `logbook-images/` next to it. Text over 100 kB and anything a
  password manager marks as secret (`x-kde-passwordManagerHint`) are not recorded.
- Only the clipboard is recorded, not the primary selection (text selected with the mouse).
- Pasting sends Shift+Insert, which works in terminals and elsewhere because the entry is
  put on both the clipboard and the primary selection.
