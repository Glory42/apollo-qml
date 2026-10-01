import QtQuick

// Transient event. Two flavours share one view: a notification, or a volume/brightness change.
Item {
    id: root

    property var ctl: null
    readonly property bool isNotify: !ctl || ctl.peekKind === "notify"

    implicitWidth: isNotify ? SurfaceStyle.peekNotifyWidth : SurfaceStyle.peekOsdWidth
    implicitHeight: isNotify ? SurfaceStyle.peekNotifyHeight : SurfaceStyle.peekOsdHeight

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.ctl) root.ctl.open(root.isNotify ? "notifications" : "quick")
    }

    Row {
        visible: root.isNotify
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 20
        spacing: 12

        NotificationAvatar {
            anchors.verticalCenter: parent.verticalCenter
            size: 36
            image: root.ctl ? root.ctl.peekImage : ""
            appIcon: root.ctl ? root.ctl.peekAppIcon : ""
            app: root.ctl ? root.ctl.peekApp : ""
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 48
            spacing: 1

            Text {
                width: parent.width
                text: root.ctl ? root.ctl.peekSummary : ""
                color: SurfaceStyle.fg
                elide: Text.ElideRight
                font.family: SurfaceStyle.fontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: root.ctl ? (root.ctl.peekBody !== "" ? root.ctl.peekBody : root.ctl.peekApp) : ""
                color: SurfaceStyle.dim
                elide: Text.ElideRight
                font.family: SurfaceStyle.fontFamily
                font.pixelSize: 12
            }
        }
    }

    Row {
        visible: !root.isNotify
        anchors.centerIn: parent
        spacing: 12

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.ctl ? root.ctl.peekIcon : ""
        }

        Rectangle {
            visible: root.ctl && root.ctl.peekProgress >= 0
            anchors.verticalCenter: parent.verticalCenter
            width: 110
            height: 6
            radius: 3
            color: SurfaceStyle.fill2

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.ctl ? root.ctl.peekProgress : 0))
                height: parent.height
                radius: 3
                color: SurfaceStyle.fg

                Behavior on width {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        Text {
            visible: root.ctl && root.ctl.peekProgress >= 0
            anchors.verticalCenter: parent.verticalCenter
            width: 28
            horizontalAlignment: Text.AlignRight
            text: root.ctl ? Math.round(root.ctl.peekProgress * 100) : ""
            color: SurfaceStyle.dim
            font.family: SurfaceStyle.fontFamily
            font.pixelSize: 11
        }
    }
}
