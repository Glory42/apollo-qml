import QtQuick
import Quickshell.Io

// Night light and power profile, both driven by their usual command line tools.
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
        profileSet.command = ["powerprofilesctl", "set", mode];
        profileSet.running = true;
    }

    Component.onCompleted: profileGet.running = true

    Process {
        id: nightProcess

        property bool pending: false

        onExited: (exitCode) => {
            if (exitCode === 0)
                root.nightLight = pending;
        }
    }

    Process {
        id: profileSet
    }

    Process {
        id: profileGet

        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const active = text.trim();
                if (active !== "")
                    root.profile = active;
            }
        }
    }
}
