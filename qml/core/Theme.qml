pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// Design tokens: black pill, quiet greys, one spring. The values below are
// Umbra's own original palette, kept as-is and NOT auto-overwritten — this
// project's "quiet black pill" look may be a deliberate choice independent
// of whatever's in palette.json (a bright tokyo-night cyan accent, say).
//
// `paletteBg`/`paletteFg`/`paletteAccent` below are read live from
// ~/.config/theme/palette.json (the single source of truth shared with
// foot/Neovim/Zed/hyprlock — see hyprland-dots' Milestone 1). They're just
// exposed here, not wired into anything yet. Deciding which of the tokens
// below (if any) should actually follow them is a real design call, not a
// mechanical one — do that deliberately, don't bulk-replace.
Singleton {
    id: root

    readonly property string fontFamily: Config.fontFamily

    readonly property color pill: "#000000"
    readonly property color fill: "#151517"
    readonly property color fill2: "#1f1f22"
    readonly property color fg: "#ecece8"
    readonly property color dim: Qt.rgba(0.925, 0.925, 0.91, 0.58)
    readonly property color faint: Qt.rgba(0.925, 0.925, 0.91, 0.30)
    readonly property color line: Qt.rgba(1, 1, 1, 0.07)
    readonly property color danger: "#ff7c72"
    readonly property color tileOn: "#e4e7ee"
    readonly property color tileOnInk: "#0b0c0e"
    readonly property color tileOnSub: Qt.rgba(0.043, 0.047, 0.055, 0.58)

    // live palette.json values — read-only mirror, nothing above depends on these yet
    property color paletteBg: "#1a1b26"
    property color paletteFg: "#c0caf5"
    property color paletteAccent: "#33ccff"

    FileView {
        id: paletteFile
        path: Quickshell.env("HOME") + "/.config/theme/palette.json"
        watchChanges: true
        onLoaded: root.applyPalette(text())
        onFileChanged: reload()
    }

    function applyPalette(jsonText) {
        try {
            const p = JSON.parse(jsonText);
            if (p.bg) root.paletteBg = "#" + p.bg.slice(0, 6);
            if (p.fg) root.paletteFg = "#" + p.fg.slice(0, 6);
            if (p.accent) root.paletteAccent = "#" + p.accent.slice(0, 6);
        } catch (e) {
            console.warn("Theme: failed to parse palette.json, keeping fallback colors", e);
        }
    }

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
}
