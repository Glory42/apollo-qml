import QtQuick
import ".."

// Back arrow, title with status, an optional extra button, and an on/off switch.
Item {
    id: root

    property var ctl: null
    property string title: ""
    property string subtitle: ""
    property bool checked: false
    property string extra: ""
    // The view the back arrow returns to.
    property string backTo: "quick"
    property bool switchVisible: true

    signal toggled()
    signal extraClicked()

    implicitHeight: 40

    Rectangle {
        id: back

        width: 32
        height: 32
        radius: 16
        anchors.verticalCenter: parent.verticalCenter
        color: backArea.containsMouse ? Theme.fill2 : "transparent"

        Icon {
            anchors.centerIn: parent
            name: "chevron"
            rotation: 180
            color: Theme.dim
        }

        MouseArea {
            id: backArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.ctl.open(root.backTo)
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
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 15
            font.weight: Font.Medium
        }

        Text {
            width: parent.width
            text: root.subtitle
            elide: Text.ElideRight
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
    }

    Row {
        id: controls

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        RoundButton {
            visible: root.extra !== ""
            anchors.verticalCenter: parent.verticalCenter
            implicitHeight: 28
            text: root.extra
            onClicked: root.extraClicked()
        }

        Toggle {
            visible: root.switchVisible
            anchors.verticalCenter: parent.verticalCenter
            checked: root.checked
            onToggled: root.toggled()
        }
    }
}
