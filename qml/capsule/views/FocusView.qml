import QtQuick
import "../.."

// What may interrupt: focus itself in the header, then staying awake, track peeks and the microphone.
ViewFrame {
    id: root

    readonly property var center: ctl ? ctl.center : null
    readonly property var idle: ctl ? ctl.idle : null
    readonly property var sound: ctl ? ctl.sound : null
    readonly property var mic: sound && sound.source ? sound.source.audio : null
    readonly property bool focusMode: !!root.center && root.center.focusMode

    spacing: 10

    // An icon, what the switch does, and the switch; the whole row flips it.
    component SwitchRow: Rectangle {
        id: row

        property string icon: ""
        property string title: ""
        property string subtitle: ""
        property bool checked: false
        signal toggled()

        width: parent.width
        implicitHeight: 52
        radius: 14
        color: rowArea.containsMouse ? Theme.fill : "transparent"

        Icon {
            id: glyph

            x: 12
            anchors.verticalCenter: parent.verticalCenter
            name: row.icon
            color: row.checked ? Theme.fg : Theme.dim
        }

        Column {
            anchors.left: glyph.right
            anchors.leftMargin: 12
            anchors.right: rowSwitch.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter

            Text {
                width: parent.width
                text: row.title
                elide: Text.ElideRight
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 13
            }

            Text {
                width: parent.width
                text: row.subtitle
                elide: Text.ElideRight
                color: Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }

        MouseArea {
            id: rowArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.toggled()
        }

        Toggle {
            id: rowSwitch

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            checked: row.checked
            onToggled: row.toggled()
        }
    }

    DetailHeader {
        width: parent.width
        ctl: root.ctl
        title: "Focus"
        subtitle: root.focusMode ? "Alerts silenced" : "Alerts on"
        checked: root.focusMode
        onToggled: root.center.focusMode = !root.center.focusMode
    }

    Column {
        width: parent.width

        SwitchRow {
            icon: "visibility"
            title: "Stay awake"
            subtitle: "No screen off, lock or sleep"
            checked: !!root.idle && root.idle.stayAwake
            onToggled: root.idle.stayAwake = !root.idle.stayAwake
        }

        SwitchRow {
            icon: "music"
            title: "Track pop-ups"
            subtitle: "A peek when a song starts or changes"
            checked: !!root.center && root.center.trackPeeks
            onToggled: root.center.setTrackPeeks(!root.center.trackPeeks)
        }

        SwitchRow {
            visible: !!root.mic
            icon: root.mic && root.mic.muted ? "mic_off" : "mic"
            title: "Microphone muted"
            subtitle: root.sound && root.sound.source ? (root.sound.source.description || root.sound.source.name) : ""
            checked: !!root.mic && root.mic.muted
            onToggled: root.sound.toggleMute(root.sound.source)
        }
    }
}
