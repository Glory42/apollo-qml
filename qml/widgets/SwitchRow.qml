import QtQuick
import ".."

// An icon, what the switch does, and the switch; the whole row flips it.
Rectangle {
    id: row

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool checked: false
    signal toggled()

    width: parent ? parent.width : 0
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
