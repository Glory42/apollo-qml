import QtQuick

// Back arrow, title with status, an optional extra button, and an on/off switch.
Item {
    id: root

    property var ctl: null
    property string title: ""
    property string subtitle: ""
    property bool checked: false
    property string extra: ""

    signal toggled()
    signal extraClicked()

    implicitHeight: 40

    Rectangle {
        id: back

        width: 32
        height: 32
        radius: 16
        anchors.verticalCenter: parent.verticalCenter
        color: backArea.containsMouse ? SurfaceStyle.fill2 : "transparent"

        Icon {
            anchors.centerIn: parent
            name: "chevron"
            rotation: 180
            color: SurfaceStyle.dim
        }

        MouseArea {
            id: backArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.ctl.open("quick")
        }
    }

    Column {
        anchors.left: back.right
        anchors.leftMargin: 8
        anchors.right: controls.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter

        Text {
            width: parent.width
            text: root.title
            color: SurfaceStyle.fg
            font.family: SurfaceStyle.fontFamily
            font.pixelSize: 15
            font.weight: Font.Medium
        }

        Text {
            width: parent.width
            text: root.subtitle
            elide: Text.ElideRight
            color: SurfaceStyle.dim
            font.family: SurfaceStyle.fontFamily
            font.pixelSize: 11
        }
    }

    Row {
        id: controls

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        PillButton {
            visible: root.extra !== ""
            anchors.verticalCenter: parent.verticalCenter
            implicitHeight: 28
            text: root.extra
            onClicked: root.extraClicked()
        }

        Rectangle {
            width: 44
            height: 26
            radius: 13
            anchors.verticalCenter: parent.verticalCenter
            color: root.checked ? SurfaceStyle.tileOn : SurfaceStyle.fill2

            Rectangle {
                x: root.checked ? parent.width - width - 3 : 3
                anchors.verticalCenter: parent.verticalCenter
                width: 20
                height: 20
                radius: 10
                color: root.checked ? SurfaceStyle.tileOnInk : SurfaceStyle.dim

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
    }
}
