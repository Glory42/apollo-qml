import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// Night light (on/off, warmth, schedule), dimming and power profile, all driven by their usual command line tools.
Item {
    id: root

    visible: false
    width: 0
    height: 0

    property bool nightLight: false
    property string profile: "balanced"
    // How warm the night light is, in kelvin; kept between sessions.
    property int temperature: 4500
    readonly property int warmest: 2500
    readonly property int coolest: 5500
    // Turns the night light on and off between Config.nightLightFrom and Config.nightLightTo; kept between sessions.
    property bool scheduled: false
    // Whether the clock was inside the schedule when last checked, or null before the first check.
    property var insideSchedule: null
    // How bright hyprsunset leaves every screen, in percent; below 100 dims it. Kept between sessions.
    property int gamma: 100
    // Low enough to read by in the dark, high enough that the screen never goes black.
    readonly property int dimmest: 25

    // Sets $on when the screen is warmer than daylight now; a hyprsunset schedule may have changed it since the last toggle.
    readonly property string nightRead: 'i=$(hyprctl hyprsunset identity get 2>/dev/null); t=$(hyprctl hyprsunset temperature 2>/dev/null) || t=;'
        + ' case "$t" in *[!0-9]*) t=;; esac; on=; [ "$i" != true ] && [ -n "$t" ] && [ "$t" -lt 6000 ] && on=1'
    // $1 is "on", "off", "toggle", or "keep" to leave the night light as it is; $2 the temperature to turn on at,
    // $3 the gamma. Prints the state the night light ends in. Starts hyprsunset first when it has anything to do.
    readonly property string nightSet: 'want=$1; k=$2; g=$3; ' + nightRead
        + '; [ "$want" = toggle ] && { [ -n "$on" ] && want=off || want=on; }; [ "$want" = keep ] && { [ -n "$on" ] && want=on || want=off; keep=1; };'
        + ' if [ -z "$t" ]; then [ "$want" = off ] && [ "$g" -ge 100 ] && { echo off; exit; }; (setsid hyprsunset -i >/dev/null 2>&1 &); sleep 1; keep=; fi;'
        + ' if [ -z "$keep" ]; then if [ "$want" = off ]; then hyprctl hyprsunset identity; else hyprctl hyprsunset temperature "$k"; fi >/dev/null || exit 1; fi;'
        + ' hyprctl hyprsunset gamma "$g" >/dev/null && echo "$want"'

    // Sent when a toggle from a keybind or the schedule went through, not when the state is first read.
    signal nightLightSet(bool on)

    function toggleNightLight() {
        runNight("toggle", true);
    }

    // Warmer also means on: dragging the warmth shows what it looks like.
    function setTemperature(kelvin) {
        temperature = Math.round(Math.max(warmest, Math.min(coolest, kelvin)) / 100) * 100;
        save();
        runNight("on", false);
    }

    function setGamma(percent) {
        gamma = Math.round(Math.max(dimmest, Math.min(100, percent)));
        save();
        runNight("keep", false);
    }

    function setScheduled(on) {
        scheduled = on;
        insideSchedule = null;
        save();
        checkSchedule();
    }

    // Minutes since midnight for "HH:MM", or -1.
    function minutesOf(text) {
        const parts = String(text).split(":");
        const hours = parseInt(parts[0]);
        const minutes = parseInt(parts[1] || "0");
        return isNaN(hours) || isNaN(minutes) ? -1 : hours * 60 + minutes;
    }

    function inSchedule(date) {
        const from = minutesOf(Config.nightLightFrom);
        const to = minutesOf(Config.nightLightTo);
        if (from < 0 || to < 0 || from === to)
            return false;
        const now = date.getHours() * 60 + date.getMinutes();
        return from < to ? now >= from && now < to : now >= from || now < to;
    }

    // Acts only when the clock crosses into or out of the schedule, so a toggle in between holds until the next crossing.
    function checkSchedule() {
        if (!scheduled)
            return;
        const inside = inSchedule(new Date());
        if (inside === insideSchedule)
            return;
        const first = insideSchedule === null;
        insideSchedule = inside;
        runNight(inside ? "on" : "off", !first);
    }

    function runNight(want, announce) {
        if (nightProcess.running) {
            // Every run sets the latest warmth and gamma, so a "keep" only matters when nothing else is waiting.
            const queued = nightProcess.queued;
            if (want === "keep" && queued)
                want = queued.want;
            nightProcess.queued = { want: want, announce: announce || !!queued && queued.announce };
            return;
        }
        nightProcess.announce = announce;
        nightProcess.command = ["sh", "-c", nightSet, "sh", want, String(temperature), String(gamma)];
        nightProcess.running = true;
    }

    function save() {
        store.setText(JSON.stringify({ temperature: temperature, scheduled: scheduled, gamma: gamma }));
    }

    function setProfile(mode) {
        profile = mode;
        profileSet.command = ["powerprofilesctl", "set", mode];
        profileSet.running = true;
    }

    Component.onCompleted: profileGet.running = true

    Process {
        id: nightProcess

        property bool announce: false
        // The latest request made while one was still running; the ones before it no longer matter.
        property var queued: null

        stdout: StdioCollector {
            onStreamFinished: {
                const state = text.trim();
                if (state !== "on" && state !== "off")
                    return;
                root.nightLight = state === "on";
                if (nightProcess.announce)
                    root.nightLightSet(root.nightLight);
            }
        }

        onRunningChanged: {
            if (running || !queued)
                return;
            const next = queued;
            queued = null;
            Qt.callLater(() => root.runNight(next.want, next.announce));
        }
    }

    // Prints whether it is on, and the warmth hyprsunset is at.
    Process {
        running: true
        command: ["sh", "-c", root.nightRead + '; echo "${on:-0} $t"']
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(" ");
                root.nightLight = parts[0] === "1";
                const kelvin = parseInt(parts[1]);
                if (root.nightLight && !isNaN(kelvin))
                    root.temperature = Math.max(root.warmest, Math.min(root.coolest, kelvin));
            }
        }
    }

    FileView {
        id: store

        path: Quickshell.statePath("display.json")
        printErrors: false
        onLoaded: {
            try {
                const saved = JSON.parse(store.text());
                if (typeof saved.temperature === "number" && !root.nightLight)
                    root.temperature = Math.max(root.warmest, Math.min(root.coolest, saved.temperature));
                if (typeof saved.gamma === "number")
                    root.gamma = Math.max(root.dimmest, Math.min(100, saved.gamma));
                root.scheduled = saved.scheduled === true;
                if (root.gamma < 100)
                    root.runNight("keep", false);
                root.checkSchedule();
            } catch (error) {
            }
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
