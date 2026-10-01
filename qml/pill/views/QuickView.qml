import QtQuick
import "../.."

ViewFrame {
    id: root

    readonly property var quick: ctl ? ctl.quick : null
    readonly property var net: ctl ? ctl.net : null
    readonly property var center: ctl ? ctl.center : null
    readonly property var system: ctl ? ctl.system : null

    Grid {
        width: parent.width
        columns: 2
        spacing: 8

        Tile {
            width: (parent.width - 8) / 2
            icon: "wifi"
            title: "Wi-Fi"
            detail: true
            subtitle: root.net ? root.net.wifiName : ""
            on: !!root.net && root.net.wifiEnabled
            onClicked: root.net.toggleWifi()
            onDetailRequested: root.ctl.open("wifi")
        }

        Tile {
            width: (parent.width - 8) / 2
            icon: "bt"
            title: "Bluetooth"
            detail: true
            subtitle: root.net ? root.net.bluetoothName : ""
            on: !!root.net && root.net.bluetoothEnabled
            onClicked: root.net.toggleBluetooth()
            onDetailRequested: root.ctl.open("bt")
        }

        Tile {
            width: (parent.width - 8) / 2
            icon: "moon"
            title: "Night light"
            subtitle: root.quick && root.quick.nightLight ? "On" : "Off"
            on: !!root.quick && root.quick.nightLight
            onClicked: root.quick.toggleNightLight()
        }

        Tile {
            width: (parent.width - 8) / 2
            icon: "bell"
            title: "Focus"
            subtitle: root.center && root.center.focusMode ? "Alerts silenced" : "Alerts on"
            on: !!root.center && root.center.focusMode
            onClicked: root.center.focusMode = !root.center.focusMode
        }
    }

    QuietSlider {
        width: parent.width
        icon: root.system && root.system.isMuted ? "mute" : "volume"
        value: root.system && root.system.currentVolume >= 0 ? root.system.currentVolume : 0
        onMoved: (v) => root.system.setVolume(v)
    }

    QuietSlider {
        width: parent.width
        icon: "sun"
        value: root.system && root.system.currentBrightness >= 0 ? root.system.currentBrightness : 0
        onMoved: (v) => root.system.setBrightness(v)
    }

    Rectangle {
        width: parent.width
        height: 40
        radius: 14
        color: Theme.fill

        Row {
            anchors.fill: parent
            anchors.margins: 3

            Repeater {
                model: [
                    { id: "power-saver", label: "Saver" },
                    { id: "balanced", label: "Balanced" },
                    { id: "performance", label: "Performance" }
                ]

                Rectangle {
                    required property var modelData
                    readonly property bool current: root.quick && root.quick.profile === modelData.id

                    width: parent.width / 3
                    height: parent.height
                    radius: 11
                    color: current ? Theme.fill2 : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData.label
                        color: parent.current ? Theme.fg : Theme.dim
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.quick.setProfile(parent.modelData.id)
                    }
                }
            }
        }
    }

    Row {
        visible: !!root.system && root.system.batteryCapacity >= 0
        spacing: 30

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: root.system ? root.system.batteryIcon : "battery_unknown"
                color: Theme.dim
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.system ? root.system.batteryCapacity + "%" : ""
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
        }

        StatPair {
            anchors.verticalCenter: parent.verticalCenter
            label: root.system ? root.system.batteryTimeLabel : ""
            value: root.system ? root.system.batteryTimeText : ""
        }

        StatPair {
            anchors.verticalCenter: parent.verticalCenter
            label: root.system ? root.system.batteryRateLabel : ""
            value: root.system ? root.system.batteryRateText : ""
        }
    }

    Text {
        visible: !root.system || root.system.batteryCapacity < 0
        text: "No battery"
        color: Theme.dim
        font.family: Theme.fontFamily
        font.pixelSize: 12
    }
}
