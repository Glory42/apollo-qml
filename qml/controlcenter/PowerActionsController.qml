import QtQuick
import Quickshell.Io
import "../common"

// Night light + shutdown/restart/sleep/lock; ControlCenterLayer.qml extends this (which extends BatteryModeController), so everything here is accessible as controlCenter.*.
BatteryModeController {
    id: root

    signal requestNotification(string appName, string summary, string body)
    signal nightLightModeChanged(bool enabled)
    property bool nightLightEnabled: false
    property bool nightLightBusy: false
    property int nightLightTemperature: 4500
    readonly property bool hyprlandNightLight: CompositorBackend.compositor === "hyprland"
    readonly property string nightLightGlyph: "\uf186"
    function toggleNightLight() {
        if (nightLightBusy)
            return;

        nightLightBusy = true;
        if (nightLightEnabled) {
            nightLightDisableProcess.running = true;
        } else {
            nightLightEnableProcess.running = true;
        }
    }

    function triggerShutdown() {
        if (!shutdownProcess.running)
            shutdownProcess.running = true;
    }
    function triggerRestart() {
        if (!restartProcess.running)
            restartProcess.running = true;
    }
    function triggerSleep() {
        if (!sleepProcess.running)
            sleepProcess.running = true;
    }
    function triggerLock() {
        if (!lockProcess.running)
            lockProcess.running = true;
    }

    Process {
        id: nightLightEnableProcess
        command: [
            "sh",
            "-c",
            hyprlandNightLight
                ? "temp=\"$1\"\n"
                    + "if ! command -v hyprsunset >/dev/null 2>&1; then exit 127; fi\n"
                    + "if hyprctl hyprsunset temperature \"$temp\" >/dev/null 2>&1; then exit 0; fi\n"
                    + "if ! command -v pgrep >/dev/null 2>&1 || ! pgrep -x hyprsunset >/dev/null 2>&1; then\n"
                    + "  if command -v setsid >/dev/null 2>&1; then\n"
                    + "    setsid hyprsunset >/dev/null 2>&1 < /dev/null &\n"
                    + "  else\n"
                    + "    nohup hyprsunset >/dev/null 2>&1 < /dev/null &\n"
                    + "  fi\n"
                    + "fi\n"
                    + "i=0\n"
                    + "while [ \"$i\" -lt 24 ]; do\n"
                    + "  if hyprctl hyprsunset temperature \"$temp\" >/dev/null 2>&1; then exit 0; fi\n"
                    + "  i=$((i + 1))\n"
                    + "  sleep 0.04\n"
                    + "done\n"
                    + "exit 1"
                : "temp=\"$1\"\n"
                    + "if ! command -v gammastep >/dev/null 2>&1; then exit 127; fi\n"
                    + "gammastep -m wayland -P -O \"$temp\" >/dev/null 2>&1",
            "tide-night-light",
            nightLightTemperature.toString()
        ]
        running: false

        onExited: function(exitCode) {
            if (exitCode === 0) {
                nightLightBusy = false;
                nightLightEnabled = true;
                nightLightModeChanged(true);
                requestNotification("Night Light", "Night Light enabled", nightLightTemperature + "K");
                return;
            }

            nightLightBusy = false;
            nightLightEnabled = false;
            nightLightModeChanged(false);
            requestNotification("Night Light", "Night Light unavailable",
                hyprlandNightLight
                    ? "Install hyprsunset to use Night Light."
                    : "Install gammastep to use Night Light.");
        }
    }

    Process {
        id: nightLightDisableProcess
        command: [
            "sh",
            "-c",
            hyprlandNightLight
                ? "hyprctl hyprsunset identity >/dev/null 2>&1 || true"
                : "if ! command -v gammastep >/dev/null 2>&1; then exit 127; fi\n"
                    + "gammastep -m wayland -x >/dev/null 2>&1 || true"
        ]
        running: false

        onExited: function(exitCode) {
            nightLightBusy = false;
            nightLightEnabled = false;
            nightLightModeChanged(false);
            if (exitCode === 127)
                requestNotification("Night Light", "Night Light unavailable",
                    hyprlandNightLight
                        ? "Install hyprsunset to use Night Light."
                        : "Install gammastep to use Night Light.");
            else
                requestNotification("Night Light", "Night Light disabled", "");
        }
    }

    Process {
        id: shutdownProcess
        command: ["systemctl", "poweroff"]
        running: false
        onExited: function(exitCode) {
            if (exitCode !== 0)
                requestNotification("Power", "Shutdown failed",
                    "Could not power off via systemctl.");
        }
    }
    Process {
        id: restartProcess
        command: ["systemctl", "reboot"]
        running: false
        onExited: function(exitCode) {
            if (exitCode !== 0)
                requestNotification("Power", "Restart failed",
                    "Could not reboot via systemctl.");
        }
    }
    Process {
        id: sleepProcess
        command: ["systemctl", "suspend"]
        running: false
        onExited: function(exitCode) {
            if (exitCode !== 0)
                requestNotification("Power", "Sleep failed",
                    "Could not suspend via systemctl.");
        }
    }
    Process {
        id: lockProcess
        command: [
            "sh",
            "-c",
            "if command -v hyprlock >/dev/null 2>&1; then hyprlock; "
                + "elif command -v swaylock >/dev/null 2>&1; then swaylock; "
                + "elif command -v i3lock >/dev/null 2>&1; then i3lock; "
                + "elif command -v loginctl >/dev/null 2>&1; then loginctl lock-session; "
                + "else exit 127; fi"
        ]
        running: false
        onExited: function(exitCode) {
            if (exitCode === 127)
                requestNotification("Power", "Lock unavailable",
                    "Install hyprlock, swaylock, or i3lock to enable screen locking.");
        }
    }
}
