pragma Singleton

import QtQuick
import Quickshell.Io
import ".."

// Design tokens. Colours follow the rice's current palette; without one they are the values written here.
QtObject {
    id: theme

    readonly property string fontFamily: Config.fontFamily

    property var palette: ({})
    readonly property bool themed: tone("bg", "") !== "" && tone("fg", "") !== ""

    // Palette colours are "rrggbb" with an optional alpha that is ignored, as the rest of the rice does.
    function toneOf(palette, key, fallback) {
        const value = palette[key];
        return typeof value === "string" && /^[0-9a-fA-F]{6}/.test(value) ? "#" + value.slice(0, 6) : fallback;
    }

    function tone(key, fallback) {
        return toneOf(theme.palette, key, fallback);
    }

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    function reload() {
        source.reload();
    }

    readonly property color hull: tone("bg", "#000000")
    readonly property color fg: tone("fg", "#ecece8")
    readonly property color accent: tone("accent", "#ecece8")
    readonly property color fill: themed ? mix(hull, fg, 0.085) : "#151517"
    readonly property color fill2: themed ? mix(hull, fg, 0.13) : "#1f1f22"
    readonly property color dim: alpha(fg, 0.58)
    readonly property color faint: alpha(fg, 0.30)
    readonly property color line: themed ? alpha(fg, 0.07) : Qt.rgba(1, 1, 1, 0.07)
    readonly property color danger: tone("regular1", "#ff7c72")
    readonly property color tileOn: themed ? mix(fg, hull, 0.08) : "#e4e7ee"
    readonly property color tileOnInk: themed ? mix(hull, fg, 0.05) : "#0b0c0e"
    readonly property color tileOnSub: alpha(tileOnInk, 0.58)

    readonly property int restWidth: 136
    readonly property int restHeight: 30
    readonly property int openWidth: 400
    readonly property int peekNotifyWidth: 340
    readonly property int peekNotifyHeight: 60
    readonly property int peekOsdWidth: 230
    readonly property int peekOsdHeight: 44
    readonly property int maxRadius: 28
    readonly property int fillet: 18
    readonly property int topMargin: 0

    readonly property int windowWidth: 480
    readonly property int windowHeight: 560

    readonly property real springStiffness: 3.4
    readonly property real springDamping: 0.3
    readonly property real springDampingClose: 0.35
    readonly property int fadeDuration: 300

    property FileView source: FileView {
        path: Config.themeDir + "/palette.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                theme.palette = JSON.parse(text());
            } catch (error) {
            }
        }
    }
}
