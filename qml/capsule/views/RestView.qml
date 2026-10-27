import QtQuick
import Quickshell
import "../.."

// Resting capsule: workspace dots and the time. Nothing else.
Item {
    id: root

    property var ctl: null

    readonly property bool recording: !!ctl && !!ctl.recorder && ctl.recorder.recording

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

        property real wheelSum: 0

        onWheel: (wheel) => {
            if (!root.ctl || Math.abs(wheel.angleDelta.y) <= Math.abs(wheel.angleDelta.x))
                return;
            wheelSum += wheel.angleDelta.y;
            if (Math.abs(wheelSum) >= 120) {
                root.ctl.stepWorkspace(wheelSum < 0 ? 1 : -1);
                wheelSum = 0;
            }
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
            visible: !root.recording
            anchors.verticalCenter: parent.verticalCenter

            Repeater {
                model: ScriptModel {
                    values: root.ctl ? root.ctl.workspaceIds : []
                }

                // Each dot clicks through to its workspace; the hit area is wider than the dot so it is easy to hit.
                Item {
                    id: slot

                    required property int modelData
                    readonly property bool current: root.ctl && modelData === root.ctl.activeWorkspace

                    width: dot.width + 4
                    height: Theme.restHeight

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.ctl.focusWorkspace(slot.modelData)
                    }

                    Rectangle {
                        id: dot

                        anchors.centerIn: parent
                        width: slot.current ? 12 : 4
                        height: 4
                        radius: 2
                        color: slot.current ? Theme.fg : Theme.faint

                        Behavior on width {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
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
