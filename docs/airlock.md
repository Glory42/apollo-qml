# Airlock

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
