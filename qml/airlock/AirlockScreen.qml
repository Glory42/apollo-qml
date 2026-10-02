import QtQuick
import ".."

// What one monitor shows while locked; the status row gives away nothing private.
Item {
    id: root

    property var services: null
    property string status: ""
    property int missed: 0

    readonly property var clock: services ? services.clock : null
    readonly property var system: services ? services.system : null
    readonly property var player: services && services.mpris ? services.mpris.activePlayer : null
    readonly property string track: services && services.mpris ? services.mpris.currentTrack : ""

    signal submitted(string password)

    onStatusChanged: {
        if (root.status === "failed") {
            field.text = "";
            shake.restart();
        }
    }

    Component.onCompleted: field.forceActiveFocus()

    Column {
        anchors.centerIn: parent
        spacing: 6

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.clock ? root.clock.currentTime : ""
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 96
            font.weight: Font.Medium
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            // Reads the time so the date turns over at midnight.
            text: root.clock && root.clock.currentTime !== "" ? Qt.formatDate(new Date(), "dddd, d MMMM") : ""
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: 15
        }

        Item {
            width: 1
            height: 28
        }

        Rectangle {
            id: box

            anchors.horizontalCenter: parent.horizontalCenter
            width: 280
            height: 44
            radius: 22
            color: Theme.fill

            Icon {
                id: glyph

                x: 16
                anchors.verticalCenter: parent.verticalCenter
                name: "lock"
                size: 16
                color: Theme.dim
            }

            Text {
                anchors.fill: field
                verticalAlignment: Text.AlignVCenter
                visible: field.text === ""
                text: root.status === "checking" ? "Checking" : (root.status === "failed" ? "Wrong password" : "Password")
                color: root.status === "failed" ? Theme.danger : Theme.faint
                font: field.font
            }

            TextInput {
                id: field

                anchors.fill: parent
                anchors.leftMargin: 44
                anchors.rightMargin: 16
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                focus: true
                echoMode: TextInput.Password
                readOnly: root.status === "checking"
                color: Theme.fg
                selectionColor: Theme.fill2
                selectedTextColor: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 14

                onAccepted: root.submitted(field.text)
                Keys.onEscapePressed: field.text = ""
            }

            SequentialAnimation {
                id: shake

                NumberAnimation { target: box; property: "anchors.horizontalCenterOffset"; to: -10; duration: 50 }
                NumberAnimation { target: box; property: "anchors.horizontalCenterOffset"; to: 10; duration: 80 }
                NumberAnimation { target: box; property: "anchors.horizontalCenterOffset"; to: -6; duration: 70 }
                NumberAnimation { target: box; property: "anchors.horizontalCenterOffset"; to: 0; duration: 60 }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onPressed: field.forceActiveFocus()
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 36
        spacing: 28

        Row {
            visible: !!root.system && root.system.batteryCapacity >= 0
            spacing: 8

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: root.system ? root.system.batteryIcon : ""
                size: 16
                color: Theme.dim
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.system ? root.system.batteryCapacity + "%" : ""
                color: Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
        }

        Row {
            visible: !!root.player && root.track !== ""
            spacing: 8

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28
                radius: 14
                color: playArea.containsMouse ? Theme.fill2 : Theme.fill

                Icon {
                    anchors.centerIn: parent
                    name: root.player && root.player.isPlaying ? "pause" : "play"
                    size: 16
                }

                MouseArea {
                    id: playArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.player && root.player.canTogglePlaying)
                            root.player.togglePlaying();
                        field.forceActiveFocus();
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, 260)
                text: root.track
                elide: Text.ElideRight
                color: Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
        }

        Row {
            visible: root.missed > 0
            spacing: 8

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: "bell"
                size: 16
                color: Theme.dim
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.missed
                color: Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
        }
    }
}
