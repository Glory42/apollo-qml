import QtQuick
import ".."

// A dim label followed by its value, on one line.
Row {
    id: root

    property string label: ""
    property string value: ""

    spacing: 8

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Theme.dim
        font.family: Theme.fontFamily
        font.pixelSize: 10
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.value
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: 10
    }
}
