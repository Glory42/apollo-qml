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

    // Run through sh by Splashdown's Log out. uwsm has to end the session itself when it started it.
    readonly property string logoutCommand: "command -v uwsm >/dev/null 2>&1 && uwsm stop || hyprctl dispatch 'hl.dsp.exit()' || hyprctl dispatch exit"

    // The rice's theme folder: themes/<name>/ and the current palette.json. APOLLO_THEME_DIR overrides it.
    readonly property string themeDir: Quickshell.env("APOLLO_THEME_DIR") || Quickshell.env("HOME") + "/.config/theme"
    // Run through sh after a theme's palette becomes the current one, to recolour the rest of the rice.
    readonly property string themeApplyCommand: 'PATH="$HOME/.local/bin:$PATH" apply-theme && hyprctl reload'
    // The wallpaper's path is added as the last argument.
    readonly property var wallpaperCommand: ["awww", "img"]
}
