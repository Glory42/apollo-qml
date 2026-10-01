import QtQuick

// The one switcher shared by every open view.
Item {
    id: root

    property var ctl: null

    implicitWidth: SurfaceStyle.openWidth
    implicitHeight: 52

    Row {
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: root.ctl ? root.ctl.dock : []

            Rectangle {
                id: tab

                required property var modelData
                readonly property bool current: root.ctl && root.ctl.dockCurrent === modelData.id

                width: 36
                height: 36
                radius: 18
                color: current ? SurfaceStyle.fill2 : (tabArea.containsMouse ? SurfaceStyle.fill : "transparent")

                Icon {
                    anchors.centerIn: parent
                    name: tab.modelData.icon
                    color: tab.current ? SurfaceStyle.fg : SurfaceStyle.dim
                }

                Rectangle {
                    visible: tab.modelData.id === "notifications" && root.ctl && root.ctl.unread > 0
                    x: parent.width - 13
                    y: 7
                    width: 7
                    height: 7
                    radius: 4
                    color: SurfaceStyle.danger
                }

                MouseArea {
                    id: tabArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.ctl.open(tab.modelData.id)
                }
            }
        }
    }
}
