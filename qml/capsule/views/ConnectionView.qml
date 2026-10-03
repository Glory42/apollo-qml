import QtQuick
import Quickshell
import "../.."

// One connection up close: traffic and ping, its addresses, its DNS, and for Wi-Fi a way to share it.
ViewFrame {
    id: root

    readonly property var net: ctl ? ctl.net : null
    property bool customOpen: false
    property bool sharing: false
    property bool showPassword: false

    spacing: 10

    onCustomOpenChanged: {
        if (root.ctl)
            root.ctl.typing = root.customOpen;
        if (root.customOpen) {
            dnsField.text = link.customDns;
            dnsField.forceActiveFocus();
        }
    }

    ConnectionService {
        id: link

        device: root.ctl ? root.ctl.detailDevice : null
    }

    // A small label with its value underneath, so long values such as addresses have the full width.
    component Stat: Column {
        property string label: ""
        property string value: ""

        width: (parent.width - parent.leftPadding - parent.rightPadding - parent.columnSpacing) / 2
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
        backTo: "wifi"
        switchVisible: false
        title: link.isWifi ? (link.network ? link.network.name : "Wi-Fi") : "Wired"
        subtitle: {
            if (!link.network || !link.network.connected)
                return "Not connected";
            if (link.isWifi)
                return "Connected · " + Math.round((link.network.signalStrength || 0) * 100) + "% signal";
            return root.net ? root.net.wiredName : "Connected";
        }
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

            Grid {
                width: parent.width
                leftPadding: 4
                rightPadding: 4
                columns: 2
                columnSpacing: 16
                rowSpacing: 10

                Stat {
                    label: "Ping"
                    value: link.ping >= 0 ? link.ping.toFixed(1) + " ms" : "-"
                }

                Stat {
                    label: "Packet loss"
                    value: link.loss >= 0 ? link.loss + "%" : "-"
                }

                Stat {
                    label: "Receiving"
                    value: link.rate(link.rxRate)
                }

                Stat {
                    label: "Sending"
                    value: link.rate(link.txRate)
                }

                Stat {
                    label: "Downloaded"
                    value: link.bytes(link.rxTotal)
                }

                Stat {
                    label: "Uploaded"
                    value: link.bytes(link.txTotal)
                }

                Stat {
                    label: "IP address"
                    value: link.ip || "-"
                }

                Stat {
                    label: "Gateway"
                    value: link.gateway || "-"
                }
            }

            Column {
                width: parent.width
                spacing: 6

                Label {
                    text: link.applying ? "DNS · applying" : "DNS"
                }

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 14
                    color: Theme.fill

                    Row {
                        anchors.fill: parent
                        anchors.margins: 3

                        Repeater {
                            model: [
                                { id: "auto", label: "Automatic" },
                                { id: "cloudflare", label: "Cloudflare" },
                                { id: "google", label: "Google" },
                                { id: "custom", label: "Custom" }
                            ]

                            Rectangle {
                                required property var modelData
                                readonly property bool current: (root.customOpen ? "custom" : link.dns) === modelData.id

                                width: parent.width / 4
                                height: parent.height
                                radius: 11
                                color: current ? Theme.fill2 : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: parent.modelData.label
                                    color: parent.current ? Theme.fg : Theme.dim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (parent.modelData.id === "custom") {
                                            root.customOpen = true;
                                        } else {
                                            root.customOpen = false;
                                            link.setDns(parent.modelData.id);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Servers for "Custom", separated by spaces; IPv4 and IPv6 can be mixed.
                Row {
                    visible: root.customOpen
                    width: parent.width
                    spacing: 8

                    Rectangle {
                        width: parent.width - save.width - parent.spacing
                        height: 34
                        radius: 17
                        color: Theme.fill

                        Text {
                            anchors.fill: dnsField
                            verticalAlignment: Text.AlignVCenter
                            visible: dnsField.text === ""
                            text: "9.9.9.9 149.112.112.112"
                            color: Theme.faint
                            font: dnsField.font
                        }

                        TextInput {
                            id: dnsField

                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true
                            color: Theme.fg
                            selectionColor: Theme.fill2
                            selectedTextColor: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 12

                            onAccepted: save.clicked()
                            Keys.onEscapePressed: root.customOpen = false
                        }
                    }

                    RoundButton {
                        id: save

                        text: "Save"
                        primary: true
                        onClicked: {
                            link.setDns("custom", dnsField.text);
                            root.customOpen = false;
                        }
                    }
                }
            }

            // Sharing: the QR code a phone scans to join, and the password itself, hidden until asked for.
            Row {
                visible: link.isWifi && root.sharing
                width: parent.width
                spacing: 16

                Rectangle {
                    visible: !link.qrFailed
                    width: 132
                    height: 132
                    radius: 14
                    color: "white"

                    Image {
                        anchors.fill: parent
                        anchors.margins: 6
                        source: link.qrFile !== "" ? "file://" + link.qrFile : ""
                        smooth: false
                        fillMode: Image.PreserveAspectFit
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - (link.qrFailed ? 0 : 132 + parent.spacing)
                    spacing: 6

                    Label {
                        text: "Password"
                    }

                    Row {
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: link.password === "" ? "None" : (root.showPassword ? link.password : "•".repeat(Math.min(link.password.length, 16)))
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }

                        Rectangle {
                            visible: link.password !== ""
                            anchors.verticalCenter: parent.verticalCenter
                            width: 26
                            height: 26
                            radius: 13
                            color: eyeArea.containsMouse ? Theme.fill2 : "transparent"

                            Icon {
                                anchors.centerIn: parent
                                name: root.showPassword ? "visibility_off" : "visibility"
                                size: 16
                                color: Theme.dim
                            }

                            MouseArea {
                                id: eyeArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.showPassword = !root.showPassword
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        wrapMode: Text.Wrap
                        text: link.qrFailed ? "Install qrencode to show a QR code." : "Scan with a phone camera to join."
                        color: Theme.dim
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                }
            }

            Row {
                spacing: 8

                RoundButton {
                    visible: link.isWifi
                    text: root.sharing ? "Hide" : "Share"
                    onClicked: {
                        root.sharing = !root.sharing;
                        root.showPassword = false;
                        if (root.sharing)
                            link.share();
                        else
                            link.forgetShared();
                    }
                }

                RoundButton {
                    visible: !!link.network && link.network.connected
                    text: "Disconnect"
                    onClicked: {
                        if (link.isWifi)
                            root.net.disconnectWifi(link.network);
                        else
                            link.device.disconnect();
                        root.ctl.open("wifi");
                    }
                }

                RoundButton {
                    visible: link.isWifi && !!link.network && link.network.known
                    text: "Forget"
                    onClicked: {
                        root.net.forgetWifi(link.network);
                        root.ctl.open("wifi");
                    }
                }
            }
        }
    }
}
