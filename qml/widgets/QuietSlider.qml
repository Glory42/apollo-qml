import QtQuick
import ".."

Item {
    id: root

    property string icon: ""
    property real value: 0
    signal moved(real value)

    readonly property real shown: area.pressed ? area.dragValue : value

    implicitHeight: 22

    Icon {
        id: glyph

        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        color: Theme.dim
    }

    Rectangle {
        id: track

        anchors.left: glyph.right
        anchors.leftMargin: 12
        anchors.right: percent.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        height: 10
        radius: 5
        color: Theme.fill2

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.shown))
            height: parent.height
            radius: 5
            color: Theme.fg
        }

        MouseArea {
            id: area

            property real dragValue: 0

            anchors.fill: parent
            anchors.topMargin: -8
            anchors.bottomMargin: -8
            cursorShape: Qt.PointingHandCursor

            function update(x) {
                dragValue = Math.max(0, Math.min(1, x / width));
                root.moved(dragValue);
            }

            onPressed: (mouse) => update(mouse.x)
            onPositionChanged: (mouse) => update(mouse.x)
        }
    }

    Text {
        id: percent

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 28
        horizontalAlignment: Text.AlignRight
        text: Math.round(Math.max(0, Math.min(1, root.shown)) * 100)
        color: Theme.dim
        font.family: Theme.fontFamily
        font.pixelSize: 11
    }
}
