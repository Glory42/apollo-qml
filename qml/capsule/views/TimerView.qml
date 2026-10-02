import QtQuick
import "../.."

ViewFrame {
    id: root

    readonly property var countdown: ctl ? ctl.countdown : null

    Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: root.countdown ? root.countdown.text : ""
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: 46
        font.weight: Font.Light
    }

    Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: !root.countdown || !root.countdown.active ? "Ready" : (root.countdown.running ? "Running" : "Paused")
        color: Theme.dim
        font.family: Theme.fontFamily
        font.pixelSize: 12
    }

    Rectangle {
        width: parent.width
        height: 10
        radius: 5
        color: Theme.fill2

        Rectangle {
            width: parent.width * (root.countdown ? root.countdown.progress : 0)
            height: parent.height
            radius: 5
            color: Theme.fg

            Behavior on width {
                NumberAnimation {
                    duration: 900
                    easing.type: Easing.Linear
                }
            }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8

        RoundButton {
            text: "− 5 min"
            onClicked: root.countdown.addMinutes(-5)
        }

        RoundButton {
            primary: true
            text: !root.countdown || !root.countdown.running ? (root.countdown && root.countdown.active ? "Resume" : "Start") : "Pause"
            onClicked: root.countdown.toggle()
        }

        RoundButton {
            text: "Reset"
            onClicked: root.countdown.reset()
        }

        RoundButton {
            text: "+ 5 min"
            onClicked: root.countdown.addMinutes(5)
        }
    }
}
