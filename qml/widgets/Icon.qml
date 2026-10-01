import QtQuick
import ".."

// Material Symbols icon, written as its ligature name so it takes its color and size like text.
Item {
    id: root

    property string name: ""
    property color color: Theme.fg
    property real size: 18

    width: size
    height: size

    readonly property var glyphs: ({
        "play": "play_arrow",
        "pause": "pause",
        "prev": "skip_previous",
        "next": "skip_next",
        "wifi": "wifi",
        "bt": "bluetooth",
        "moon": "bedtime",
        "volume": "volume_up",
        "mute": "volume_off",
        "sun": "light_mode",
        "bell": "notifications",
        "timer": "timer",
        "cloud": "cloud",
        "cal": "calendar_month",
        "battery": "battery_full",
        "bolt": "bolt",
        "music": "music_note",
        "sliders": "tune",
        "power": "power_settings_new",
        "chevron": "chevron_right"
    })

    Text {
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: root.glyphs[root.name] || ""
        color: root.color
        font.family: Theme.iconFont
        font.pixelSize: root.size
    }
}
