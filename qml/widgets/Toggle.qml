import QtQuick
import ".."

// An on/off switch.
Rectangle {
    id: root

    property bool checked: false
    signal toggled()

    implicitWidth: 44
    implicitHeight: 26
    radius: height / 2
    color: root.checked ? Theme.tileOn : Theme.fill2

    Rectangle {
        x: root.checked ? parent.width - width - 3 : 3
        anchors.verticalCenter: parent.verticalCenter
        width: parent.height - 6
        height: width
        radius: width / 2
        color: root.checked ? Theme.tileOnInk : Theme.dim

        Behavior on x {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
