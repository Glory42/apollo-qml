pragma Singleton

import QtQuick

// Design tokens: black pill, quiet greys, one morph curve.
QtObject {
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

    readonly property int restWidth: 136
    readonly property int restHeight: 30
    readonly property int openWidth: 400
    readonly property int peekNotifyWidth: 340
    readonly property int peekNotifyHeight: 60
    readonly property int peekOsdWidth: 230
    readonly property int peekOsdHeight: 44
    readonly property int maxRadius: 28
    readonly property int topMargin: 6

    readonly property int windowWidth: 460
    readonly property int windowHeight: 560

    readonly property int morphDuration: 460
    readonly property var morphCurve: [0.2, 0.9, 0.25, 1, 1, 1]
    readonly property int fadeDuration: 300
}
