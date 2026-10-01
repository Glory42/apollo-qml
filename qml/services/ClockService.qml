import QtQuick

// Current time text, refreshed on the minute.
Item {
    id: root

    visible: false
    width: 0
    height: 0

    property string currentTime: "00:00"
    property string clockFormat: "24"

    function updateClock() {
        const now = new Date();
        root.currentTime = Qt.formatTime(now, root.clockFormat === "24" ? "HH:mm" : "hh:mm ap");
        clockTimer.interval = (60 - now.getSeconds()) * 1000 - now.getMilliseconds();
    }

    onClockFormatChanged: updateClock()

    Timer {
        id: clockTimer

        running: true
        repeat: true
        triggeredOnStart: true
        interval: 1000
        onTriggered: root.updateClock()
    }
}
