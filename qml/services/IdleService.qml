import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import ".."

// What happens when the owner walks away: screens off, lock, sleep. The lock also goes up before any sleep.
Item {
    id: root

    visible: false

    // False under APOLLO_DEV, so a test shell never locks or sleeps the desktop it is run from.
    property bool active: true
    property bool locked: false
    // The compositor has confirmed the lock covers every screen; only then is sleep let through.
    property bool secure: false
    property bool stayAwake: false
    property bool sleeping: false
    // A suspend asked for here waits for the lock, so it does not depend on the sleep signal arriving in time.
    property bool suspendWanted: false
    // This session's logind object, which carries the Lock signal (`loginctl lock-session`).
    property string sessionPath: ""
    // How long sleep is held for the lock before it is let through anyway; read from logind below.
    property int budgetMs: 4000

    readonly property bool watching: active && !stayAwake

    signal lockRequested()
    // Sleep went ahead before the lock was confirmed, so the session may have slept exposed.
    signal sleptUnsecured()

    function suspend() {
        root.suspendWanted = true;
        root.lockRequested();
        if (root.secure)
            suspendNow();
        else
            suspendDeadline.restart();
    }

    function suspendNow() {
        root.suspendWanted = false;
        suspendDeadline.stop();
        Quickshell.execDetached(["systemctl", "suspend"]);
    }

    function goingToSleep() {
        console.info("IdleService: sleep is starting, secure=" + root.secure);
        root.sleeping = true;
        root.lockRequested();
        if (root.secure) {
            letGo();
            return;
        }
        // Screens that are already off (idle, or something turned them off as the lid closed) draw no frames, so the lock could not be confirmed on them.
        Quickshell.execDetached(Config.screenOnCommand);
        sleepDeadline.restart();
    }

    function letGo() {
        sleepDeadline.stop();
        if (!hold.running)
            return;
        console.info("IdleService: letting sleep through");
        // Blanked only now: an output that is off draws no frames, so the lock could never be confirmed on it.
        Quickshell.execDetached(Config.screenOffCommand);
        hold.running = false;
    }

    function wokeUp() {
        console.info("IdleService: woke up");
        root.sleeping = false;
        sleepDeadline.stop();
        hold.running = root.active;
        Quickshell.execDetached(Config.screenOnCommand);
    }

    onSecureChanged: {
        if (!secure)
            return;
        if (sleeping)
            letGo();
        if (suspendWanted)
            suspendNow();
    }

    IdleMonitor {
        enabled: root.watching && Config.idleScreenOffSeconds > 0
        timeout: Config.idleScreenOffSeconds
        respectInhibitors: true
        onIsIdleChanged: Quickshell.execDetached(isIdle ? Config.screenOffCommand : Config.screenOnCommand)
    }

    IdleMonitor {
        enabled: root.watching && Config.idleLockSeconds > 0
        timeout: Config.idleLockSeconds
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) root.lockRequested()
    }

    IdleMonitor {
        enabled: root.watching && Config.idleSleepSeconds > 0
        timeout: Config.idleSleepSeconds
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) root.suspend()
    }

    // Sleep waits for this to end, which is what gets the lock on screen first; it ends by itself if the shell dies.
    Process {
        id: hold

        running: root.active
        stdinEnabled: true
        command: ["systemd-inhibit", "--what=sleep", "--mode=delay", "--who=Apollo", "--why=Lock before sleep", "cat"]
    }

    // logind sleeps anyway once its window runs out, so let go a little earlier and say so, rather than be overrun.
    Timer {
        id: sleepDeadline

        interval: root.budgetMs
        onTriggered: {
            if (!root.sleeping || !hold.running)
                return;
            console.warn("IdleService: the lock was not confirmed within " + root.budgetMs + " ms, sleeping anyway");
            root.sleptUnsecured();
            root.letGo();
        }
    }

    // A lock that never confirms should not swallow the suspend; the sleep path above still waits for it.
    Timer {
        id: suspendDeadline

        interval: 3000
        onTriggered: if (root.suspendWanted) root.suspendNow()
    }

    // The budget is logind's window less a fifth of it (at least a second), so logind has time to act on the release.
    Process {
        running: root.active
        command: ["gdbus", "call", "--system", "--dest", "org.freedesktop.login1", "--object-path", "/org/freedesktop/login1", "--method", "org.freedesktop.DBus.Properties.Get", "org.freedesktop.login1.Manager", "InhibitDelayMaxUSec"]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = text.match(/uint64 (\d+)/);
                if (!found)
                    return;
                const windowMs = Math.floor(Number(found[1]) / 1000);
                root.budgetMs = Math.max(500, Math.min(12000, windowMs - Math.max(Math.floor(windowMs / 5), 1000)));
            }
        }
    }

    Process {
        running: root.active
        command: ["gdbus", "call", "--system", "--dest", "org.freedesktop.login1", "--object-path", "/org/freedesktop/login1", "--method", "org.freedesktop.login1.Manager.GetSession", "auto"]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = text.match(/'([^']+)'/);
                root.sessionPath = found ? found[1] : "";
            }
        }
    }

    // stdbuf: gdbus block-buffers into a pipe, which held PrepareForSleep back until long after sleep.
    Process {
        id: monitor

        running: root.active
        command: ["setpriv", "--pdeathsig", "TERM", "stdbuf", "-oL", "gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1"]
        stdout: SplitParser {
            onRead: (line) => {
                if (line.includes("PrepareForSleep (true"))
                    root.goingToSleep();
                else if (line.includes("PrepareForSleep (false"))
                    root.wokeUp();
                else if (root.sessionPath !== "" && line.startsWith(root.sessionPath + ": org.freedesktop.login1.Session.Lock "))
                    root.lockRequested();
            }
        }
        onExited: (exitCode) => {
            if (!root.active)
                return;
            console.warn("IdleService: the logind monitor exited with " + exitCode + ", restarting it");
            restartMonitor.restart();
        }
    }

    // A dead monitor would mean an unlocked suspend again, so it comes back instead of failing silently.
    Timer {
        id: restartMonitor

        interval: 1000
        onTriggered: monitor.running = root.active
    }
}
