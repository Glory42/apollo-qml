import QtQuick

// Countdown state. Idle shows the chosen duration, active counts down, paused keeps the remainder.
Item {
    id: root

    visible: false
    width: 0
    height: 0

    property int totalSeconds: 300
    property int remaining: 0
    property bool running: false
    property bool active: false

    readonly property int shownSeconds: active ? remaining : totalSeconds
    readonly property real progress: active && totalSeconds > 0 ? 1 - remaining / totalSeconds : 0
    readonly property string text: {
        const s = shownSeconds;
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const sec = s % 60;
        const mm = (m < 10 && h > 0 ? "0" : "") + m;
        return (h > 0 ? h + ":" + mm : mm) + ":" + (sec < 10 ? "0" : "") + sec;
    }

    signal finished()

    function toggle() {
        if (!active) {
            remaining = totalSeconds;
            active = true;
            running = true;
        } else {
            running = !running;
        }
    }

    function reset() {
        running = false;
        active = false;
        remaining = 0;
    }

    function addMinutes(minutes) {
        const delta = minutes * 60;
        totalSeconds = Math.max(60, totalSeconds + delta);
        if (active)
            remaining = Math.max(1, remaining + delta);
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.running
        onTriggered: {
            root.remaining -= 1;
            if (root.remaining <= 0) {
                root.reset();
                root.finished();
            }
        }
    }
}
