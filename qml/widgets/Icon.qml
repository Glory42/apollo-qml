import QtQuick
import ".."

// Icon drawn from a Nerd Font glyph, so it takes its color and size like text.
Item {
    id: root

    property string name: ""
    property color color: Theme.fg
    property real size: 18

    width: size
    height: size

    readonly property var glyphs: ({
        "play": "\u{F040A}",
        "pause": "\u{F03E4}",
        "prev": "\u{F04AE}",
        "next": "\u{F04AD}",
        "wifi": "\u{F05A9}",
        "bt": "\u{F00AF}",
        "moon": "\u{F0F65}",
        "volume": "\u{F057E}",
        "mute": "\u{F075F}",
        "sun": "\u{F00E0}",
        "bell": "\u{F009A}",
        "timer": "\u{F13AB}",
        "cloud": "\u{F0590}",
        "cal": "\u{F00ED}",
        "battery": "\u{F0079}",
        "bolt": "\u{F0241}",
        "music": "\u{F075A}",
        "sliders": "\u{F062E}",
        "power": "\u{F0425}",
        "chevron": "\u{F0142}"
    })

    Text {
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: root.glyphs[root.name] || ""
        color: root.color
        font.family: Config.iconFont
        font.pixelSize: root.size
    }
}
