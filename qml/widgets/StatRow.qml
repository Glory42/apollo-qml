import QtQuick
import ".."

// A label on the left and its value on the right.
Item {
    id: root

    property string label: ""
    property string value: ""

    implicitHeight: 16

    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Theme.dim
        font.family: Theme.fontFamily
        font.pixelSize: 10
    }

    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.value
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: 10
    }
}
