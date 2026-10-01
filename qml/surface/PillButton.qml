import QtQuick

Rectangle {
    id: root

    property string text: ""
    property bool primary: false
    signal clicked()

    implicitWidth: label.implicitWidth + 32
    implicitHeight: 34
    radius: 17
    color: primary ? SurfaceStyle.tileOn : (area.containsMouse ? SurfaceStyle.fill2 : SurfaceStyle.fill)

    Text {
        id: label

        anchors.centerIn: parent
        text: root.text
        color: root.primary ? SurfaceStyle.tileOnInk : SurfaceStyle.fg
        font.family: SurfaceStyle.fontFamily
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
