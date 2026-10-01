pragma Singleton

import QtQuick

// User settings: edit the values below.
QtObject {
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property string iconFont: "JetBrainsMono Nerd Font"
    readonly property string clockFormat: "24"
    readonly property int windowGap: 0

    readonly property bool weatherEnabled: true
    readonly property string weatherLocation: ""
    readonly property string weatherUnits: "metric"
    readonly property int weatherRefreshInterval: 1800000
}
