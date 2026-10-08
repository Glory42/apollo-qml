pragma Singleton

import QtQuick
import Quickshell

// User settings: edit the values below.
QtObject {
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property string clockFormat: "24"
    readonly property int windowGap: 0
    readonly property bool swipeReverse: false
    readonly property bool mediaPeek: true

    readonly property bool weatherEnabled: true
    readonly property string weatherLocation: ""
    readonly property string weatherUnits: "metric"
    readonly property int weatherRefreshInterval: 1800000

    // When a scheduled night light turns on and off, as "HH:MM"; the schedule itself is switched on in the Display view.
    readonly property string nightLightFrom: "23:00"
    readonly property string nightLightTo: "07:00"

    // Seconds without input before each step; 0 turns that step off. None of it runs under APOLLO_DEV.
    readonly property int idleScreenOffSeconds: 300
    readonly property int idleLockSeconds: 330
    readonly property int idleSleepSeconds: 0
    readonly property var screenOffCommand: ["hyprctl", "dispatch", 'hl.dsp.dpms({ action = "disable" })']
    readonly property var screenOnCommand: ["hyprctl", "dispatch", 'hl.dsp.dpms({ action = "enable" })']

    // Hasselblad: where captures go, and the commands run on them through sh with the file as $1.
    readonly property string screenshotDir: Quickshell.env("HOME") + "/Pictures/Screenshots"
    readonly property string recordingDir: Quickshell.env("HOME") + "/Videos/Recordings"
    readonly property string screenshotEditCommand: 'satty --filename "$1" --output-filename "$1"'
    readonly property string openFileCommand: 'xdg-open "$1"'

    // Run through sh by Splashdown's Log out. uwsm has to end the session itself when it started it.
    readonly property string logoutCommand: "command -v uwsm >/dev/null 2>&1 && uwsm stop || hyprctl dispatch 'hl.dsp.exit()' || hyprctl dispatch exit"

    // The rice's theme folder: themes/<name>/ and the current palette.json. APOLLO_THEME_DIR overrides it.
    readonly property string themeDir: Quickshell.env("APOLLO_THEME_DIR") || Quickshell.env("HOME") + "/.config/theme"
    // Run through sh after a theme's palette becomes the current one, to recolour the rest of the rice.
    readonly property string themeApplyCommand: 'PATH="$HOME/.local/bin:$PATH" apply-theme && hyprctl reload'
    // The wallpaper's path is added as the last argument.
    readonly property var wallpaperCommand: ["awww", "img"]
}
