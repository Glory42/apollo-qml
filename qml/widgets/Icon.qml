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
        "music": "music_note",
        "sliders": "tune",
        "power": "power_settings_new",
        "chevron": "chevron_right",
        "battery_0_bar": "battery_0_bar",
        "battery_1_bar": "battery_1_bar",
        "battery_2_bar": "battery_2_bar",
        "battery_3_bar": "battery_3_bar",
        "battery_4_bar": "battery_4_bar",
        "battery_5_bar": "battery_5_bar",
        "battery_6_bar": "battery_6_bar",
        "battery_full": "battery_full",
        "battery_unknown": "battery_unknown",
        "battery_charging_20": "battery_charging_20",
        "battery_charging_30": "battery_charging_30",
        "battery_charging_50": "battery_charging_50",
        "battery_charging_60": "battery_charging_60",
        "battery_charging_80": "battery_charging_80",
        "battery_charging_90": "battery_charging_90",
        "battery_charging_full": "battery_charging_full"
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
