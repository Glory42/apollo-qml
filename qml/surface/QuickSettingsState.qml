import QtQuick
import Quickshell.Io
import "../common"

// Headless state and actions behind the quick settings view.
Item {
    id: root

    visible: false
    width: 0
    height: 0

    property bool nightLight: false
    property string profile: "balanced"

    function toggleNightLight() {
        const enable = !nightLight;
        nightProcess.command = enable
            ? ["sh", "-c", "hyprctl hyprsunset temperature 4500 || { (setsid hyprsunset >/dev/null 2>&1 &); sleep 1; hyprctl hyprsunset temperature 4500; }"]
            : ["sh", "-c", "hyprctl hyprsunset identity"];
        nightProcess.pending = enable;
        nightProcess.running = true;
    }

    function setProfile(mode) {
        profile = mode;
        SystemServices.setPowerProfileMode("powerprofilesctl", mode, "", false);
    }

    Process {
        id: nightProcess

        property bool pending: false

        onExited: (exitCode) => {
            if (exitCode === 0)
                root.nightLight = pending;
        }
    }

    Connections {
        target: SystemServices

        function onTlpStateReady(available, active) {
            if (available && active !== "")
                root.profile = active;
        }
    }

    Component.onCompleted: SystemServices.requestPowerProfileState("powerprofilesctl")
}
