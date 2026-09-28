import QtQuick
import "../common"

Item {
    id: root

    visible: false
    width: 0
    height: 0

    property bool active: false
    property string wallpaperPath: ""
    property var hyprMonitor: null
    property var screenObject: null

    readonly property bool ready: true
    readonly property string effectiveSource: wallpaperPath

    function prewarm() {}
}
