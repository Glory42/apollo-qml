import QtQuick
import ".."

Item {
    id: root

    property string icon: ""
    property real value: 0
    // The value at the right end; above 1 lets a slider go past 100%.
    property real maximum: 1
    // A tappable icon, for mute.
    property bool iconClickable: false
    // A chevron at the end that opens a view with more.
    property bool detail: false
    signal moved(real value)
    signal iconClicked()
    signal detailRequested()

    readonly property real shown: area.pressed ? area.dragValue : value

    implicitHeight: 22

    Icon {
        id: glyph

        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        color: Theme.dim

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            enabled: root.iconClickable
            cursorShape: Qt.PointingHandCursor
            onClicked: root.iconClicked()
        }
    }

    Rectangle {
        id: track

        anchors.left: glyph.right
        anchors.leftMargin: 12
        anchors.right: percent.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        height: 10
        radius: 5
        color: Theme.fill2

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.shown / root.maximum))
            height: parent.height
            radius: 5
            color: Theme.fg
        }

        MouseArea {
            id: area

            property real dragValue: 0

            anchors.fill: parent
            anchors.topMargin: -8
            anchors.bottomMargin: -8
            cursorShape: Qt.PointingHandCursor

            function update(x) {
                dragValue = Math.max(0, Math.min(1, x / width)) * root.maximum;
                root.moved(dragValue);
            }

            onPressed: (mouse) => update(mouse.x)
            onPositionChanged: (mouse) => update(mouse.x)
        }
    }

    Text {
        id: percent

        anchors.right: root.detail ? more.left : parent.right
        anchors.rightMargin: root.detail ? 4 : 0
        anchors.verticalCenter: parent.verticalCenter
        width: 28
        horizontalAlignment: Text.AlignRight
        text: Math.round(Math.max(0, Math.min(root.maximum, root.shown)) * 100)
        color: Theme.dim
        font.family: Theme.fontFamily
        font.pixelSize: 11
    }

    Rectangle {
        id: more

        visible: root.detail
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        height: 24
        radius: 12
        color: moreArea.containsMouse ? Theme.fill2 : "transparent"

        Icon {
            anchors.centerIn: parent
            name: "chevron"
            size: 14
            color: Theme.dim
        }

        MouseArea {
            id: moreArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.detailRequested()
        }
    }
}
