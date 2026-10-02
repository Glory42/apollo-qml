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

    // Sets $on when the screen is warmer than daylight now; a hyprsunset schedule may have changed it since the last toggle.
    readonly property string nightRead: 'i=$(hyprctl hyprsunset identity get 2>/dev/null); t=$(hyprctl hyprsunset temperature 2>/dev/null) || t=;'
        + ' case "$t" in *[!0-9]*) t=;; esac; on=; [ "$i" != true ] && [ -n "$t" ] && [ "$t" -lt 6000 ] && on=1'
    // Prints the state it ends in. Turning on starts hyprsunset first if it is not running.
    readonly property string nightToggle: nightRead + '; if [ -n "$on" ]; then hyprctl hyprsunset identity >/dev/null && echo off; else'
        + ' { hyprctl hyprsunset temperature 4500 >/dev/null 2>&1 || { (setsid hyprsunset >/dev/null 2>&1 &); sleep 1; hyprctl hyprsunset temperature 4500 >/dev/null; }; } && echo on; fi'

    // Sent only when a toggle went through, not when the state is first read.
    signal nightLightSet(bool on)

    function toggleNightLight() {
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

        command: ["sh", "-c", root.nightToggle]
        stdout: StdioCollector {
            onStreamFinished: {
                const state = text.trim();
                if (state !== "on" && state !== "off")
                    return;
                root.nightLight = state === "on";
                root.nightLightSet(root.nightLight);
            }
        }
    }

    Process {
        running: true
        command: ["sh", "-c", root.nightRead + '; echo "${on:-0}"']
        stdout: StdioCollector {
            onStreamFinished: root.nightLight = text.trim() === "1"
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
