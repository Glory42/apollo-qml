# Idle

Apollo does what `hypridle` would, so that does not need to run alongside it:

- After `idleScreenOffSeconds` without input the screens turn off, and come back on the
  first key or mouse move.
- After `idleLockSeconds` Airlock locks.
- After `idleSleepSeconds` the machine suspends. This is off (`0`) by default.
- Airlock also locks before any suspend, whoever asked for it: Splashdown, the lid, or
  `systemctl suspend`. The screens go black as sleep starts, and Apollo holds sleep back
  until the lock is drawn. Splashdown's Suspend and idle sleep lock first and only then
  suspend.
- `loginctl lock-session` locks Airlock too.
- A video or anything else that inhibits idle keeps all of this from starting.
- `houston awake toggle` stops the idle steps until it is toggled again or Apollo restarts.
- None of it runs under `APOLLO_DEV=1`.
