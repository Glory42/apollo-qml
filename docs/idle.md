# Idle

Apollo does what `hypridle` would, so that does not need to run alongside it:

- After `idleScreenOffSeconds` without input the screens turn off, and come back on the
  first key or mouse move.
- After `idleLockSeconds` Airlock locks.
- After `idleSleepSeconds` the machine suspends. This is off (`0`) by default.
- Airlock also locks before any suspend, whoever asked for it: Splashdown, the lid, or
  `systemctl suspend`. Apollo holds sleep back until the compositor confirms the lock
  covers every screen, then blanks the screens and lets sleep through. Splashdown's
  Suspend and idle sleep lock first and only then suspend.
- If the screens are already off when sleep starts (idle, or switched off as the lid closed), Apollo turns them on first, because a lock can only be confirmed on a screen that draws.
- If the lock is not confirmed in time, Apollo lets sleep through a little before logind
  would anyway, and posts a critical "Screen did not lock before suspend" notification.
  The time allowed follows logind's `InhibitDelayMaxSec` (4 s at its 5 s default).
- `loginctl lock-session` locks Airlock too.
- A video or anything else that inhibits idle keeps all of this from starting.
- `houston awake toggle` stops the idle steps until it is toggled again or Apollo restarts.
- None of it runs under `APOLLO_DEV=1`.
