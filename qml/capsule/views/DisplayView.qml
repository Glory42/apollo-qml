import QtQuick
import "../.."

// How the screen looks: screen and keyboard brightness, dimming every screen, and the night light's warmth and schedule.
ViewFrame {
    id: root

    readonly property var system: ctl ? ctl.system : null
    readonly property var quick: ctl ? ctl.quick : null
    readonly property bool nightLight: !!root.quick && root.quick.nightLight

    spacing: 10

    component SectionLabel: Text {
        leftPadding: 4
        topPadding: 6
        color: Theme.faint
        font.family: Theme.fontFamily
        font.pixelSize: 11
    }

    Component.onCompleted: if (root.system) root.system.refreshBacklights()

    DetailHeader {
        width: parent.width
        ctl: root.ctl
        title: "Display"
        subtitle: root.nightLight ? "Night light on · " + root.quick.temperature + "K" : "Night light off"
        checked: root.nightLight
        onToggled: root.quick.toggleNightLight()
    }

    Column {
        width: parent.width
        spacing: 4

        SectionLabel {
            text: "Brightness"
        }

        Column {
            width: parent.width

            QuietSlider {
                visible: !!root.system && root.system.currentBrightness >= 0
                width: parent.width
                height: 34
                icon: "sun"
                value: root.system ? root.system.currentBrightness : 0
                onMoved: (v) => root.system.setBrightness(v)
            }

            // Dims every screen through hyprsunset, including ones without a backlight; it never goes fully dark.
            QuietSlider {
                width: parent.width
                height: 34
                icon: "dim"
                value: root.quick ? root.quick.gamma / 100 : 1
                onMoved: (v) => root.quick.setGamma(v * 100)
            }

            QuietSlider {
                visible: !!root.system && root.system.currentKeyboard >= 0
                width: parent.width
                height: 34
                icon: "keyboard"
                value: root.system ? root.system.currentKeyboard : 0
                onMoved: (v) => root.system.setKeyboardBrightness(v)
            }

        }

        SectionLabel {
            text: "Night light"
        }

        // Further right is warmer; dragging it turns the night light on.
        QuietSlider {
            width: parent.width
            height: 34
            icon: "thermostat"
            value: root.quick ? (root.quick.coolest - root.quick.temperature) / (root.quick.coolest - root.quick.warmest) : 0
            onMoved: (v) => root.quick.setTemperature(root.quick.coolest - v * (root.quick.coolest - root.quick.warmest))
        }

        Item {
            width: parent.width
            height: 44

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.right: scheduleSwitch.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: "On a schedule"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }

                Text {
                    text: Config.nightLightFrom + " – " + Config.nightLightTo
                    color: Theme.dim
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }

            Toggle {
                id: scheduleSwitch

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                checked: !!root.quick && root.quick.scheduled
                onToggled: root.quick.setScheduled(!root.quick.scheduled)
            }
        }
    }
}
