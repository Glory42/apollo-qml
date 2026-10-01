import QtQuick
import ".."

Rectangle {
    id: root

    property string text: ""
    property bool primary: false
    signal clicked()

    implicitWidth: label.implicitWidth + 32
    implicitHeight: 34
    radius: 17
    color: primary ? Theme.tileOn : (area.containsMouse ? Theme.fill2 : Theme.fill)

    Text {
        id: label

        anchors.centerIn: parent
        text: root.text
        color: root.primary ? Theme.tileOnInk : Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: 12
        font.weight: Font.Medium
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
