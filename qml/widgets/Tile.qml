import QtQuick
import ".."

// Toggle tile: light when on, dark when off.
Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool on: false
    property bool detail: false
    signal clicked()
    signal detailRequested()

    implicitHeight: 56
    radius: 18
    color: on ? Theme.tileOn : (area.containsMouse ? Theme.fill2 : Theme.fill)

    Icon {
        id: glyph

        x: 14
        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        color: root.on ? Theme.tileOnInk : Theme.fg
    }

    Column {
        anchors.left: glyph.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: root.detail ? 36 : 10
        anchors.verticalCenter: parent.verticalCenter

        Text {
            width: parent.width
            text: root.title
            elide: Text.ElideRight
            color: root.on ? Theme.tileOnInk : Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
        }

        Text {
            width: parent.width
            text: root.subtitle
            elide: Text.ElideRight
            color: root.on ? Theme.tileOnSub : Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Item {
        visible: root.detail
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 36

        Icon {
            anchors.centerIn: parent
            size: 16
            name: "chevron"
            color: root.on ? Theme.tileOnInk : Theme.dim
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.detailRequested()
        }
    }
}
