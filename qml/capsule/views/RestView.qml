import QtQuick
import Quickshell
import "../.."

// Resting capsule: workspace dots and the time. Nothing else.
Item {
    id: root

    property var ctl: null

    readonly property bool recording: !!ctl && !!ctl.recorder && ctl.recorder.recording
    readonly property bool timerActive: !recording && ctl && ctl.countdown.active

    implicitWidth: Math.max(Theme.restWidth, content.width + 32)
    implicitHeight: Theme.restHeight

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            if (!root.ctl)
                return;
            // While recording, the capsule is the stop button.
            if (root.recording && mouse.button === Qt.LeftButton) {
                root.ctl.recorder.stop();
                return;
            }
            root.ctl.open(mouse.button === Qt.RightButton ? "quick" : root.ctl.lastOpened);
        }
    }

    Row {
        id: content

        anchors.centerIn: parent
        spacing: 12

        Row {
            visible: root.recording
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 8
                height: 8
                radius: 4
                color: Theme.danger
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.ctl && root.ctl.recorder ? root.ctl.recorder.elapsedText : ""
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
        }

        Row {
            visible: root.timerActive
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                size: 14
                name: "timer"
                color: Theme.dim
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.ctl ? root.ctl.countdown.text : ""
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
        }

        Row {
            visible: !root.timerActive && !root.recording
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Repeater {
                model: ScriptModel {
                    values: root.ctl ? root.ctl.workspaceIds : []
                }

                Rectangle {
                    required property int modelData
                    readonly property bool current: root.ctl && modelData === root.ctl.activeWorkspace

                    anchors.verticalCenter: parent.verticalCenter
                    width: current ? 12 : 4
                    height: 4
                    radius: 2
                    color: current ? Theme.fg : Theme.faint

                    Behavior on width {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.ctl && root.ctl.clock ? root.ctl.clock.currentTime : ""
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
        }
    }
}
