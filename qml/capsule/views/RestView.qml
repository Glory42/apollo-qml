import QtQuick
import Quickshell
import "../.."

// Resting capsule: the time, swapped for the workspace dots for a moment after a workspace switch.
Item {
    id: root

    property var ctl: null

    readonly property bool recording: !!ctl && !!ctl.recorder && ctl.recorder.recording
    property bool showDots: false

    Connections {
        target: root.ctl

        function onActiveWorkspaceChanged() {
            root.showDots = true;
            dotsTimer.restart();
        }
    }

    Timer {
        id: dotsTimer

        interval: 1500
        onTriggered: root.showDots = false
    }

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

        // The clock and the dots share one spot and fade into each other; it is as wide as whichever is showing.
        Item {
            readonly property bool dotsShown: !root.recording && root.showDots

            anchors.verticalCenter: parent.verticalCenter
            width: dotsShown ? dots.width : clock.width
            height: Math.max(dots.height, clock.height)

            Row {
                id: dots

                anchors.centerIn: parent
                spacing: 4
                opacity: parent.dotsShown ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

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
                id: clock

                anchors.centerIn: parent
                opacity: parent.dotsShown ? 0 : 1
                text: root.ctl && root.ctl.clock ? root.ctl.clock.currentTime : ""
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.Medium

                Behavior on opacity {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
