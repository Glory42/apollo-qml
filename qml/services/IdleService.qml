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
    property bool stayAwake: false
    property bool sleeping: false
    // A suspend asked for here waits for the lock, so it does not depend on the sleep signal arriving in time.
    property bool suspendWanted: false
    // This session's logind object, which carries the Lock signal (`loginctl lock-session`).
    property string sessionPath: ""

    readonly property bool watching: active && !stayAwake

    signal lockRequested()

    function suspend() {
        root.suspendWanted = true;
        root.lockRequested();
        if (root.locked)
            suspendNow();
    }

    function suspendNow() {
        root.suspendWanted = false;
        Quickshell.execDetached(["systemctl", "suspend"]);
    }

    function goingToSleep() {
        root.sleeping = true;
        Quickshell.execDetached(Config.screenOffCommand);
        root.lockRequested();
        if (root.locked)
            letGo.restart();
    }

    function wokeUp() {
        root.sleeping = false;
        letGo.stop();
        hold.running = root.active;
        Quickshell.execDetached(Config.screenOnCommand);
    }

    onLockedChanged: {
        if (locked && sleeping)
            letGo.restart();
        if (locked && suspendWanted)
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

    // A moment for the lock to be drawn before sleep is let through.
    Timer {
        id: letGo

        interval: 250
        onTriggered: hold.running = false
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
