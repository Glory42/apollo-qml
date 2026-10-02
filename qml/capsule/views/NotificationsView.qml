import QtQuick
import "../.."

ViewFrame {
    id: root

    readonly property var center: ctl ? ctl.center : null
    readonly property int total: center ? center.count : 0

    Item {
        width: parent.width
        height: 32

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.total > 0 ? "Notifications · " + root.total : "Notifications"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 15
            font.weight: Font.Medium
        }

        RoundButton {
            visible: root.total > 0
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            implicitHeight: 28
            text: "Clear all"
            onClicked: root.center.dismissAll()
        }
    }

    ListView {
        width: parent.width
        height: Math.min(contentHeight, 300)
        visible: root.total > 0
        clip: true
        spacing: 4
        interactive: contentHeight > height
        model: root.center ? root.center.tracked : null

        delegate: Rectangle {
            id: card

            required property var modelData
            readonly property var primary: findAction("default")

            function findAction(id) {
                const list = modelData.actions || [];
                for (let i = 0; i < list.length; i++)
                    if (list[i].identifier === id) return list[i];
                return null;
            }

            width: ListView.view.width
            height: content.implicitHeight + 20
            radius: 14
            color: cardArea.containsMouse ? Theme.fill : "transparent"

            MouseArea {
                id: cardArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (card.primary) card.primary.invoke();
                    card.modelData.dismiss();
                }
            }

            NotificationAvatar {
                x: 10
                y: 10
                size: 36
                image: card.modelData.image
                appIcon: card.modelData.appIcon
                app: card.modelData.appName
            }

            Column {
                id: content

                x: 58
                y: 10
                width: parent.width - 58 - 40
                spacing: 2

                Text {
                    width: parent.width
                    text: card.modelData.summary
                    elide: Text.ElideRight
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }

                Text {
                    visible: text !== ""
                    width: parent.width
                    text: card.modelData.body
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    color: Theme.dim
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }

                Text {
                    width: parent.width
                    text: card.modelData.appName
                    elide: Text.ElideRight
                    color: Theme.faint
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }

                Row {
                    spacing: 6
                    visible: actionRepeater.count > 0
                    topPadding: 4

                    Repeater {
                        id: actionRepeater

                        model: (card.modelData.actions || []).filter((a) => a.identifier !== "default")

                        RoundButton {
                            required property var modelData

                            implicitHeight: 26
                            text: modelData.text
                            onClicked: {
                                modelData.invoke();
                                card.modelData.dismiss();
                            }
                        }
                    }
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.top: parent.top
                anchors.topMargin: 8
                width: 24
                height: 24
                radius: 12
                color: closeArea.containsMouse ? Theme.fill2 : "transparent"
                visible: cardArea.containsMouse

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: Theme.dim
                    font.pixelSize: 16
                }

                MouseArea {
                    id: closeArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.modelData.dismiss()
                }
            }
        }
    }

    Text {
        visible: root.total === 0
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        topPadding: 24
        bottomPadding: 24
        text: "No notifications"
        color: Theme.dim
        font.family: Theme.fontFamily
        font.pixelSize: 12
    }
}
