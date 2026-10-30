import QtQuick
import Quickshell
import Quickshell.Io
import "../.."

// One Bluetooth device up close: your name for it, what it is and can do, how it may connect, and forgetting it.
ViewFrame {
    id: root

    readonly property var net: ctl ? ctl.net : null
    readonly property var device: ctl ? ctl.bluetoothDevice : null
    readonly property bool named: !!device && device.name !== "" && device.name !== device.deviceName
    property var profiles: []
    property string codec: ""
    // Forgetting takes a second tap, and the first one wears off.
    property bool confirmForget: false

    spacing: 10

    // A forgotten device is gone; there is nothing left to show.
    onDeviceChanged: if (!device && ctl && ctl.view === "btdevice") ctl.open("bt")

    Component.onCompleted: info.running = !!device

    Connections {
        target: root.device

        function onConnectedChanged() {
            info.running = true;
        }
    }

    // Profiles from bluetoothctl and, while it plays, the codec from PipeWire; neither is on the D-Bus object Quickshell reads.
    Process {
        id: info

        command: ["sh", "-c", 'timeout 5 bluetoothctl info "$1" 2>/dev/null | sed -n \'s/.*UUID:.*(0000\\([0-9a-fA-F]\\{4\\}\\)-0000-1000-8000-00805f9b34fb)$/uuid \\1/p\';'
            + ' pw-dump 2>/dev/null | jq -r --arg a "$1" \'.[] | select(.type == "PipeWire:Interface:Node" and .info.props["api.bluez5.address"]? == $a)'
            + ' | "codec " + (.info.props["api.bluez5.codec"] // "")\'', "sh", root.device ? root.device.address : ""]
        stdout: StdioCollector {
            onStreamFinished: {
                const ids = [];
                let codec = "";
                for (const line of text.split("\n")) {
                    if (line.startsWith("uuid "))
                        ids.push(line.slice(5));
                    else if (line.startsWith("codec ") && line.length > 6)
                        codec = line.slice(6);
                }
                root.profiles = root.net ? root.net.profileLabels(ids) : [];
                root.codec = codec !== "" && root.net ? root.net.codecLabel(codec) : "";
            }
        }
    }

    Timer {
        id: forgetWindow

        interval: 3000
        onTriggered: root.confirmForget = false
    }

    // A small label with its value underneath, so long values such as addresses have the full width.
    component Stat: Column {
        property string label: ""
        property string value: ""
        property bool wide: false

        width: wide ? parent.width - parent.leftPadding - parent.rightPadding
            : (parent.width - parent.leftPadding - parent.rightPadding - parent.columnSpacing) / 2
        spacing: 2

        Text {
            text: parent.label
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: 10
        }

        Text {
            width: parent.width
            text: parent.value
            elide: Text.ElideRight
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }
    }

    component Label: Text {
        leftPadding: 4
        color: Theme.faint
        font.family: Theme.fontFamily
        font.pixelSize: 11
    }

    DetailHeader {
        width: parent.width
        ctl: root.ctl
        backTo: "bt"
        title: root.device && root.net ? root.net.deviceName(root.device) : "Device"
        subtitle: root.device && root.net ? root.net.deviceSubtitle(root.device) : ""
        checked: !!root.device && root.device.connected
        onToggled: root.net.pressDevice(root.device)
    }

    Flickable {
        width: parent.width
        height: Math.min(contentHeight, 400)
        contentHeight: sections.implicitHeight
        clip: true
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: sections

            width: parent.width
            spacing: 12

            // Enter saves; an empty name, or Reset, gives back the name the device reports itself.
            Column {
                width: parent.width
                spacing: 6

                Label {
                    text: "Name"
                }

                Row {
                    width: parent.width
                    spacing: 8

                    Rectangle {
                        width: parent.width - (reset.visible ? reset.width + parent.spacing : 0)
                        height: 34
                        radius: 17
                        color: Theme.fill

                        TextInput {
                            id: nameField

                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true
                            text: root.device ? root.device.name : ""
                            color: Theme.fg
                            selectionColor: Theme.fill2
                            selectedTextColor: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            onActiveFocusChanged: if (root.ctl) root.ctl.typing = activeFocus
                            onAccepted: {
                                root.net.renameDevice(root.device, text);
                                focus = false;
                            }
                            Keys.onEscapePressed: {
                                text = root.device ? root.device.name : "";
                                focus = false;
                            }
                        }
                    }

                    RoundButton {
                        id: reset

                        visible: root.named
                        text: "Reset"
                        onClicked: {
                            root.net.renameDevice(root.device, "");
                            nameField.focus = false;
                        }
                    }
                }
            }

            Grid {
                width: parent.width
                leftPadding: 4
                rightPadding: 4
                columns: 2
                columnSpacing: 16
                rowSpacing: 10

                Stat {
                    label: "Type"
                    value: root.device && root.net ? root.net.deviceType(root.device) : "-"
                }

                Stat {
                    label: "Battery"
                    value: {
                        if (!root.device || !root.device.batteryAvailable)
                            return "-";
                        const raw = Math.max(0, Number(root.device.battery) || 0);
                        return Math.round(raw <= 1 ? raw * 100 : raw) + "%";
                    }
                }

                Stat {
                    label: "Address"
                    value: root.device ? root.device.address : "-"
                }

                Stat {
                    label: "Pairing"
                    value: !root.device ? "-" : (root.device.bonded ? "Paired and bonded" : (root.device.paired ? "Paired" : "Not paired"))
                }

                Stat {
                    label: "Real name"
                    value: root.device && root.device.deviceName !== "" ? root.device.deviceName : "-"
                }

                Stat {
                    label: "Codec"
                    value: root.codec !== "" ? root.codec : "-"
                }

                Stat {
                    wide: true
                    label: "Can do"
                    value: root.profiles.length > 0 ? root.profiles.join(", ") : "-"
                }
            }

            Column {
                width: parent.width

                SwitchRow {
                    icon: "lock"
                    title: "Trusted"
                    subtitle: "Connects without asking"
                    checked: !!root.device && root.device.trusted
                    onToggled: root.device.trusted = !root.device.trusted
                }

                SwitchRow {
                    icon: "visibility_off"
                    title: "Blocked"
                    subtitle: "Refuses every connection"
                    checked: !!root.device && root.device.blocked
                    onToggled: root.device.blocked = !root.device.blocked
                }

                SwitchRow {
                    icon: "power"
                    title: "Wake from sleep"
                    subtitle: "Can wake the computer"
                    checked: !!root.device && root.device.wakeAllowed
                    onToggled: root.device.wakeAllowed = !root.device.wakeAllowed
                }
            }

            RoundButton {
                visible: !!root.device && (root.device.paired || root.device.bonded)
                text: root.confirmForget ? "Tap again to forget" : "Forget device"
                onClicked: {
                    if (!root.confirmForget) {
                        root.confirmForget = true;
                        forgetWindow.restart();
                        return;
                    }
                    root.confirmForget = false;
                    root.net.forgetDevice(root.device);
                    root.ctl.open("bt");
                }
            }
        }
    }
}
