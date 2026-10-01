import QtQuick

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
    color: on ? SurfaceStyle.tileOn : (area.containsMouse ? SurfaceStyle.fill2 : SurfaceStyle.fill)

    Icon {
        id: glyph

        x: 14
        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        color: root.on ? SurfaceStyle.tileOnInk : SurfaceStyle.fg
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
            color: root.on ? SurfaceStyle.tileOnInk : SurfaceStyle.fg
            font.family: SurfaceStyle.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
        }

        Text {
            width: parent.width
            text: root.subtitle
            elide: Text.ElideRight
            color: root.on ? SurfaceStyle.tileOnSub : SurfaceStyle.dim
            font.family: SurfaceStyle.fontFamily
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
            color: root.on ? SurfaceStyle.tileOnInk : SurfaceStyle.dim
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.detailRequested()
        }
    }
}
