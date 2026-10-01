import QtQuick
import "../core"

// One tappable row: icon, title, subtitle, and a right-hand action with an optional secondary action on hover.
Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property string action: ""
    property string secondary: ""
    property bool highlighted: false
    property bool busy: false
    property real iconOpacity: 1

    signal activated()
    signal secondaryActivated()

    implicitHeight: 52
    radius: 14
    color: area.containsMouse && !busy ? Theme.fill : "transparent"
    opacity: busy ? 0.6 : 1

    Icon {
        id: glyph

        x: 12
        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        opacity: root.iconOpacity
        color: root.highlighted ? Theme.fg : Theme.dim
    }

    Column {
        anchors.left: glyph.right
        anchors.leftMargin: 12
        anchors.right: actions.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter

        Text {
            width: parent.width
            text: root.title
            elide: Text.ElideRight
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: root.highlighted ? Font.Medium : Font.Normal
        }

        Text {
            width: parent.width
            text: root.subtitle
            elide: Text.ElideRight
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.busy
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }

    Row {
        id: actions

        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Text {
            visible: root.secondary !== "" && area.containsMouse && !root.busy
            text: root.secondary
            color: Theme.faint
            font.family: Theme.fontFamily
            font.pixelSize: 11

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: root.secondaryActivated()
            }
        }

        Text {
            text: root.action
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
    }
}
